const path = require('path');
const envPath = path.join(__dirname, './.env');
require('dotenv').config({path: envPath});

require('hardhat-deploy');
require('hardhat-contract-sizer');
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');

task("accounts", "Prints the list of accounts", async () => {
    const accounts = await ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            forking: {
                url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API}`,
            },
            chainId: 250,
        },
        localhostMainnet: {
            url: 'http://127.0.0.1:8545',
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY
            ],
        },
        localhostFantom: {
            url: 'http://127.0.0.1:8547',
            chainId: 250,
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY,
            ],
        },
        localhostPolygon: {
            url: 'http://127.0.0.1:8546',
            chainId: 137,
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY
            ],
        },
        ropsten: {
            url: `https://ropsten.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY,
            ],
            chainId: 3,
            gas: "auto",
            minGasPrice: 1000000000,
            initialBaseFeePerGas: 360000000,
            gasPrice: "auto",
            gasMultiplier: 1.2
        },
        rinkeby: {
            url: `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY,
            ],
            chainId: 4,
            gas: "auto",
            gasPrice: 3100000000,
            gasMultiplier: 1.2
        },
        mainnet: {
            url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY,
            ],
            chainId: 1,
            gas: "auto",
            gasPrice: 77100000000,
            gasMultiplier: 1.2
        },
        heco: {
            url: "https://http-mainnet.hecochain.com",
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY,
            ],
            chainId: 128,
            gas: "auto",
            gasPrice: "auto",
            gasMultiplier: 1.2
        },
        avalanche: {
            url: "https://api.avax.network/ext/bc/C/rpc",
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY,
            ],
            chainId: 43114,
            gas: "auto",
            gasPrice: "auto",
            gasMultiplier: 1.2
        },
        fuji: {
            url: "https://api.avax-test.network/ext/bc/C/rpc",
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY,
            ],
            chainId: 43113,
            gas: "auto",
            gasPrice: "auto",
            gasMultiplier: 1.2
        },
        polygon: {
            url: "https://polygon-rpc.com/",
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY,
            ],
            chainId: 137,
            gas: "auto",
            gasPrice: 60000000000,
            gasMultiplier: 3.6
        },
        fantom: {
            url: "https://rpc.ftm.tools/",
            accounts: [
                process.env.DEPLOYER_PRIVATE_KEY,
                process.env.SECONDARY_DEPLOYER_PRIVATE_KEY
            ],
            chainId: 250,
            gas: "auto",
            gasPrice: "auto",
            gasMultiplier: 1.2
        }
    },
    solidity: {
        compilers: [
            {
                version: "0.4.18",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.5.0",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.6.0",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.6.2",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.6.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.6.11",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.7.0",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.7.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.8.7",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.8.9",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.8.12",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            },
            {
                version: "0.8.13",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            }
        ],
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    mocha: {
        timeout: 360000
    },
    etherscan: {
        // apiKey: process.env.ETHERSCAN_API_KEY, // ETH Mainnet
        apiKey: process.env.FANTOM_API_KEY, // ETH Mainnet
        // apiKey: process.env.HECO_API_KEY, // HECO Mainnet
        // apiKey: process.env.BSCSCAN_API_KEY // BSC
    },

    contractSizer: {
        alphaSort: true,
        runOnCompile: true,
        disambiguatePaths: false,
    },
};

