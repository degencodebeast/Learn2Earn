const { ethers } = require("hardhat");

async function main() {
  // Deploying the contract
  const Vault = await ethers.getContractFactory("Vault");
  const usdcTokenAddress = "0x..."; // Replace with the actual USDC token address
  const learnTokenAddress = "0x..."; // Replace with the actual LEARN token address
  const vault = await Vault.deploy(usdcTokenAddress, learnTokenAddress);
  await vault.deployed();

  console.log("Vault deployed to:", vault.address);

  // Optional: Verify the contract on Etherscan
  await hre.run("verify:verify", {
    address: vault.address,
    constructorArguments: [usdcTokenAddress, learnTokenAddress],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
