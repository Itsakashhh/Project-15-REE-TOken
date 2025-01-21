// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract REEToken is IERC20 {
    // Token details
    string public name = "REE Token";
    string public symbol = "REE";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    bool public paused;

    // Balances and allowances
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Blacklist mapping
    mapping(address => bool) public isBlacklisted;

    // Custom errors
    error AddressZero();
    error InsufficientBalance();
    error AllowanceExceeded();
    error ContractPaused();
    error AddressBlacklisted();
    error Unauthorized();

    // Events
    event Paused(address account);
    event Unpaused(address account);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Blacklisted(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    modifier notBlacklisted(address account) {
        if (isBlacklisted[account]) revert AddressBlacklisted();
        _;
    }

    // Constructor
    constructor(uint256) {
        owner = msg.sender;
        totalSupply = 100000000 * (10 ** decimals);
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    // IERC20 functions
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public override whenNotPaused notBlacklisted(msg.sender) notBlacklisted(to) returns (bool) {
        if (to == address(0)) revert AddressZero();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        if (spender == address(0)) revert AddressZero();

        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override
        whenNotPaused
        notBlacklisted(from)
        notBlacklisted(to)
        notBlacklisted(msg.sender)
        returns (bool)
    {
        if (to == address(0)) revert AddressZero();
        if (balances[from] < amount) revert InsufficientBalance();
        if (allowances[from][msg.sender] < amount) revert AllowanceExceeded();

        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    // Pausable functionality
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner {
        if (!paused) revert ContractPaused();
        paused = false;
        emit Unpaused(msg.sender);
    }

    // Mintable functionality
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        if (to == address(0)) revert AddressZero();

        totalSupply += amount;
        balances[to] += amount;
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    // Burnable functionality
    function burn(uint256 amount) public whenNotPaused notBlacklisted(msg.sender) {
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    // Blacklist functionality
    function blacklist(address account) public onlyOwner {
        if (isBlacklisted[account]) revert AddressBlacklisted();

        isBlacklisted[account] = true;
        emit Blacklisted(account);
    }

    function removeFromBlacklist(address account) public onlyOwner {
        if (!isBlacklisted[account]) revert AddressBlacklisted();

        isBlacklisted[account] = false;
        emit RemovedFromBlacklist(account);
    }
}
