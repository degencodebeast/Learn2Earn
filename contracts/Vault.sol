//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is Ownable {
    uint256 private usdcAmount;
    uint256 private learnAmount;

    event ValueChanged(uint256 newValue);

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

    function sendUsdc(uint256 amount) external onlyOwner {
        require(usdcAmount >= amount, "Insufficient USDC balance");
        usdcAmount -= amount;
        usdcToken.transfer(owner(), amount);
        emit ValueChanged(usdcAmount);
    }

    function sendLearn(uint256 amount) external onlyOwner {
        require(learnAmount >= amount, "Insufficient Learn balance");
        learnAmount -= amount;
        learnToken.transfer(owner(), amount);
        emit ValueChanged(learnAmount);
    }

    function receiveToken(address token, uint256 amount) external {
        if (token == address(usdcToken)) {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            usdcAmount += amount;
            emit ValueChanged(usdcAmount);
        } else if (token == address(learnToken)) {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            learnAmount += amount;
            emit ValueChanged(learnAmount);
        } else {
            revert("Unsupported token");
        }
    }

    receive() external payable {
        revert(
            "You must call the receiveToken function if you wish to send USDC or LEARN tokens to this contract!"
        );
    }
}
