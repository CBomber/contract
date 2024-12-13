// SPDX-License-Identifier: MIT
// https://cbomber.io
// CBomberShop
pragma solidity 0.8.20;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address account, uint256 id, uint256 value) external ;
}

contract CBomberShop is Ownable{

    using SafeMath for uint256;

    address public devFundAddress;
    address public paymentToken;

    struct product{
        uint256 tokenId;
        address nftAddress;
        uint256 total;
        uint256 sold;
        uint256 price;
        bool isToken;
        bool state;
    }

    mapping (uint256 => product) private productList;

    uint256 private _nextProductId = 0;

    event SetDevFundAddress(address newAddress);
    
    event AddProduct(uint256 _id,uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken);
    event UpdateProduct(uint256 _id,uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken);
    event SetPaymentTokenAddress(address _address);
    event Buy(address _account,address _nft,uint256 _tokenID);
    event SetProductState(uint256 _id,bool _state);

    constructor (address _token,address _devFundAddress) {
        paymentToken = _token;
        devFundAddress = _devFundAddress;
    }

    function getNextProductId() public view returns (uint256) {
        return _getNextProductId();
    }

    function _getNextProductId() private view returns (uint256) {
        return _nextProductId.add(1);
    }

    function _incrementProductId() internal {
        _nextProductId ++;
    }

    function setDevFundAddress(address _address) public onlyOwner{
        devFundAddress = _address;
        emit SetDevFundAddress(_address);
    }

    function setTokenAddress(address _address) public onlyOwner{
        paymentToken = _address;
        emit SetPaymentTokenAddress(_address);
    }

    function setProductState(uint256 _id,bool _state) public onlyOwner{
        productList[_id].state = _state;
        emit SetProductState(_id,_state);
    }

    function _addProduct(uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken) internal {

        uint256 _id = _getNextProductId();
        productList[_id] = product(_tokenId,_nftAddress,_total,0,_price,_isToken,true);

        _incrementProductId();
        emit AddProduct(_id,_tokenId,_nftAddress,_total,_price,_isToken);
    }

    function addProduct(uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken) public onlyOwner{

        _addProduct( _tokenId, _nftAddress, _total, _price, _isToken);

    }

    function ButchAddProduct(uint256[] memory _tokenIds,address[] memory _nftAddresss,uint256[] memory _totals,uint256[] memory _prices,bool[] memory _isTokens) public onlyOwner{
        require(_tokenIds.length == _nftAddresss.length && _tokenIds.length == _totals.length && _tokenIds.length == _prices.length && _tokenIds.length == _isTokens.length, "ERC1155: ids and amounts length mismatch");
        for(uint256 index = 0 ; index < _tokenIds.length ; index++){
            _addProduct( _tokenIds[index], _nftAddresss[index], _totals[index], _prices[index], _isTokens[index]);
        }
    }

    function updateProduct(uint256 _id,uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken) public onlyOwner{

        productList[_id].tokenId = _tokenId;
        productList[_id].nftAddress = _nftAddress;
        productList[_id].total = _total;
        productList[_id].price = _price;
        productList[_id].isToken = _isToken;

        emit UpdateProduct( _id, _tokenId, _nftAddress, _total, _price,_isToken);

    }

    function query(uint256 _id) public view returns(product memory){
        return productList[_id];
    }

    function queryList(uint256[] memory _ids) public view returns(product[] memory tmpProductList){
        tmpProductList = new product[](_ids.length);
        for(uint index = 0 ; index < _ids.length ; index++){
            tmpProductList[index] = productList[_ids[index]];
        }
        return tmpProductList;
    }

    function buy(uint256 _id) public payable{

        require(productList[_id].state,"error: Product unavailable.");

        require(productList[_id].sold < productList[_id].total , "error: Insufficient quantities available for sale.");

        if(productList[_id].isToken){

            require(IERC20(paymentToken).balanceOf(_msgSender()) >= productList[_id].price,"error: Insufficient token balance");

            IERC20(paymentToken).transferFrom(_msgSender(), devFundAddress, productList[_id].price);
            
        }else{
            require(_msgValue() >= productList[_id].price,"error: Insufficient payment eth");
            
            (bool s, ) = devFundAddress.call{value: _msgValue()}("");require(s);
        }
        productList[_id].sold = productList[_id].sold.add(1);

        IERC1155(productList[_id].nftAddress).mint(_msgSender(),productList[_id].tokenId,1,'0x0');

        emit Buy(_msgSender(),productList[_id].nftAddress,productList[_id].tokenId);
    }

}