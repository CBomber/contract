// SPDX-License-Identifier: MIT
// https://cbomber.io
// CryptoBomberMarket
pragma solidity ^0.8.8;

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
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface  IPoolAdmin {
    function sendGas(uint256 value) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC1155Holder is ERC165, IERC1155Receiver {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract CryptoBomberMarket is Ownable,ERC1155Holder{

    using SafeMath for uint256;

    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant DEV_FUND_PERCENT = 20;
    uint256 public constant POOL_FUND_PERCENT = 20;
    bool private defiPoolOnState = false;
    bool private isFundsFlowToPool = false;

    address private paymentToken;
    address private devFundAddress;
    address private hostingPool;
    address private poolAdmin;

    struct Total{
        uint256 token;
        uint256 eth;
    }
    mapping(address => bool) private nftContractList;
    mapping(address => mapping(uint256 => uint256)) balances;
    mapping(address => Total) salesAmountList;
    mapping(address => uint256[]) accountSalesList;
    mapping(address => uint256[]) accountSoldsList;
    mapping (uint256 => Order) private NFTSalesOrder;

    uint256[] private salesList;
    uint256[] private soldsList;

    uint256 private _indexToAssign = 0;

    struct Order {
        uint256 id;
        bool isForSale;
        address nftAddress;
        uint256 tokenID;
        uint number;
        address seller;
        bool isToken;
        uint256 minPrice;
        address onlySellTo;
    }

    event SellNFT(uint256 _id,address _nftAddress,uint256 _tokenid,uint _number, uint256 _minSalePriceInWei,bool _isToken,address _onlySellTo,uint256 time);
    event CancelSalesOrder(uint256 _index,address seller,uint256 time);
    event BuyNFT(uint256 _index,address account,uint256 time);
    event Withdraw(address account,uint256 ethValue,uint256 tokenValue,uint256 time);

    constructor (address _token,address _devFundAddress,address _hostingPool,address _poolAdmin) {
        paymentToken = _token;
        devFundAddress = _devFundAddress;
        hostingPool = _hostingPool;
        poolAdmin = _poolAdmin;
    }

    function getNextIndexToAssign() public view returns (uint256) {
        return _indexToAssign.add(1);
    }

    function _getNextIndexToAssign() private view returns (uint256) {
        return _indexToAssign.add(1);
    }

    function _incrementIndexToAssign() internal {
        _indexToAssign ++;
    }

    function addNFTContract(address _nftAddress) public onlyOwner {
        nftContractList[_nftAddress] = true;
    }

    function removeNFTContract(address _nftAddress) public onlyOwner{
        nftContractList[_nftAddress] = false;
    }

    function setDevFundAddress(address _address) public onlyOwner{
        devFundAddress = _address;
    }

    function getDevFundAddress() public view returns(address){
        return devFundAddress;
    }

    function setHostingPool(address _address) public onlyOwner{
        hostingPool = _address;
    }

    function getHostingPool() public view returns(address){
        return hostingPool;
    }

    function getDefiPoolOnState() public view returns(bool){
        return defiPoolOnState;
    }

    function setDefiPoolOnState(bool _value) public onlyOwner{
        defiPoolOnState = _value;
    }

    function setPoolAdmin(address _address) public onlyOwner{
        poolAdmin = _address;
    }

    function getPoolAdmin() public view returns(address){
        return poolAdmin;
    }

    function setIsFundsFlowToPoolState(bool _value) public onlyOwner(){
        isFundsFlowToPool = _value;
    }

    function getIsFundsFlowToPoolState() public view returns(bool){
        return isFundsFlowToPool;
    }

    function sellNFT(address _nftAddress,uint256 _tokenid,uint _number, uint256 _minSalePriceInWei,bool _isToken,address _onlySellTo) public {

        //it's not public.
        
    }
   
    function cancelSalesOrder(uint256 _index) public {
        //it's not public.
    }

    function deleteElement(uint256[] storage dataArray,uint256 index) internal {
        require(index < dataArray.length, "Invalid index");
        dataArray[index] = dataArray[dataArray.length - 1];
        dataArray.pop();
    }

    function buyNFT(uint256 _index) public payable {

        //it's not public.
        
    }

    function withdraw() public{
        Total storage _total = salesAmountList[_msgSender()];

        if(_total.eth > 0){
            require(address(this).balance >= _total.eth ,"error: eth Insufficient balance");
            (bool s, ) = _msgSender().call{value: _total.eth}("");require(s);
            _total.eth = 0;
        }
        if(_total.token > 0){
            require(IERC20(paymentToken).balanceOf(address(this)) >= _total.token,"error: token Insufficient balance");
            IERC20(paymentToken).transfer(_msgSender(), _total.token);
            _total.token = 0;
        }

        emit Withdraw(_msgSender(),_total.eth,_total.token,block.timestamp);
    }

    function getUserSalesAmount(address _account) public view returns(Total memory){
        return salesAmountList[_account];
    }

    function getAccountSalesIndex(address _account) public view returns(uint256[] memory){
        return accountSalesList[_account];
    }

    function getAccountSales(address _account) public view returns(Order[] memory orders){
        orders = new Order[](accountSalesList[_account].length);
        for(uint i = 0; i< accountSalesList[_account].length ; i++){
            orders[i] = _queryOrder(accountSalesList[_account][i]);
        }
    }

    function getAccountSoldsIndex(address _account) public view returns(uint256[] memory){
        return accountSoldsList[_account];
    }

    function getAccountSolds(address _account) public view returns(Order[] memory orders){
        orders = new Order[](accountSoldsList[_account].length);
        for(uint i = 0; i< accountSoldsList[_account].length ; i++){
            orders[i] = _queryOrder(accountSoldsList[_account][i]);
        }
    }
    
    function balanceOf(address _nft,uint256 _tokenid) public view returns(uint256){
        return balances[_nft][_tokenid];
    }

    function _queryOrder(uint256 _orderId) internal view returns(Order memory){
        return NFTSalesOrder[_orderId];
    }

    function queryOrder(uint256 _orderId) public view returns(Order memory){
        return _queryOrder(_orderId);
    }

    function getSalesListCount() public view returns(uint256){
        return salesList.length;
    }

    function getSoldsListCount() public view returns(uint256){
        return soldsList.length;
    }

    function getSalesListIndexOrder(uint256 _index) public view returns(Order memory){
        return _queryOrder(salesList[_index]);
    }

    function getSoldsListIndexOrder(uint256 _index) public view returns(Order memory){
        return _queryOrder(soldsList[_index]);
    }

    function getPageSalesOrderAsc(uint256 _size,uint256 _index) public view returns(Order[] memory orders){
        uint256 _length = _index.add(_size) <= getSalesListCount() ? _size : getSalesListCount().sub(_index).add(1);
        orders = new Order[](_length);
        for(uint256 i = 0; i < _length; i++){
            orders[i] = NFTSalesOrder[salesList[i.add(_index.sub(1))]];
        }
    }

    function getPageSoldsOrderAsc(uint256 _size,uint256 _index) public view returns(Order[] memory orders){
        uint256 _length = _index.add(_size) <= getSoldsListCount() ? _size : getSoldsListCount().sub(_index).add(1);
        orders = new Order[](_length);
        for(uint256 i = 0; i < _length; i++){
            orders[i] = NFTSalesOrder[soldsList[i.add(_index.sub(1))]];
        }
    }
    
    function getPageSalesOrderDesc(uint256 _size,uint256 _index) public view returns(Order[] memory indexArray){
        uint256 _length = _index > _size ? _size : _index;
        indexArray = new Order[](_length);
        for(uint256 i = 1; i <= _length; i++){
            indexArray[i.sub(1)] = NFTSalesOrder[salesList[_index.sub(i)]];
        }
    }

    function getPageSoldsOrderDesc(uint256 _size,uint256 _index) public view returns(Order[] memory indexArray){
        uint256 _length = _index > _size ? _size : _index;
        indexArray = new Order[](_length);
        for(uint256 i = 1; i <= _length; i++){
            indexArray[i.sub(1)] = NFTSalesOrder[soldsList[_index.sub(i)]];
        }
    }

}
