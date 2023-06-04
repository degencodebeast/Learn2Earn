// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.18;

contract Learn is ERC20, ERC20Permit, ERC20Votes, Ownable {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint256) public userTokens;

    address[] public holders;
    address immutable i_owner;
    uint256 totalSupply;

    // events for the governance token
    event TokenTransfered(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event TokenMinted(address indexed to, uint256 amount);
    event TokenBurned(address indexed from, uint256 amount);

    constructor(
        uint256 _keepPercentage,
        address _owner
    ) ERC20("Learn", "LEARN") ERC20Permit("Learn") {
        totalSupply = (1000000 * 10 ** 18);
        uint256 keepAmount = (totalSupply * _keepPercentage) / 100; // amount of tokens kept for the vault
        _mint(msg.sender, totalSupply - keepAmount);
        holders.push(msg.sender);
        i_owner = _owner;
    }

    // Award governence tokens use chainlink automation / keepers
    function awardTokens(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
        userTokens[recipient] += amount;
        if (userTokens[recipient] == amount) {
            holders.push(recipient);
        }
    }

    function getNumberOfHolders() external view returns (uint256) {
        return holders.length;
    }

    // Overrides required for Solidiy
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
        emit TokenTransfered(from, to, amount);
        userTokens[from] -= amount;
        userTokens[to] += amount;
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
        emit TokenMinted(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
        emit TokenBurned(account, amount);
    }

    function _burnFrom(address account, uint256 amount) external {
        require(
            allowances[account][msg.sender] >= amount,
            "Insufficient allowance"
        );
        require(balances[account] >= amount, "Insufficient balance");

        balances[account] -= amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
        emit TokenBurned(account, amount);
    }
}
