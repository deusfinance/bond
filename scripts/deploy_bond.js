const hre = require("hardhat");

const usdc = '0x04068da6c83afcfa0e13ba15a6696662335d5b75'
const dei = '0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3'
const admin = "0xB90e62724B6A65e0C5a918f7b407b2a3dFC6FcCd"
const trusty = "0xB90e62724B6A65e0C5a918f7b407b2a3dFC6FcCd"
const deus = "0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44"

// todo should set
const nft = "0x1e976649939a33b554035067a2DD41F47Cac36ef"
const escape = "0x1ad2af7c7F80a94eE9343Bca0cdf1898e8Aa64F3"
const apy = "0x77F4Cca31F7Bd18B865c22BaCBfeE4303461d22B"
const oracle = "0xc19Efb4c7bA36d7ECC0225946ae3A4C78364C7FB"
const capacity = BigInt(100*1e6)


async function deployBond() {

    constructorArguments = [
        admin,
        trusty,
        deus,
        dei,
        usdc,
        nft,
        apy,
        escape,
        oracle,
        capacity
    ]
    const [signer] = await hre.ethers.getSigners()
    const contractInstance = await hre.ethers.getContractFactory("DeiBonds");
    const contract = await contractInstance.deploy(...constructorArguments);
    await contract.deployed();
    console.log("DeiBonds deployed to:", contract.address);

    await hre.run("verify:verify", {
        address: contract.address,
        constructorArguments: constructorArguments
    });
    // return contract;
}

async function main() {
    const amo = await deployBond();

    return;
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
