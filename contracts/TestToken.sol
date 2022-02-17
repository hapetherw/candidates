// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Token is ERC20, Ownable {
    using SafeERC20 for ERC20;
    uint public immutable feePercentage;
    uint public immutable burnPercentage;
    address public immutable fundAddress;
    mapping(address => bool) public blackLists;

    constructor(
        string memory _name,
        string memory _symbol,
        uint _feePercentage,
        uint _burnPercentage,
        address _fundAddress
    ) ERC20(_name, _symbol) {
        feePercentage = _feePercentage;
        burnPercentage = _burnPercentage;
        fundAddress = _fundAddress;
    }
    
    modifier checkBlackList() {
        require(!blackLists[msg.sender], "You are a blackList address");
        _;
    }
    
    function addBlackList(address blackAddress) public onlyOwner {
        blackLists[blackAddress] = true;
    }

    function removeBlackList(address blackAddress) public onlyOwner {
        blackLists[blackAddress] = false;
    }
    
    function transfer(address recipient, uint256 amount) public checkBlackList virtual override returns (bool) {
        uint feeAmount = amount * feePercentage / 100;
        uint burnAmount = feeAmount * burnPercentage / 100;
        _transfer(_msgSender(), recipient, amount - feeAmount);
        _transfer(_msgSender(), fundAddress, feeAmount - burnAmount);
        _burn(_msgSender(), burnAmount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public checkBlackList virtual override returns (bool) {
        uint feeAmount = amount * feePercentage / 100;
        uint burnAmount = feeAmount * burnPercentage / 100;

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        
        _transfer(sender, recipient, amount - feeAmount);
        _transfer(sender, fundAddress, feeAmount - burnAmount);
        _burn(sender, burnAmount);

        return true;
    }
}