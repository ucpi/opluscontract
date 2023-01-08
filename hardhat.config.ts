import { HardhatUserConfig } from "hardhat/config";
import "hardhat-secure-accounts";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
require("dotenv").config({ path: ".env" });

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    mumbai: {
      url: process.env.MUMBAI_RPC_URL,
    },
  },
  paths: {
    accounts: ".accounts",
  },
};

export default config;
