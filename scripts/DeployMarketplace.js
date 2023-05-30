const { ethers } = require("hardhat");

async function main() {
  // Deploying the contract
  const LearningPlatform = await ethers.getContractFactory("LearningPlatform");
  const usdcTokenAddress = "0x..."; // Replace with the address of the USDC token
  const daoAddress = "0x..."; // Replace with the address of the DAO

  const learningPlatform = await LearningPlatform.deploy(
    usdcTokenAddress,
    daoAddress
  );
  await learningPlatform.deployed();

  console.log(
    "LearningPlatform contract deployed to:",
    learningPlatform.address
  );

  // Optional: Verify the contract on Etherscan
  await hre.run("verify:verify", {
    address: learningPlatform.address,
    constructorArguments: [usdcTokenAddress, daoAddress],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
