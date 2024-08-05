// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BSideToken {
    // token details
    string public constant name = "BSideToken";
    string public constant symbol = "BST";
    uint8 public constant decimals = 18;
    uint256 public constant max_supply = 1_000_000 * 10**uint256(decimals); // 1 million tokens

    // Owner address, immutable after deployment
    // What does it mean to be a public variable?
    address public immutable owner;

    uint256 public total_supply = 0;

    mapping(address => uint256) public balance_of;

    bool private locked = false;

    // Events
    // What is the keywork "indexed"?
    //  Allows the evm to create an index/filter on the parameter
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(uint256 initial_supply) {
        require(
            initial_supply * 10**uint256(decimals) <= max_supply,
            "Initial supply can not exceed maximum supply"
        );
        owner = msg.sender; // Where is msg defined?
        mint_(owner, initial_supply * 10**uint256(decimals));
    }

    // Modifiers

    // Modifer to restrict to owner
    modifier only_owner() {
        require(msg.sender == owner, "Restricted to owner account");
        _;
    }

    modifier valid_address(address a) {
        require(a != address(0), "Can not use null address");
        _;
    }

    modifier no_reentry() {
        // For finer grained control, we can use an array
        // and pass a parameter into the modifier
        locked = true;
        _;
        locked = false;
    }

    function mint_(address to_, uint256 amount_) internal {
        require(
            total_supply + amount_ <= max_supply,
            "Minting exceeds maximum."
        );
        total_supply += amount_;
        balance_of[to_] += amount_;
        emit Mint(to_, amount_);
        emit Transfer(address(0), to_, amount_);
    }

    function mint(address to_, uint256 amount_)
        external
        only_owner
        valid_address(to_)
    {
        mint_(to_, amount_);
    }

    function burn_(address from_, uint256 amount_) internal {
        // What does it mean when intellisense states "infinite gas" on action.
        require(balance_of[from_] >= amount_, "Insuffient funds");
        total_supply -= amount_;
        balance_of[from_] -= amount_;
        emit Burn(from_, amount_);
        emit Transfer(from_, address(0), amount_); // Is address(0) special?
    }

    // "infitite gas" could mean a few things:
    // 1. Infinite loops
    // 2. Infinite re-entry
    // 3. Unbounded operations
    function burn(uint256 amount_) external valid_address(msg.sender) {
        burn_(msg.sender, amount_);
    }

    function transfer(address to_, uint256 amount_)
        external
        no_reentry
        valid_address(msg.sender)
        valid_address(to_)
        returns (bool)
    {
        require(to_ != address(0), "Invalid address");
        require(balance_of[msg.sender] >= amount_, "Insufficient funds");

        balance_of[msg.sender] -= amount_;
        balance_of[to_] += amount_;

        emit Transfer(msg.sender, to_, amount_);
        return true;
    }

    function get_balance(address account_) external view returns (uint256) {
        return balance_of[account_];
    }

    receive() external payable {}

    function withdraw_ether() external only_owner {
        // Look up payable and address type
        payable(owner).transfer(address(this).balance);
    }
}
