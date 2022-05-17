const hre = require('hardhat')

const admin = '0xEf6b0872CfDF881Cf9Fe0918D3FA979c616AF983'
const setter = '0xEf6b0872CfDF881Cf9Fe0918D3FA979c616AF983'
const muon = '0xE4F8d9A30936a6F8b17a73dC6fEb51a3BBABD51A'
const spookyPair = '0xaF918eF5b9f33231764A5557881E6D3e5277d456'
const spookyV2Router = '0xF491e7B69E4244ad4002BC14e878a34207E38c29'
const ftmUsdPriceFeed = '0xf4766552D15AE4d256Ad41B6cf2933482B0680dc'
const onChainThreshold = BigInt(0.005e18)
const muonThreshold = BigInt(0.001e18)
const minimumRequiredSignatures = 1
const appId = 30
const validEpoch = 40

async function deployOracle() {
  constructorArguments = [
    spookyPair,
    spookyV2Router,
    ftmUsdPriceFeed,
    muon,
    appId,
    minimumRequiredSignatures,
    validEpoch,
    onChainThreshold,
    muonThreshold,
    admin,
    setter,
  ]
  const contractInstance = await hre.ethers.getContractFactory(
    'Oracle',
  )
  const contract = await contractInstance.deploy(...constructorArguments)
  await contract.deployed()
  console.log('Oracle deployed to:', contract.address)

  await hre.run('verify:verify', {
    address: contract.address,
    constructorArguments: constructorArguments,
  })
  return contract
}

async function main() {
  const oracle = await deployOracle()
  // console.log((await oracle.getOnChainPrice()).toBigInt())
  return
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
