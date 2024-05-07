// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721Enumerable, Ownable {
    // NFT struct to store basic NFT information
    struct NFT {
        address owner;
        uint256 price;
        bool isListed;
    }

    // Mapping from token ID to NFT
    mapping(uint256 => NFT) private nfts;

    // Events
    event NFTListed(uint256 indexed tokenId, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId);
    event NFTSold(uint256 indexed tokenId, address buyer, uint256 price);

    // Constructor to initialize the contract
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // List an NFT for sale
    function listNFT(uint256 tokenId, uint256 price) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Market: Caller is not owner nor approved");
        require(price > 0, "Market: Price must be greater than 0");

        nfts[tokenId] = NFT(_msgSender(), price, true);
        emit NFTListed(tokenId, price);
    }

    // Unlist an NFT from sale
    function unlistNFT(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Market: Caller is not owner nor approved");

        delete nfts[tokenId];
        emit NFTUnlisted(tokenId);
    }

    // Buy an NFT that is listed for sale
    function buyNFT(uint256 tokenId) external payable {
        NFT storage nft = nfts[tokenId];
        require(nft.isListed, "Market: NFT not listed for sale");
        require(msg.value >= nft.price, "Market: Insufficient funds");

        address seller = nft.owner;
        nft.isListed = false;
        nft.owner = _msgSender();

        payable(seller).transfer(msg.value);
        emit NFTSold(tokenId, _msgSender(), nft.price);

        _transfer(seller, _msgSender(), tokenId);
    }

    // Get the details of an NFT
    function getNFT(uint256 tokenId) external view returns (address owner, uint256 price, bool isListed) {
        NFT storage nft = nfts[tokenId];
        return (nft.owner, nft.price, nft.isListed);
    }

    // Override ERC721 _baseURI function to return the base URI
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    // Override isApprovedForAll to enable the contract to operate on behalf of the owner
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return owner == _msgSender() || super.isApprovedForAll(owner, operator);
    }

    // Withdraw the contract balance to the owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // Fallback function to receive ethers
    receive() external payable {}
}