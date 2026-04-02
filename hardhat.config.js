// hardhat.config.js
import "@nomicfoundation/hardhat-toolbox";

export default {
  solidity: {
    version: "0.8.24",
    settings: {
        evmVersion: "paris", // avoids mcopy opcode
        optimizer: { enabled: true, runs: 200 }
    }
  },
  networks: {
    hardhat: {
      chainId: 31337,
      // Pre-fund your agent account
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
        accountsBalance: "1000000000000000000000000" // 1M ETH for testing
      },
      // Enable mining on every transaction for predictable testing
      mining: {
        auto: true,
        interval: 0
      }
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    }
  },
  // For EIP-712 testing
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};