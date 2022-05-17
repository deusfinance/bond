const hre = require("hardhat");

const admin = "0xB90e62724B6A65e0C5a918f7b407b2a3dFC6FcCd"
// const admin = "0xB90e62724B6A65e0C5a918f7b407b2a3dFC6FcCd"

async function deployAPY() {
    constructorArguments = [
        admin,
        admin,
        BigInt(35 * 1e16)
    ]
    const [signer] = await hre.ethers.getSigners()
    const contractInstance = await hre.ethers.getContractFactory("BondApy");
    const contract = await contractInstance.deploy(...constructorArguments);
    await contract.deployed();
    console.log("BondAPY deployed to:", contract.address);

    await hre.run("verify:verify", {
        address: contract.address,
        constructorArguments: constructorArguments
    });
    return contract;
}

async function main() {
    const buyback = await deployAPY();
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
