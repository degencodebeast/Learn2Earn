// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Certificate is ERC721, ERC721URIStorage, Ownable {
    // Events
    event NftMinted(address to, uint256 tokenId);

    constructor() ERC721("Certificate", "CERT") {}

    function _baseURI() internal pure override returns (string memory) {
        return ""; // insert base uri
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyOwner {
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

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal view override(ERC721, ERC721URIStorage) {
        revert("This badge can not be burned!");
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
