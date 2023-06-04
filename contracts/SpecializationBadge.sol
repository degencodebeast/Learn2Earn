// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SpecializationBadge is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => string) _tokenURIs;

    // Events
    event NftMinted(address to, uint256 tokenId);
    event TokenUriUpdated(uint256 tokenId, string uri);

    /**
     * @dev Initializes the contract by setting an admin and burner address. The burner address is used to create a modifier so that nobody is able to burn their nft.
     */
    constructor() ERC721("Degree", "DEG") {}

    function getTokenIdCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _baseURI() internal pure override returns (string memory) {
        return ""; // insert base uri
    }

    /**
     * @dev This function is not meant to be but is required to be implemented by solidity. To make sure it can't be called, the onlyBurner modifier was made with an address that we created. As an additional precaution when the function is called it reverts.
     * @param tokenId .
     */
    function _burn(
        uint256 tokenId
    ) internal view override(ERC721, ERC721URIStorage) {
        revert("This badge can not be burned!");
    }

    /**
     * @dev     The following function's override is required.
     * @param   tokenId .
     * @return  string
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev
     * @param   to  .
     * @param   uri .
     */
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _tokenURIs[tokenId] = uri;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit NftMinted(to, tokenId);
    }

    /**
     * @dev
     * @param   from    .
     * @param   to  .
     * @param   firstTokenId    .
     * @param   batchSize   .
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        require(from == address(0), "This token can't be transfered!");
    }

    /**
     * @dev
     * @param   from    .
     * @param   to  .
     * @param   tokenId .
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override onlyOwner {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev     Function updates tokenUri. It will be called automatically by the chainlink keepers when a course is completed.
     * @param   tokenId .
     * @param   uri .
     */
    function updateTokenURI(
        uint256 tokenId,
        string memory uri
    ) public onlyOwner {
        _setTokenURI(tokenId, uri);
        _tokenURIs[tokenId] = uri;

        emit TokenUriUpdated(tokenId, uri);
    }
}
