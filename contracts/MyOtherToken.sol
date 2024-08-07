// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This doesn't necessarily follow the ERC20 standard.  Just
// learning how to write some solidity.
contract MyOtherToken {
    string public constant name = "MyOtherToken";
    string public constant symbol = "MOT";
    uint256 private constant decimals = 18;
    uint256 private max_supply = 1_000_000 * 10 ** decimals;

    mapping(address => uint256) private _balances;

    uint256 private _total_supply = 0;
    bool private _locked = false;
    address private immutable _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Must be owner");
        _;
    }

    modifier noReentry() {
        require(!_locked, "Re-entry is not allowed");
        _locked = true;
        _;
        _locked = false;
    }

    modifier verifyAddress(address a) {
        require(a != address(0), "Invalid address");
        _;
    }

    modifier verifyFunds(address a, uint256 amount) {
        require(_balances[a] >= amount, "Insufficent funds");
        _;
    }

    modifier verifyFoo(address from, address to, uint256 amount) {
        uint256 from_amount = _balances[from];
        uint256 to_amount = _balances[to];
        _;
        // THIS SEEMS TO BE A NO NO.  Examining state after the _; can result in the compiler getting "confused"
        require(from_amount - amount == _balances[from], "Transfer failed");
        require(to_amount - amount == _balances[to], "Transfer failed");
    }

    modifier verifyMinting(uint256 amount) {
        require(_total_supply + amount <= max_supply, "Minting exceeds maximum supply");
        _;
    }

    modifier verifyBurning(address from, uint256 amount) {
        require(_balances[from] >= amount, "Insuffient funds to burn");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(uint256 initial_supply) {
        _owner = msg.sender;
        _total_supply = initial_supply * 10 ** decimals;
    }

    // 0x78FD83768c7492aE537924c9658BE3D29D8ffFc1,0x742d35Cc6634C0532925a3b844Bc454e4438f44e,99
    function transfer(address a, address b, uint256 amount)
        external 
        verifyAddress(a)
        verifyFunds(a, amount)
        verifyAddress(b)
        // verifyFoo(a, b, amount)  // This modified is not liked.
        noReentry
        returns (bool)
    {
        _balances[a] -= amount;
        _balances[b] += amount;
        emit Transfer(a, b, amount);
        return true;
    }

    function mint(address to, uint256 amount) 
        external
        verifyAddress(msg.sender) 
        onlyOwner
        verifyAddress(to)
        verifyMinting(amount)
        noReentry
    {
        _total_supply += amount;
        _balances[to] += amount;
        emit Mint(to, amount);
    }

    function burn(address from, uint256 amount) 
        external
        verifyAddress(from)
        verifyBurning(from, amount)
        noReentry
    {
        max_supply -= amount;
        _total_supply -= amount;
        _balances[from] -= amount;
        emit Burn(from, amount);
    }

    function balance(address a)
        external view 
        verifyAddress(a)
        returns (uint256)
    {
        return _balances[a];
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        // withdraw the ether received in "receive"
        payable(_owner).transfer(address(this).balance);
    }
}