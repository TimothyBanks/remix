// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal _totalSupply;
    bool private _locked;
    address private immutable _owner;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can access this action.");
        _;
    }

    modifier verifyAddress(address a) {
        require(a != address(0), "Must specify a valid address.");
        _;
    }

    modifier noReentry() {
        require(!_locked, "Rentrant calls are not allowed.");
        _locked = true;
        _;
        _locked = false;
    }

    modifier sufficientFunds(address a, uint256 amount) {
        require(_balances[a] >= amount, "Insufficient funds to burn");
        _;
    }

    modifier verifyTransfer(address sender, address recipient, uint256 amount) {
        uint256 sender_amount = _balances[sender];
        uint256 recipient_amount = _balances[recipient];
        _;
        require(sender_amount - amount == _balances[sender], "Sender funds not adjusted correctly");
        require(recipient_amount + amount == _balances[recipient], "Recipient funds not adjusted correctly");
    }

    modifier verifyAllowance(address owner, address spender, uint256 amount) {
        _;
        require(_allowances[owner][spender] == amount, "Recipient allowanace not adjusted correctly.");
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply
    ) {
        _owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = initialSupply * 10**uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        override
        verifyAddress(account)
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        verifyAddress(owner)
        verifyAddress(spender)
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        verifyAddress(sender)
        sufficientFunds(sender, amount)
        verifyAddress(recipient)
        verifyTransfer(sender, recipient, amount)
        noReentry
    {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        internal
        verifyAddress(owner)
        sufficientFunds(owner, amount)
        verifyAddress(spender)
        verifyAllowance(owner, spender, amount)
        noReentry
    {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }    
    
    receive() external payable {}

    function withdraw() external onlyOwner {
        // withdraw the ether received in "receive"
        payable(_owner).transfer(address(this).balance);
    }
}
