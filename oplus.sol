// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract oplus is ERC1155, Ownable {
    struct sdata {
        string uin;
        uint256 timestamp;
        string brand;
        string product;
        string country;
        string price;
        string _imagelink;
        string _category;
    }
    struct rewards {
        string code;
        string brand;
        uint256 issuetime;
        uint256 expirytime;
        uint256 reedemtime;
        bool isactive;
        uint256 nftid;
        string nftlink;
    }

    mapping(address => string[]) public buydata;
    mapping(address => sdata[]) public scandata;
    mapping(string => sdata[]) public scancat;
    mapping(string => string[]) public buycat;
    mapping(address => rewards[]) public myrewards;
    mapping(string => uint256) public couponindex;
    mapping(uint256 => string) private _uris;

    bytes[] public arr;
    uint256 public nftid;

    constructor() ERC1155("") {}

    function scanitem(
        string memory _category,
        string memory _brand,
        string memory _uin,
        string memory _product,
        string memory _price,
        string memory _country,
        string memory _imagelink,
        bytes32 _mess,
        bytes memory _sign
    ) external {
        address x = recoverSigner(_mess, _sign);
        scandata[x].push(
            sdata(
                _uin,
                block.timestamp,
                _brand,
                _product,
                _country,
                _price,
                _imagelink,
                _category
            )
        );
        scancat[
            string(
                abi.encodePacked(x, "$", _category)
            )
        ].push(
                sdata(
                    _uin,
                    block.timestamp,
                    _brand,
                    _product,
                    _country,
                    _price,
                    _imagelink,
                    _category
                )
            );
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

    function VerifyMessage(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
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
        string memory _link,
        uint256 _expire
    ) external onlyOwner {
        myrewards[_user].push(
            rewards(
                _code,
                _brand,
                block.timestamp,
                block.timestamp + _expire,
                0,
                true,
                nftid,
                _link
            )
        );
        couponindex[
            string(abi.encodePacked(_user, "$", _brand, "$", _code))
        ] = myrewards[_user].length;
        _mint(_user, nftid, 1, "");
        setTokenURI(nftid, _link);
        nftid++;
    }

    function claimrewards(
        string memory _brand,
        string memory _code,
        bytes32 _mess,
        bytes memory _sign
    ) public {
        uint256 i = couponindex[
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
        require(r[i].expirytime > block.timestamp, "coupon expired");
        require(r[i].isactive == true, "coupon already used");
        r[i] = rewards(
            r[i].code,
            r[i].brand,
            r[i].issuetime,
            r[i].expirytime,
            block.timestamp,
            false,
            r[i].nftid,
            r[i].nftlink
        );
        _safeTransferFrom(
            recoverSigner(_mess, _sign),
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
            r[i].nftid,
            1,
            ""
        );
    }

    function setTokenURI(uint256 tokenId, string memory _uri) public  onlyOwner {
        _uris[tokenId] = _uri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _uris[tokenId];
    }

    function convertExternalString(
        string memory dat
    ) public pure returns (bytes memory) {
        return bytes(dat);
    }
}
