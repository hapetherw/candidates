import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-dependency-compiler";
import "hardhat-gas-reporter";
import * as dotenv from "dotenv";
dotenv.config();

const chainIds = {
  ganache: 1337,
  mainnet: 1,
  ropsten: 3,
  mumbai: 80001
};

const { pk } = require("./secrets.json");

const INFURA_API_KEY = process.env.INFURA_API_KEY;
const ALCHEMY_KEY = process.env.ALCHEMY_KEY || "";
const ETHERSCAN_KEY = process.env.ETHERSCAN_KEY;

const config = {
  networks: {
    hardhat: {
      blockGasLimit: 10000000
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${INFURA_API_KEY}`,
      chainId: chainIds.ropsten,
      accounts: [pk],
      gasMultiplier: 1.25
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_KEY}`,
      chainId: chainIds.mumbai,
      accounts: [pk],
      gasMultiplier: 1.25
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_KEY
  },
  solidity: {
    compilers: [
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  mocha: {
    timeout: 30000,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  dependencyCompiler: {
  },
};

export default config;
