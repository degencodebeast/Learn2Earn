const { ethers } = require("hardhat");

async function main() {
  // Deploying the contract
  const Degree = await ethers.getContractFactory("Degree");
  const burnerAddress = "0x..."; // Replace with the burner address
  const degree = await Degree.deploy(burnerAddress);
  await degree.deployed();

  console.log("Degree contract deployed to:", degree.address);

  // Optional: Verify the contract on Etherscan
  await hre.run("verify:verify", {
    address: degree.address,
    constructorArguments: [burnerAddress],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
