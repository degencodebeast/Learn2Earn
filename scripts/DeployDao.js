const { ethers } = require("hardhat");

async function main() {
  // Deploying the contract
  const Dao = await ethers.getContractFactory("Dao");
  const tokenAddress = "0x..."; // Replace with the token address
  const timelockAddress = "0x..."; // Replace with the timelock contract address
  const votingDelay = 1; // Set the desired voting delay
  const votingPeriod = 50400; // Set the desired voting period
  const quorumPercentage = 50; // Set the desired quorum percentage

  const dao = await Dao.deploy(
    tokenAddress,
    timelockAddress,
    votingDelay,
    votingPeriod,
    quorumPercentage
  );
  await dao.deployed();

  console.log("Dao contract deployed to:", dao.address);

  // Optional: Verify the contract on Etherscan
  await hre.run("verify:verify", {
    address: dao.address,
    constructorArguments: [
      tokenAddress,
      timelockAddress,
      votingDelay,
      votingPeriod,
      quorumPercentage,
    ],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
