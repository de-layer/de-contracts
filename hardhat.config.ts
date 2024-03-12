// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config';

import '@layerzerolabs/toolbox-hardhat';
import '@nomiclabs/hardhat-ethers';
import 'hardhat-contract-sizer';
import 'hardhat-deploy';
// import "@nomicfoundation/hardhat-verify";
import "@nomiclabs/hardhat-etherscan";

import { HardhatUserConfig, HttpNetworkAccountsUserConfig } from 'hardhat/types';

import { EndpointId } from '@layerzerolabs/lz-definitions';

// Set your preferred authentication method
//
// If you prefer using a mnemonic, set a MNEMONIC environment variable
// to a valid mnemonic
const MNEMONIC = process.env.MNEMONIC;

// If you prefer to be authenticated using a private key, set a PRIVATE_KEY environment variable
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const accounts: HttpNetworkAccountsUserConfig | undefined = MNEMONIC
    ? { mnemonic: MNEMONIC }
    : PRIVATE_KEY
        ? [PRIVATE_KEY]
        : undefined;

if (accounts == null) {
    console.warn(
        'Could not find MNEMONIC or PRIVATE_KEY environment variables. It will not be possible to execute transactions in your example.'
    );
}

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: '0.8.22',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    networks: {
        mainnet: {
            chainId: 1,
            eid: EndpointId.ETHEREUM_V2_MAINNET,
            url: "https://1rpc.io/eth",
            accounts
        },
        base: {
            chainId: 8453,
            eid: EndpointId.BASE_V2_MAINNET,
            url: "https://1rpc.io/base",
            accounts
        },
    },
    namedAccounts: {
        deployer: {
            default: 0, // wallet address of index[0], of the mnemonic in .env
        },
    },
    etherscan: {
        apiKey: {
          mainnet: process.env.ETHERSCAN_API_KEY,
          base: process.env.BASESCAN_API_KEY,
        },
        customChains: [
          {
            network: "base",
            chainId: 8453,
            urls: {
              apiURL: "https://api.basescan.org/api",
              browserURL: "https://basescan.org"
            }  
          }
        ]
      },
};

export default config;
