// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MockVault.sol";
import "./IdentityRegistry.sol"; 

contract MockRiskRouter is EIP712, Ownable {
    MockVault public vault;
    IERC20 public stablecoin;
    IdentityRegistry public identityRegistry;

    uint256 public maxPositionSize = 10000 * 1e6;
    uint256 public maxDailyLoss = 1000 * 1e6;
    mapping(uint256 => uint256) public dailyLoss;

    bytes32 private constant _TRADE_INTENT_TYPEHASH =
        keccak256("TradeIntent(uint256 agentId,address tokenIn,address tokenOut,uint256 amountIn,uint256 minAmountOut,uint256 deadline,bytes32 riskParams)");

    struct TradeIntent {
        uint256 agentId;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        uint256 deadline;
        bytes32 riskParams;
    }

    event TradeExecuted(uint256 indexed agentId, uint256 amountIn, uint256 amountOut, uint256 timestamp);
    event RiskCheckPassed(uint256 indexed agentId, bytes32 riskParams);

    // Update constructor to accept IdentityRegistry address
    constructor(address _vault, address _stablecoin, address _identityRegistry)
        EIP712("MockRiskRouter", "1")
        Ownable(msg.sender)
    {
        vault = MockVault(_vault);
        stablecoin = IERC20(_stablecoin);
        identityRegistry = IdentityRegistry(_identityRegistry); // <-- Store it
    }

    function executeTrade(TradeIntent calldata intent, bytes calldata signature) external {
        require(intent.deadline >= block.timestamp, "Deadline expired");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                _TRADE_INTENT_TYPEHASH,
                intent.agentId,
                intent.tokenIn,
                intent.tokenOut,
                intent.amountIn,
                intent.minAmountOut,
                intent.deadline,
                intent.riskParams
            ))
        );
        address signer = ECDSA.recover(digest, signature);

        require(signer == identityRegistry.ownerOf(intent.agentId), "Invalid signature");

        require(intent.amountIn <= maxPositionSize, "Exceeds max position size");

        uint256 potentialLoss = intent.amountIn;
        require(dailyLoss[intent.agentId] + potentialLoss <= maxDailyLoss, "Daily loss limit exceeded");
        dailyLoss[intent.agentId] += potentialLoss;

        // Mock swap - in reality you'd interact with a DEX
        uint256 amountOut = intent.amountIn;

        vault.recordTrade(intent.agentId, intent.amountIn, amountOut);

        emit TradeExecuted(intent.agentId, intent.amountIn, amountOut, block.timestamp);
        emit RiskCheckPassed(intent.agentId, intent.riskParams);
    }

    function setMaxPositionSize(uint256 newMax) external onlyOwner {
        maxPositionSize = newMax;
    }

    function resetDailyLoss(uint256 agentId) external onlyOwner {
        dailyLoss[agentId] = 0;
    }
}