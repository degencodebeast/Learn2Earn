//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Vault is Ownable, ReentrancyGuard {
    uint256 public usdcAmount;
    uint256 public learnAmount;

    event TokensWithdrawn(uint256 amount, IERC20 token);
    event TokensDeposited(uint256 amount, IERC20 token);

    IERC20 public usdcToken;
    IERC20 public learnToken;

    constructor(address _usdcToken, address _learnToken) {
        usdcToken = IERC20(_usdcToken);
        learnToken = IERC20(_learnToken);
    }

    function retrieveUsdc() public view returns (uint256) {
        return usdcAmount;
    }

    function retrieveLearn() public view returns (uint256) {
        return learnAmount;
    }

    function withdrawUsdc(
        uint256 amount,
        address student
    ) external onlyOwner nonReentrant {
        require(usdcAmount >= amount, "Insufficient USDC balance");
        usdcAmount -= amount;
        usdcToken.transfer(student, amount);
        emit TokensWithdrawn(amount, usdcToken);
    }

    function withdrawLearn(uint256 amount) external onlyOwner nonReentrant {
        require(learnAmount >= amount, "Insufficient Learn balance");
        learnAmount -= amount;
        learnToken.transfer(owner(), amount);
        emit TokensWithdrawn(amount, learnToken);
    }

    function depositToken(address token, uint256 amount) external nonReentrant {
        if (token == address(usdcToken)) {
            usdcToken.approve(address(this), amount); // Approve the contract to spend the tokens
            usdcToken.transferFrom(msg.sender, address(this), amount);
            usdcAmount += amount;

            emit TokensDeposited(amount, usdcToken);
        } else if (token == address(learnToken)) {
            learnToken.approve(address(this), amount); // Approve the contract to spend the tokens
            learnToken.transferFrom(msg.sender, address(this), amount);
            learnAmount += amount;

            emit TokensDeposited(amount, learnToken);
        } else {
            revert("Unsupported token");
        }
    }

    receive() external payable {
        revert(
            "You must call the depositToken function if you wish to send USDC or LEARN tokens to this contract!"
        );
    }
}
