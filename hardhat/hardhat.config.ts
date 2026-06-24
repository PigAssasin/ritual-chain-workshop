import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import { configVariable, defineConfig } from "hardhat/config";

const solcPath = process.env.HARDHAT_SOLC_PATH;

export default defineConfig({
  plugins: [hardhatToolboxViemPlugin],
  solidity: {
    profiles: {
      default: {
        version: "0.8.24",
        path: solcPath || undefined,
      },
      production: {
        version: "0.8.24",
        path: solcPath || undefined,
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    ritual: {
      type: "http",
      chainType: "l1",
      url: "https://rpc.ritualfoundation.org",
      chainId: 1979,
      accounts: [configVariable("DEPLOYER_PRIVATE_KEY")],
    },
  },
});
