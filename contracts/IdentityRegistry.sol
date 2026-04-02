// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract IdentityRegistry is ERC721, Ownable {
    using Strings for uint256;

    uint256 private _nextTokenId;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) public agentOwner; // agentId => owner address

    event IdentityRegistered(uint256 indexed agentId, address indexed owner, string uri);

    constructor() ERC721("AgentIdentity", "AID") Ownable(msg.sender) {}

    function mintIdentity(string memory uri) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _tokenURIs[tokenId] = uri;
        agentOwner[tokenId] = msg.sender;
        emit IdentityRegistered(tokenId, msg.sender, uri);
        return tokenId;
    }

    function setAgentURI(uint256 agentId, string memory uri) external {
        require(ownerOf(agentId) == msg.sender, "Not agent owner");
        _tokenURIs[agentId] = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURIs[tokenId];
    }

    function getAgent(uint256 agentId) external view returns (address owner, string memory uri) {
        owner = ownerOf(agentId);
        uri = _tokenURIs[agentId];
    }
}