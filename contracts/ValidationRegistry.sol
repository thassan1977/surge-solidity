// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ValidationRegistry is Ownable {
    struct Validation {
        bytes32 artifactHash;    // hash of off-chain artifact (e.g., IPFS CID keccak256)
        uint8 score;             // validator score (0-100)
        uint256 timestamp;
        address validator;
    }

    mapping(uint256 => Validation[]) public validations; // agentId => array
    mapping(uint256 => mapping(address => bool)) public validators; // agentId -> validator -> isValidator

    event ValidationPosted(uint256 indexed agentId, bytes32 artifactHash, uint8 score, address indexed validator);

    constructor() Ownable(msg.sender) {}

    function addValidator(uint256 agentId, address validator) external onlyOwner {
        validators[agentId][validator] = true;
    }

    function postValidation(uint256 agentId, bytes32 artifactHash, uint8 score) external {
        require(validators[agentId][msg.sender], "Not a validator for this agent");
        require(score <= 100, "Score out of range");
        validations[agentId].push(Validation(artifactHash, score, block.timestamp, msg.sender));
        emit ValidationPosted(agentId, artifactHash, score, msg.sender);

        // Also update reputation via ReputationRegistry (requires interface)
        // This assumes ReputationRegistry is known; you can store its address.
        // We'll handle this via a separate call from the agent or an oracle.
        // For simplicity, the agent will call ReputationRegistry.recordValidatorScore separately.
    }

    function getValidations(uint256 agentId) external view returns (Validation[] memory) {
        return validations[agentId];
    }
}