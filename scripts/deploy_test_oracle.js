const hre = require("hardhat");

const admin = "0xB90e62724B6A65e0C5a918f7b407b2a3dFC6FcCd"
const setter = "0xB90e62724B6A65e0C5a918f7b407b2a3dFC6FcCd"
const muonContract = "0xE4F8d9A30936a6F8b17a73dC6fEb51a3BBABD51A"
const minimumRequiredSignatures = 1
const appId = 2500
const expireTime = 40

async function deployOracle() {
    constructorArguments = [
        muonContract,
        appId,
        minimumRequiredSignatures,
        expireTime,
        admin,
        setter
    ]
    const [signer] = await hre.ethers.getSigners()
    const contractInstance = await hre.ethers.getContractFactory("TestOracle");
    const contract = await contractInstance.deploy(...constructorArguments);
    await contract.deployed();
    console.log("Oracle deployed to:", contract.address);

    await hre.run("verify:verify", {
        address: contract.address,
        constructorArguments: constructorArguments
    });
    return contract;
}

async function main() {
    const oracle = await deployOracle();
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
