// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ReputationRegistry is Ownable {
    struct Reputation {
        uint256 score;      // current reputation (0-100)
        uint256 lastUpdated;
        uint256 totalTrades;
        int256 cumulativePnl;
    }

    mapping(uint256 => Reputation) public reputations;
    mapping(uint256 => mapping(address => bool)) public validators; // agentId -> validator -> isValidator

    event ReputationUpdated(uint256 indexed agentId, uint256 newScore, uint256 timestamp);
    event PnLRecorded(uint256 indexed agentId, int256 pnl, uint256 timestamp);
    event ValidatorScorePosted(uint256 indexed agentId, address indexed validator, uint8 score);

    constructor() Ownable(msg.sender) {}

    function addValidator(uint256 agentId, address validator) external onlyOwner {
        validators[agentId][validator] = true;
    }

    // Called by Vault after each trade
    function recordPnL(uint256 agentId, int256 pnl) external {
        Reputation storage rep = reputations[agentId];
        rep.totalTrades++;
        rep.cumulativePnl += pnl;
        _updateReputation(agentId);
    }

    // Called by ValidationRegistry when a validator posts a score
    function recordValidatorScore(uint256 agentId, uint8 score) external {
        require(validators[agentId][msg.sender], "Not a validator for this agent");
        // Simple reputation update: 70% PnL-based, 30% validator score
        Reputation storage rep = reputations[agentId];
        // Compute pnl-based score (normalize to 0-100)
        uint256 pnlScore = _normalizePnl(rep.cumulativePnl, rep.totalTrades);
        uint256 newScore = (pnlScore * 70 + uint256(score) * 30) / 100;
        rep.score = newScore;
        rep.lastUpdated = block.timestamp;
        emit ReputationUpdated(agentId, newScore, block.timestamp);
        emit ValidatorScorePosted(agentId, msg.sender, score);
    }

    function _normalizePnl(int256 cumulativePnl, uint256 totalTrades) internal pure returns (uint256) {
        if (totalTrades == 0) return 50; // neutral start
        // Simple normalization: cap at ±1000% return -> score 0-100
        int256 avgPnl = cumulativePnl / int256(totalTrades);
        // Assume pnl in stablecoin terms; map to 0-100
        if (avgPnl >= 0) {
            return uint256(50 + (avgPnl * 50) / 1000); // max 100 at avgPnl=1000
        } else {
            return uint256(50 - (uint256(-avgPnl) * 50) / 1000); // min 0 at avgPnl=-1000
        }
    }

    function _updateReputation(uint256 agentId) internal {
        Reputation storage rep = reputations[agentId];
        uint256 pnlScore = _normalizePnl(rep.cumulativePnl, rep.totalTrades);
        // If no validator scores yet, use only pnlScore
        rep.score = pnlScore;
        rep.lastUpdated = block.timestamp;
        emit ReputationUpdated(agentId, rep.score, block.timestamp);
    }

    function getReputation(uint256 agentId) external view returns (uint256 score, uint256 lastUpdated, uint256 totalTrades) {
        Reputation storage rep = reputations[agentId];
        return (rep.score, rep.lastUpdated, rep.totalTrades);
    }
}