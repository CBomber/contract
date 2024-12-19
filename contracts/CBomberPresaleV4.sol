// SPDX-License-Identifier: MIT
// https://cbomber.io
// CBomberPresale
pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721{
    function safeMint(address to) external;
}

 interface IUniswapV2Router01 {
     function factory() external pure returns (address);
     function WETH() external pure returns (address);
 
     function addLiquidity(
         address tokenA,
         address tokenB,
         uint amountADesired,
         uint amountBDesired,
         uint amountAMin,
         uint amountBMin,
         address to,
         uint deadline
     ) external returns (uint amountA, uint amountB, uint liquidity);
     function addLiquidityETH(
         address token,
         uint amountTokenDesired,
         uint amountTokenMin,
         uint amountETHMin,
         address to,
         uint deadline
     ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
     function removeLiquidity(
         address tokenA,
         address tokenB,
         uint liquidity,
         uint amountAMin,
         uint amountBMin,
         address to,
         uint deadline
     ) external returns (uint amountA, uint amountB);
     function removeLiquidityETH(
         address token,
         uint liquidity,
         uint amountTokenMin,
         uint amountETHMin,
         address to,
         uint deadline
     ) external returns (uint amountToken, uint amountETH);
     function removeLiquidityWithPermit(
         address tokenA,
         address tokenB,
         uint liquidity,
         uint amountAMin,
         uint amountBMin,
         address to,
         uint deadline,
         bool approveMax, uint8 v, bytes32 r, bytes32 s
     ) external returns (uint amountA, uint amountB);
     function removeLiquidityETHWithPermit(
         address token,
         uint liquidity,
         uint amountTokenMin,
         uint amountETHMin,
         address to,
         uint deadline,
         bool approveMax, uint8 v, bytes32 r, bytes32 s
     ) external returns (uint amountToken, uint amountETH);
     function swapExactTokensForTokens(
         uint amountIn,
         uint amountOutMin,
         address[] calldata path,
         address to,
         uint deadline
     ) external returns (uint[] memory amounts);
     function swapTokensForExactTokens(
         uint amountOut,
         uint amountInMax,
         address[] calldata path,
         address to,
         uint deadline
     ) external returns (uint[] memory amounts);
     function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
     external
     payable
     returns (uint[] memory amounts);
     function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
     external
     returns (uint[] memory amounts);
     function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
     external
     returns (uint[] memory amounts);
     function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
     external
     payable
     returns (uint[] memory amounts);
 
     function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
     function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
     function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
     function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
     function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
 }
 

 interface IUniswapV2Router02 is IUniswapV2Router01 {
     function removeLiquidityETHSupportingFeeOnTransferTokens(
         address token,
         uint liquidity,
         uint amountTokenMin,
         uint amountETHMin,
         address to,
         uint deadline
     ) external returns (uint amountETH);
     function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
         address token,
         uint liquidity,
         uint amountTokenMin,
         uint amountETHMin,
         address to,
         uint deadline,
         bool approveMax, uint8 v, bytes32 r, bytes32 s
     ) external returns (uint amountETH);
 
     function swapExactTokensForTokensSupportingFeeOnTransferTokens(
         uint amountIn,
         uint amountOutMin,
         address[] calldata path,
         address to,
         uint deadline
     ) external;
     function swapExactETHForTokensSupportingFeeOnTransferTokens(
         uint amountOutMin,
         address[] calldata path,
         address to,
         uint deadline
     ) external payable;
     function swapExactTokensForETHSupportingFeeOnTransferTokens(
         uint amountIn,
         uint amountOutMin,
         address[] calldata path,
         address to,
         uint deadline
     ) external;
 }

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CBomberPresale is Ownable{

    using SafeMath for uint256;
    using Address for address;

    uint256 public PRESALE_LIMIT = 210 ether;

    uint256 public total;
    uint256 public claimTotal;

    uint256 public FIRST_PRIZE = 14 ether;
    uint256 public SECOND_PRIZE = 2 ether;
    uint256 public THIRD_PRIZE = 1 ether;
    uint256 public LAST_PRIZE = 1 ether;
    uint256 public LUCKY_PRIZE = 1 ether;

    uint256 public LUCKY_INTERVAL = 10;
    
    address public firstPrizeAddress ;
    address public secondPrizeAddress;
    address public thirdPrizeAddress;
    address public lastPrizeAddress;

    address public tokenAddress;
    address public nftAddress;

    uint256 public CLAIM_TOKEN_TOTAL = 7000000000 ether;
    uint256 public LP_TOKEN_AMOUNT = 1500000000 ether;
    uint256 public LP_ETH_AMOUNT = 45 ether;

    uint256 public STOP_PRESALE_TIME;
    address public ABANDONMENT_ADDRESS = 0x0000000000000000000000000000000000000001;

    address[] internal buyAddresss;
    address[] internal luckyAddresss;

    struct User {
        uint256 balances;
        uint256 lastTime;
        bool claim;
        bool state;
    }

    mapping(address => User) internal _userList;

    uint256 public SINGLE_FEE = 0.01 ether;

    bool public CLAIM_STATE = false;

    address private DEV;
    /**
     * @dev base 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
     * Sepolia 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3
     */
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24);

    event Buy(uint256 _number,address _sender,uint256 time);
    event Claim(address _sender,uint256 _amount,uint256 time);
    event AddLiquidity(address _sender);

    constructor (address _dev,address _token,address _nft,uint256 _stopTime) {
        DEV = _dev;
        tokenAddress = _token;
        nftAddress = _nft;
        STOP_PRESALE_TIME = _stopTime;
    }

    function queryUser(address _sender) public view returns(User memory){
        return _userList[_sender];
    }

    function luckyAddressCount() public view returns(uint256){
        return luckyAddresss.length;
    }

    function buyAddressCount() public view returns(uint256){
        return buyAddresss.length;
    }

    function getPageLuckyDesc(uint256 _index ,uint256 _size) public view returns(address[] memory indexArray){
        uint256 _length = _index > _size ? _size : _index;
        indexArray = new address[](_length);
        for(uint256 i = 1; i <= _length; i++){
            indexArray[i.sub(1)] = luckyAddresss[_index.sub(i)];
        }
    }

    function getPageBuyDesc(uint256 _index ,uint256 _size) public view returns(address[] memory indexArray){
        uint256 _length = _index > _size ? _size : _index;
        indexArray = new address[](_length);
        for(uint256 i = 1; i <= _length; i++){
            indexArray[i.sub(1)] = buyAddresss[_index.sub(i)];
        }
    }

    function _buy() internal {

        buyAddresss.push(_msgSender());

        if(buyAddresss.length % LUCKY_INTERVAL == 0){
            
            luckyAddresss.push(_msgSender());
            IERC721(nftAddress).safeMint(_msgSender());

        }

        if(buyAddresss.length % (PRESALE_LIMIT.div(SINGLE_FEE).div(4)) == 0 && buyAddresss.length != (PRESALE_LIMIT.div(SINGLE_FEE))){

            (bool s, ) = _msgSender().call{value: LUCKY_PRIZE}(""); require(s);

        }

        total = total.add(SINGLE_FEE);

        if(total == PRESALE_LIMIT){

            uint256 firstPrizeIndex = random(buyAddresss.length,block.number.sub(1));
            firstPrizeAddress = buyAddresss[firstPrizeIndex];

            uint256 secondPrizeIndex = random(buyAddresss.length,block.number.sub(2));
            secondPrizeAddress = buyAddresss[secondPrizeIndex];

            uint256 thirdPrizeIndex = random(buyAddresss.length,block.number.sub(3));
            thirdPrizeAddress = buyAddresss[thirdPrizeIndex];

            (bool first, ) = firstPrizeAddress.call{value: FIRST_PRIZE}(""); require(first);
            (bool second, ) = secondPrizeAddress.call{value: SECOND_PRIZE}(""); require(second);
            (bool third, ) = thirdPrizeAddress.call{value: THIRD_PRIZE}(""); require(third);

            lastPrizeAddress = _msgSender();
            (bool last, ) = _msgSender().call{value: LAST_PRIZE }(""); require(last);

            _addLPToken();

            (bool dev, ) = DEV.call{value: address(this).balance }(""); require(dev);

        }

    }

    function buy(uint256 _number) public payable {

        require(!_msgSender().isContract(),'error: Requestor is the contractual address');

        require(!CLAIM_STATE,"error: Claim has been turned on, stop buying.");

        require(block.timestamp < STOP_PRESALE_TIME,"error: presale stopped.");

        require(_msgValue() >= SINGLE_FEE.mul(_number) && _number > 0,"error: Insufficient gas value");

        require(total.add(SINGLE_FEE.mul(_number)) <= PRESALE_LIMIT ,"error: exceeds the hardtop limit.");

        if(_msgValue() > SINGLE_FEE.mul(_number)){
            (bool s, ) = _msgSender().call{value: _msgValue().sub(SINGLE_FEE.mul(_number))}(""); require(s);
        }

        for(uint256 index = 1 ;index <= _number ; index++){
            _buy();
        }

        if(_userList[_msgSender()].state){

            _userList[_msgSender()].balances = _userList[_msgSender()].balances.add(SINGLE_FEE.mul(_number));
            _userList[_msgSender()].lastTime = block.timestamp;

        }else{
            _userList[_msgSender()] = User({
                balances : SINGLE_FEE.mul(_number),
                lastTime : block.timestamp,
                claim : false,
                state : true
            });
        }

        emit Buy(_number,_msgSender(),block.timestamp);
        
    }

    function claim() public {

        require(CLAIM_STATE, "error: unopened");
        require(_userList[_msgSender()].claim == false,"error: The address has been claimed.");
        require(_userList[_msgSender()].balances > 0  ,"error: This address is not eligible for claim.");

        uint256 tokenAmount = _getTokenAmount(_msgSender());
        
        IERC20(tokenAddress).transfer(_msgSender(), tokenAmount);

        _userList[_msgSender()].claim = true;

        claimTotal = claimTotal.add(tokenAmount);

        emit Claim(_msgSender(),tokenAmount,block.timestamp);

    }

    function _getTokenAmount(address _user) internal view returns(uint256){
        uint256 tokenAmount = _userList[_user].state ? _userList[_user].balances.mul(CLAIM_TOKEN_TOTAL).div(PRESALE_LIMIT) : 0;
        return tokenAmount;
    }

    function getTokenAmount(address _user) public view returns(uint256){
        return _getTokenAmount(_user);
    }

    function _addLPToken() internal{

        _addLiquidity(LP_TOKEN_AMOUNT,LP_ETH_AMOUNT);

        CLAIM_STATE = true;

        emit AddLiquidity(_msgSender());
    }
   
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {

        IERC20(tokenAddress).approve(address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.addLiquidityETH{value : ethAmount}(
            tokenAddress, tokenAmount, 0, 0, DEV, block.timestamp.add(600)
        );
    }

    function presaleSettlement() public onlyOwner {

        require(!CLAIM_STATE,"error: claim opened.");

        require(block.timestamp > STOP_PRESALE_TIME,"error: No stopping time.");

        uint256 firstPrizeIndex = random(buyAddresss.length,block.number.sub(1));
        firstPrizeAddress = buyAddresss[firstPrizeIndex];

        uint256 secondPrizeIndex = random(buyAddresss.length,block.number.sub(2));
        secondPrizeAddress = buyAddresss[secondPrizeIndex];

        uint256 thirdPrizeIndex = random(buyAddresss.length,block.number.sub(3));
        thirdPrizeAddress = buyAddresss[thirdPrizeIndex];

        (bool first, ) = firstPrizeAddress.call{value: total.mul(FIRST_PRIZE).div(PRESALE_LIMIT)}(""); require(first);
        (bool second, ) = secondPrizeAddress.call{value: total.mul(SECOND_PRIZE).div(PRESALE_LIMIT)}(""); require(second);
        (bool third, ) = thirdPrizeAddress.call{value: total.mul(THIRD_PRIZE).div(PRESALE_LIMIT)}(""); require(third);

        uint256 newLPTokenAmount = total.mul(LP_TOKEN_AMOUNT).div(PRESALE_LIMIT);
        uint256 newLPETHAmount = total.mul(LP_ETH_AMOUNT).div(PRESALE_LIMIT);

        _addLiquidity(newLPTokenAmount,newLPETHAmount);

        uint256 lpTokenRemainingAmount = LP_TOKEN_AMOUNT.sub(newLPTokenAmount);
        uint256 claimTokenRemainingAmount = CLAIM_TOKEN_TOTAL.sub((total.mul(CLAIM_TOKEN_TOTAL).div(PRESALE_LIMIT)));
        uint256 abandonmentAmount = lpTokenRemainingAmount.add(claimTokenRemainingAmount);
        IERC20(tokenAddress).transfer(ABANDONMENT_ADDRESS, abandonmentAmount);
        
        CLAIM_STATE = true;

        (bool dev, ) = DEV.call{value: address(this).balance }(""); require(dev);

        emit AddLiquidity(_msgSender());

    }

    function random(uint number,uint seed) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,
        block.number,
        block.gaslimit,
        seed,
        _msgSender()))) % number;
    }
}
