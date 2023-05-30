const { ethers } = require("hardhat");

async function main() {
  // Deploying the contract
  const CommunityForum = await ethers.getContractFactory("CommunityForum");
  const learnAddress = "0x..."; // Replace with the token address
  const maxReward = ethers.utils.parseEther("10"); // Set the desired max reward

  const communityForum = await CommunityForum.deploy(tokenAddress, maxReward);
  await communityForum.deployed();

  console.log("CommunityForum contract deployed to:", communityForum.address);

  // Optional: Verify the contract on Etherscan
  await hre.run("verify:verify", {
    address: communityForum.address,
    constructorArguments: [tokenAddress, maxReward],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
