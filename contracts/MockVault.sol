// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ReputationRegistry.sol"; 

contract MockVault is Ownable, ReentrancyGuard {
    IERC20 public stablecoin;
    mapping(uint256 => uint256) public balances;
    ReputationRegistry public reputation;

    event Deposited(uint256 indexed agentId, uint256 amount);
    event Withdrawn(uint256 indexed agentId, uint256 amount);
    event PnLRecorded(uint256 indexed agentId, int256 pnl, uint256 newBalance, uint256 timestamp);

    // Update constructor to accept reputation address
    constructor(address _stablecoin, address _reputation) Ownable(msg.sender) {
        stablecoin = IERC20(_stablecoin);
        reputation = ReputationRegistry(_reputation);
    }

    function deposit(uint256 agentId, uint256 amount) external nonReentrant {
        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[agentId] += amount;
        emit Deposited(agentId, amount);
    }

    function withdraw(uint256 agentId, uint256 amount) external nonReentrant {
        require(balances[agentId] >= amount, "Insufficient balance");
        balances[agentId] -= amount;
        require(stablecoin.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(agentId, amount);
    }

    // Called by RiskRouter after trade execution
    function recordTrade(uint256 agentId, uint256 amountIn, uint256 amountOut) external {
        // In production, ensure only RiskRouter can call this
        int256 pnl = int256(amountOut) - int256(amountIn);
        balances[agentId] = balances[agentId] + amountOut - amountIn;
        emit PnLRecorded(agentId, pnl, balances[agentId], block.timestamp);

        // Auto-update reputation
        reputation.recordPnL(agentId, pnl);
    }
}