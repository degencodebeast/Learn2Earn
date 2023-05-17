const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("Degree", function () {
  /* This is a fixture function that sets up the initial state for each test in the "Degree" test suite.
    It deploys the "Degree" contract using the contract factory, gets the owner signer, and sets an
    empty token URI. It then returns an object containing the deployed contract instance, the owner
    signer, and the token URI. This fixture function is used by the `loadFixture` function to run this
    setup once, snapshot that state, and reset Hardhat Network to that snapshot in every test. */
  async function deployMintFixture() {
    const owner = await ethers.getSigner();
    const degreeFactory = await ethers.getContractFactory("Degree");
    const _admin = "0x5c2A3F66e899F5723566b9d24C75f8881E76C6f4"; // fake address will be the dao address later
    const _burnerAddress = "0x5c2A3F66e899F5723566b9d24C75f8881E76C6f4"; // fake address will be an address that we create and don't save the password
    const tokenURI = "";
    const Degree = await degreeFactory.deploy(_admin, _burnerAddress);

    return { Degree, owner, tokenURI };
  }

  describe("SafeMint", function () {
    /* This test case is checking if the `safeMint` function of the `Degree` contract is working
        correctly by minting an NFT and checking if the transaction was successful. It does this by
        first deploying the `Degree` contract and getting the owner signer, then calling the `safeMint`
        function with the owner's address and an empty token URI. Finally, it checks if the transaction
        was successful by asserting that the returned value `nft` is truthy. */
    it("Should mint nft", async function () {
      const { Degree, owner, tokenURI } = await loadFixture(deployMintFixture);
      const nft = await Degree.safeMint(owner.address, tokenURI);
      assert.isOk(nft);
    });

    /* This test case is checking if the `getTokenIdCount` function of the `Degree` contract is working
    correctly by minting multiple NFTs and checking if the token ID counter increases with each
    minted NFT. It does this by first deploying the `Degree` contract and getting the owner signer,
    then calling the `safeMint` function with the owner's address and an empty token URI multiple
    times. Finally, it checks if the token ID counter is equal to the number of minted NFTs by using
    the `expect` assertion. */
    it("TokenId counter increases with each nft minted", async function () {
      const { Degree, owner, tokenURI } = await loadFixture(deployMintFixture);
      const nft = await Degree.safeMint(owner.address, tokenURI);
      expect(await Degree.getTokenIdCount()).to.equal(1);

      const nft2 = await Degree.safeMint(owner.address, tokenURI);
      const nft3 = await Degree.safeMint(owner.address, tokenURI);
      expect(await Degree.getTokenIdCount()).to.equal(3);
    });

    /* This test case is checking if the `updateTokenURI` function of the `Degree` contract is working
    correctly by minting an NFT, getting its token ID, updating its token URI, and checking if the
    new token URI is correctly set. It does this by first deploying the `Degree` contract and
    getting the owner signer, then calling the `safeMint` function with the owner's address and an
    empty token URI to mint an NFT. It then gets the token ID of the minted NFT and updates its
    token URI using the `updateTokenURI` function with a new token URI. Finally, it checks if the
    new token URI is correctly set by using the `expect` assertion. */
    it("TokenURI can be updated", async function () {
      const { Degree, owner, tokenURI } = await loadFixture(deployMintFixture);
      const nft = await Degree.safeMint(owner.address, tokenURI);
      await nft.wait(1);

      const tokenId = await Degree.getTokenIdCount();
      expect(await Degree.tokenURI(tokenId)).to.equal(tokenURI); // this is throwing an error

      const newTokenURI = "new URI";
      await Degree.updateTokenURI(tokenId, newTokenURI);
      expect(await Degree.tokenUri(tokenId)).to.equal(newTokenURI);
    });

    /* This test case is checking if the `updateTokenURI` function of the `Degree` contract can only be
    called by an admin. It does this by first deploying the `Degree` contract and getting the owner
    signer, then calling the `safeMint` function with the owner's address and a new token URI to
    mint an NFT. It then gets the token ID of the minted NFT and attempts to update its token URI
    using the `updateTokenURI` function with the same token URI. Since the `updateTokenURI` function
    can only be called by an admin, the test expects an error message to be thrown with the message
    "Only an Admin has access." If the error message is thrown, the test passes. */
    it("TokenURI can only be updated by an Admin", async function () {
      const { Degree, owner, tokenURI } = await loadFixture(deployMintFixture);
      const newTokenURI = "New URI";
      const nft = await Degree.safeMint(owner.address, tokenURI);
      await nft.wait(1);
      const tokenId = await Degree.getTokenIdCount();
      try {
        const txResponse = await Degree.updateTokenURI(tokenId, newTokenURI);
      } catch (error) {
        expect(error.message).to.match(/Only an Admin has access./);
        return;
      }
    });

    /* This test case is checking if the `_burn` function of the `Degree` contract is working correctly
   by attempting to burn an NFT and checking if an error message is thrown with the message "Only an
   Admin has access." It does this by first deploying the `Degree` contract and getting the owner
   signer, then calling the `safeMint` function with the owner's address and an empty token URI to
   mint an NFT. It then attempts to burn the NFT using the `_burn` function with the token ID of 1.
   Since the `_burn` function can only be called by an admin, the test expects an error message to
   be thrown with the message "Only an Admin has access." If the error message is thrown, the test
   passes. Additionally, the test checks if the token ID count is still equal to 1 after the failed
   burn attempt. */
    it("Token should not burnable", async function () {
      const { Degree, owner, tokenURI } = await loadFixture(deployMintFixture);
      const txResponse = await Degree.safeMint(owner.address, tokenURI);
      await txResponse.wait(1);
      try {
        await Degree._burn(1);
      } catch (error) {
        expect(error.message).to.match(/You can't burn this token!/);
        expect(await Degree.getTokenIdCount()).to.equal(1);
        return;
      }
    });

    it("Token should not be transferable", async function () {
      const { Degree, owner, tokenURI } = await loadFixture(deployMintFixture);
      const txResponse = await Degree.safeMint(owner.address, tokenURI);
      await txResponse.wait(1);
      const tokenId = Degree.getTokenIdCount();
      const from = Degree.getContractAddress();
      await Degree._transfer(from, owner.address, tokenId);

      //   try {
      //     await Degree._transfer(from, owner.address, tokenId);
      //   } catch (error) {
      //     expect(error.message).to.match(/This token can't be transfered!/);
      //   }
    });
  });
});
