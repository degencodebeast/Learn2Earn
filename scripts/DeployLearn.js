const { ethers } = require("hardhat");

async function main() {
  // Deploying the contract
  const Learn = await ethers.getContractFactory("Learn");
  const keepPercentage = 20; // Set the desired keep percentage
  const ownerAddress = "0x..."; // Replace with the owner's address

  const learn = await Learn.deploy(keepPercentage, ownerAddress);
  await learn.deployed();

  console.log("Learn contract deployed to:", learn.address);

  // Optional: Verify the contract on Etherscan
  await hre.run("verify:verify", {
    address: learn.address,
    constructorArguments: [keepPercentage, ownerAddress],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
