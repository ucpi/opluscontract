// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract oplus is ERC1155,Ownable{
    uint256 public tokenId;

    mapping(uint256 => string) private _uris;
    mapping(address => sdata[]) public scanData;
    mapping(address => rewards[]) public myrewards;
    mapping(string => uint256) public couponIndex;

    constructor() ERC1155("") {}

    struct sdata {
        string uin;
        uint256 timeStamp;
        string brand;
        string product;
        string country;
        string price;
        string metadata;
        string _category;
    }

    struct rewards {
        string code;
        string brand;
        uint256 issueTime;
        uint256 expiryTime;
        uint256 reedemTime;
        bool isActive;
        uint256 tokenId;
        string metadata;
    }

    event SCAN(address indexed user,string indexed category,string indexed brand,string uin,string product,string price,string country,string metadata,bytes32 message,bytes sign);
    event REWARD(address indexed user,string indexed brand,string code,string metadata,uint256 expire);
    event CLAIM(address indexed user,string indexed brand,string code,bytes32 message,bytes sign);

    
    // why msg and sign here ? , you can use msg.sender directly i want know more from the frontend side
    function scanItem(
        string memory _category,
        string memory _brand,
        string memory _uin,
        string memory _product,
        string memory _price,
        string memory _country,
        string memory _metadata,
        bytes32 _message,
        bytes memory _sign
    ) external {
        address x = recoverSigner(_message, _sign);
        scanData[x].push(
            sdata(
                _uin,
                block.timestamp,
                _brand,
                _product,
                _country,
                _price,
                _metadata,
                _category
            )
        );
        emit SCAN(x,_category,_brand,_uin,_product,_price,_country,_metadata,_message,_sign);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _ethSignedMessageHash)
        );
        return ecrecover(prefixedHashMessage, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function generatereward(
        string memory _brand,
        address _user,
        string memory _code,
        string memory _metadata,
        uint256 _expire
    ) external onlyOwner {
        tokenId++;
        myrewards[_user].push(
            rewards(
                _code,
                _brand,
                block.timestamp,
                block.timestamp + _expire,
                0,
                true,
                tokenId,
                _metadata
            )
        );
        couponIndex[
            string(abi.encodePacked(_user, "$", _brand, "$", _code))
        ] = myrewards[_user].length;
        _mint(_user,tokenId, 1, "");
        setTokenURI(tokenId, _metadata);
        emit REWARD(_user, _brand, _code, _metadata, _expire);
    }



    // who is claiming this reward , why are you using message and sign here ?,
    // you can use the user address directly by using msg.sender
    // right now this function has a bug anyone having the msg and sign of specific reward can claim the reward
    function claimrewards(
        string memory _brand,
        string memory _code,
        bytes32 _mess,
        bytes memory _sign
    ) public {
        uint256 i = couponIndex[
            string(
                abi.encodePacked(
                    recoverSigner(_mess, _sign),
                    "$",
                    _brand,
                    "$",
                    _code
                )
            )
        ];
        rewards[] memory r = myrewards[recoverSigner(_mess, _sign)];
        require(r[i].expiryTime > block.timestamp, "coupon expired");
        require(r[i].isActive == true, "coupon already used");
        r[i] = rewards(
            r[i].code,
            r[i].brand,
            r[i].issueTime,
            r[i].expiryTime,
            block.timestamp,
            false,
            r[i].tokenId,
            r[i].metadata
        );
         _burn(recoverSigner(_mess, _sign), r[i].tokenId,1);
        emit CLAIM(recoverSigner(_mess, _sign), _brand, _code, _mess, _sign);
        // _safeTransferFrom(
        //     recoverSigner(_mess, _sign),
        //     0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        //     
        //     1,
        //     ""
        // );
    }

    function convertExternalString(
        string memory data
    ) external pure returns (bytes memory) {
        return bytes(data);
    }

    function setTokenURI(uint256 id, string memory _uri) public onlyOwner {
        _uris[id] = _uri;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _uris[id];
    }
}
