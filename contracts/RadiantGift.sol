// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact sage@sagetowers.com
contract RadiantGift is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl, ERC721Burnable  {
    using Counters for Counters.Counter;
    string public image = "ipfs://QmS7mQFBMVZFZbBayDmo8fYey3p4DLtabzwhAWvACqrCJX";
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;
    uint256 public maxSupply;
    string private _baseURIExtended;
    string private ContractURI;

    constructor() ERC721("Radiant Gift", "RGIFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        maxSupply = 10000;
        _baseURIExtended = "https://metadata.sagetowers.com/rgift/";
        ContractURI= "ipfs://QmRZKfc4S8obsYcZjW8VoMny7d6JeKNLbZnbSz8E39TvAg";
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = newMaxSupply;
    }

    function setBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURIExtended = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }
    
    function setContractURI(string memory newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ContractURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        return ContractURI;
    }

    function mint(address to, string memory rng) public onlyRole(MINTER_ROLE) {
        require(_tokenIdCounter.current() < maxSupply, "Maximum supply reached");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
         bytes32 hash = keccak256(
            abi.encodePacked(
                tokenId,
                block.number+8,
                blockhash(block.number - 1),
                rng
            )
        );
        tokenIdToHash[tokenId] = hash;
        hashToTokenId[hash] = tokenId;
        _mint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}