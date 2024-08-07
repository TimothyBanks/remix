// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract BSideToken is ERC20 {
    uint256 private _maxSupply = 1_000_000 * 10**18;

    modifier sufficientMint(uint256 amount) {
        require(_totalSupply + amount <= _maxSupply, "Insufficient max supply");
        _;
    }

    modifier verifyMint(address to, uint256 amount) {
        uint256 _total = _totalSupply;
        uint256 _user = _balances[to];
        _;
        require(_total + amount == _totalSupply, "Mint failed");
        require(_user + amount == _balances[to], "Mint failed");
    }

    modifier sufficientBurn(uint256 amount) {
        require(amount <= _totalSupply, "Insufficient total supply");
        require(amount <= _balances[msg.sender], "Insufficient balance");
        _;
    }

    modifier verifyBurn(uint256 amount) {
        uint256 _max = _maxSupply;
        uint256 _total = _totalSupply;
        uint256 _user = _balances[msg.sender];
        _;
        require(_max - amount == _maxSupply, "Burn was not successful.");
        require(_total - amount == _totalSupply, "Burn was not successful.");
        require(_user - amount == _balances[msg.sender], "Burn was not successful.");
    }

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(uint256 initialSupply)
        ERC20("BSideToken", "BSIDE", 18, initialSupply)
    {}

    function burn(uint256 amount)
        external
        verifyAddress(msg.sender)
        sufficientBurn(amount)
        verifyBurn(amount)
        noReentry
    {
        _maxSupply -= amount;
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
    }

    function mint(address to, uint256 amount) 
        external 
        onlyOwner
        sufficientMint(amount)
        verifyMint(to, amount)
        noReentry
    {
        _totalSupply += amount;
        _balances[to] += amount;
        emit Mint(to, amount);
    }
}
