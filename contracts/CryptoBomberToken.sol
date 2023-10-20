// SPDX-License-Identifier: MIT
// https://cbomber.io
// CryptoBomberToken
pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
           _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract ERC20Burnable is Context, ERC20 {
  
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract CryptoBomberToken is ERC20, ERC20Burnable, Ownable {

    uint256 private total;

    mapping(address => uint256) timestamp; 
    mapping(address => uint256) distBalances;
    mapping(address => uint256) unlockNum;

    event Distribute(uint256 _amount, address _to, uint256 _unlockNum, uint256 _startTime, uint256 _time);

    mapping (address => bool) private distributeUser;
    
    constructor() ERC20("CryptoBomber Token", "CB"){
        total = 100000000 * (10 ** 18);
    }

    modifier onlyDistribute() {
        require(isDistribute(_msgSender()) || owner() == _msgSender(), "Role: caller does not have the distribute role or above");
        _;
    }

    function isDistribute(address account) public view returns (bool) {
        return distributeUser[account];
    }

    function addDistribute(address account) public onlyOwner{
        distributeUser[account] = true;
    }

    function removeDistribute(address account) public onlyOwner{
        distributeUser[account] = false;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(_totalSupply + amount <= total,"ERC20: Exceeding the maximum limit");
        _mint(to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20)
    {
        super._burn(account, amount);
    }

    function freeAmount(address user) internal view returns (uint256 amount) {
        uint monthDiff;
        uint unrestricted;

        if (user == owner()) {
            return _balances[user];
        }
        if (block.timestamp < timestamp[user]) {
            monthDiff = 0;
        }else{
            monthDiff = (block.timestamp - timestamp[user]) / (30 days);
		}
        if (monthDiff >= unlockNum[user]) {
            return _balances[user];
        }
        if (block.timestamp < timestamp[user]) {
            unrestricted = 0;
        }else{
            unrestricted = distBalances[user] / (unlockNum[user]) * (monthDiff);
        }
        if (unrestricted > distBalances[user]) {
            unrestricted = distBalances[user];
        }
        if (unrestricted + _balances[user] < distBalances[user]) {
            amount = 0;
        } else {
            amount = unrestricted + (_balances[user]) - (distBalances[user]);
        }
        return amount;
    }    

    function getFreeAmount(address user) public view returns (uint256 amount) {
        amount = freeAmount(user);
        return amount;
    }
 
    function getRestrictedAmount(address user) public view returns (uint256 amount) {
        amount = _balances[user] - freeAmount(user);
        return amount;
    }

    function distribute(uint256 _amount, address _to, uint256 _unlockNum, uint256 _startTime) public onlyDistribute {
        require(distBalances[_to] == 0,"Lock already exists for the address"); 
        require(_totalSupply + _amount <= total,"Exceeding the maximum limit");
 
        distBalances[_to] += _amount;
        unlockNum[_to] += _unlockNum;
        timestamp[_to] = _startTime > 0 ? _startTime : block.timestamp;
        _mint(_to, _amount);

        emit Distribute(_amount,_to,_unlockNum,_startTime,block.timestamp);
    }
    
    function transfer(address _to, uint256 _value) public override returns (bool){
        uint256 _freeAmount = freeAmount(_msgSender());
        require(_freeAmount >= _value,"error: Exceeding the unlocking limit");
        return super.transfer(_to, _value);
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
        uint _freeAmount = freeAmount(_from);
        require(_freeAmount >= _value,"error: Exceeding the unlocking limit");
        return super.transferFrom(_from, _to, _value);
    }
}
