// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyOtherToken {
    string public constant token_name = "MyOtherToken";
    string public constant token_symbol = "MOT";
    uint8 public constant decimals = 18;
    uint256 private constant multipler = 10**uint256(decimals);
    uint256 public constant max_supply = 1_000_000 * multipler; // 1 million tokens

    address private immutable owner;
    uint256 private total_supply = 0;
    mapping(address => uint256) private balances;
    bool private locked = false;

    modifier only_owner() {
        require(msg.sender == owner, "Only owner can access this action.");
        _;
    }

    modifier valid_address(address a) {
        require(a != address(0), "Must specify a valid address.");
        _;
    }

    modifier no_rentry() {
        require(!locked, "Rentrant calls are not allowed.");
        locked = true;
        _;
        locked = false;
    }

    modifier sufficient_mint(uint256 amount) {
        require(total_supply + amount <= max_supply, "Insufficient max supply");
        _;
    }

    modifier sufficient_burn(uint256 amount) {
        require(amount <= total_supply, "Insufficient total supply");
        _;
    }

    modifier sufficient_funds(address a, uint256 amount) {
        require(balances[a] >= amount, "Insufficient funds to burn");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(uint256 initial_supply) {
        require(initial_supply * multipler <= max_supply, "initial_supply can not exceed maximum.");
        owner = msg.sender;
        total_supply = initial_supply;
        balances[owner] = total_supply;
    }

    function transfer(address to, uint256 amount) 
        external 
        valid_address(msg.sender)
        valid_address(to)
        sufficient_funds(msg.sender, amount) 
        no_rentry
    {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function mint(address to, uint256 amount) 
        external 
        only_owner
        valid_address(to)
        sufficient_mint(amount) 
        no_rentry
    {
        balances[to] += amount;
        total_supply += amount;
        emit Mint(to, amount);
    }

    function burn(address from, uint256 amount)
        external
        only_owner
        valid_address(from)
        sufficient_funds(from, amount)
        sufficient_burn(amount)
        no_rentry
    {
        balances[from] -= amount;
        total_supply -= amount;
        // Should this also burn from the maximum?
        emit Burn(from, amount);
    }

    function balance(address a) 
        external view 
        valid_address(a)
        returns (uint256)
    {
        return balances[a];
    }

    receive() external payable {}

    function withdraw() external only_owner {
        // withdraw the ether received in "receive"
        payable(owner).transfer(address(this).balance);
    }
}