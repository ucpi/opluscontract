import { ethers, upgrades, accounts } from "hardhat";
async function main() {
  const signer = await accounts.getSigner();
  console.log(`Account ${signer.address} unlocked!`);
  const Oplus = await ethers.getContractFactory("oplus", signer);
  const oplus = await upgrades.deployProxy(Oplus);
  await oplus.deployed();
  console.log("Box deployed to:", oplus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
