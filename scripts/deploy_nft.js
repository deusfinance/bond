const hre = require("hardhat");

// const admin = "0x2408E836eBfcF135731Df4Cf357C10a7b65193bF"
const admin = "0x2408E836eBfcF135731Df4Cf357C10a7b65193bF"

async function deployNft() {
    constructorArguments = [
        admin
    ]
    const [signer] = await hre.ethers.getSigners()
    const contractInstance = await hre.ethers.getContractFactory("BondNFT");
    const contract = await contractInstance.deploy(...constructorArguments);
    await contract.deployed();
    console.log("BondNFT deployed to:", contract.address);

    await hre.run("verify:verify", {
        address: contract.address,
        constructorArguments: constructorArguments
    });
    return contract;
}

async function main() {
    const buyback = await deployNft();
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