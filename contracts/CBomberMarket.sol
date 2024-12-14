// SPDX-License-Identifier: MIT
// https://cbomber.io
// CBomberMarket
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

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
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

interface IERC721Receiver {
 
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC721Holder is IERC721Receiver {
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract CBomberMarket is Ownable,ERC1155Holder,ERC721Holder{

    using SafeMath for uint256;

    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant DEV_FUND_PERCENT = 50;

    address public paymentToken;
    address public devFundAddress;

    struct NFTInfo{
        bool isERC1155;
        bool state;
    }

    mapping(address => NFTInfo) private nftContractList;
    mapping(address => mapping(uint256 => uint256)) balances;
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
    event AddNFTContract(address _nft,bool _isERC1155);
    event RemoveNFTContract(address _nft);
    event SetDevFundAddress(address _account);
    event SellNFT(uint256 _id,address _nftAddress,uint256 _tokenid,uint _number, uint256 _minSalePriceInWei,bool _isToken,address _onlySellTo,uint256 time);
    event CancelSalesOrder(uint256 _index,address seller,uint256 time);
    event BuyNFT(uint256 _index,address account,uint256 time);
    event Withdraw(address account,uint256 ethValue,uint256 tokenValue,uint256 time);

    constructor (address _token,address _devFundAddress) {
        paymentToken = _token;
        devFundAddress = _devFundAddress;
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

    function addNFTContract(address _nftAddress,bool _isERC1155) public onlyOwner {
        nftContractList[_nftAddress].isERC1155 = _isERC1155;
        nftContractList[_nftAddress].state = true;
        emit AddNFTContract(_nftAddress,_isERC1155);
    }

    function removeNFTContract(address _nftAddress) public onlyOwner{
        nftContractList[_nftAddress].state = false;
        emit RemoveNFTContract(_nftAddress);
    }

    function setDevFundAddress(address _address) public onlyOwner{
        devFundAddress = _address;
        emit SetDevFundAddress(_address);
    }
    
    function sellNFT(address _nftAddress,uint256 _tokenid,uint _number, uint256 _minSalePriceInWei,bool _isToken,address _onlySellTo) public {

        require(nftContractList[_nftAddress].state == true,"error: Unsupported nft addresses");

        uint256 _index = _getNextIndexToAssign();

        if(nftContractList[_nftAddress].isERC1155){

            IERC1155 _1155NFT = IERC1155(_nftAddress);

            require(_1155NFT.balanceOf(_msgSender(),_tokenid) >= _number,"error: Wallet nft low balance");
            require(_1155NFT.isApprovedForAll(_msgSender(),address(this)),"error: nft not approved");

            NFTSalesOrder[_index] = Order(_index,true,_nftAddress,_tokenid,_number,_msgSender(),_isToken,_minSalePriceInWei,_onlySellTo);

            emit SellNFT(_index,_nftAddress,_tokenid,_number,_minSalePriceInWei,_isToken,_onlySellTo,block.timestamp);

            _incrementIndexToAssign();
            _1155NFT.safeTransferFrom(_msgSender(), address(this), _tokenid, _number, "0x0");
            balances[_nftAddress][_tokenid] = balances[_nftAddress][_tokenid].add(_number);

        }else{

            IERC721 _721NFT = IERC721(_nftAddress);

            require(_721NFT.ownerOf(_tokenid) == _msgSender() ,"error: The tokenid does not belong to this address.");
            require(_721NFT.isApprovedForAll(_msgSender(),address(this)),"error: nft not approved");

            NFTSalesOrder[_index] = Order(_index,true,_nftAddress,_tokenid,1,_msgSender(),_isToken,_minSalePriceInWei,_onlySellTo);

            emit SellNFT(_index,_nftAddress,_tokenid,1,_minSalePriceInWei,_isToken,_onlySellTo,block.timestamp);

            _incrementIndexToAssign();

            _721NFT.safeTransferFrom(_msgSender(), address(this), _tokenid, "0x0");
            balances[_nftAddress][_tokenid] = balances[_nftAddress][_tokenid].add(1);

        }

        accountSalesList[_msgSender()].push(_index);
        salesList.push(_index);


    }
   
    function cancelSalesOrder(uint256 _index) public {

        require(NFTSalesOrder[_index].isForSale == true,"error: The state of nft is false");
        require(NFTSalesOrder[_index].seller == _msgSender(),"error: nft does not belong to the requester");

        Order storage _offer = NFTSalesOrder[_index];

        if(nftContractList[_offer.nftAddress].isERC1155){
            IERC1155(_offer.nftAddress).safeTransferFrom(address(this), _msgSender(), _offer.tokenID, _offer.number, "0x0");
            balances[_offer.nftAddress][_offer.tokenID] = balances[_offer.nftAddress][_offer.tokenID].sub(_offer.number);
        }else{
            IERC721(_offer.nftAddress).safeTransferFrom(address(this), _msgSender(), _offer.tokenID, "0x0");
            balances[_offer.nftAddress][_offer.tokenID] = 0;
        }
        
        _offer.isForSale = false;

        emit CancelSalesOrder(_index,_msgSender(),block.timestamp);

        uint256[] storage saless = accountSalesList[_msgSender()];
        for (uint256 i = 0; i < saless.length; i++) {
            if (saless[i] == _index) {
                deleteElement(saless,i); 
                break;
            }
        }
        for (uint256 i = 0; i < salesList.length; i++) {
            if (salesList[i] == _index) {
                deleteElement(salesList,i); 
                break;
            }
        }
    }

    function deleteElement(uint256[] storage dataArray,uint256 index) internal {
        require(index < dataArray.length, "Invalid index");
        dataArray[index] = dataArray[dataArray.length - 1];
        dataArray.pop();
    }

    function buyNFT(uint256 _index) public payable {

        Order storage _offer = NFTSalesOrder[_index];
        require(NFTSalesOrder[_index].isForSale == true,"error: The state of nft is false");
        require(_offer.onlySellTo == address(0x0) || (_offer.onlySellTo != address(0x0) && _offer.onlySellTo == _msgSender()),"error: No order purchase privileges");

        uint256 operatingAmount = _offer.minPrice.mul(DEV_FUND_PERCENT).div(PERCENTS_DIVIDER);
        uint256 sellerAmount = _offer.minPrice.sub(operatingAmount);
        
        if(_offer.isToken){
            
            require(IERC20(paymentToken).allowance(_msgSender(),address(this)) >= _offer.minPrice && IERC20(paymentToken).balanceOf(_msgSender()) >= _offer.minPrice,"error: Unapproved token or insufficient quota");
            IERC20(paymentToken).transferFrom(_msgSender(), devFundAddress, operatingAmount);
            IERC20(paymentToken).transferFrom(_msgSender(), _offer.seller, sellerAmount);

        }else{
            require(_msgValue() >= _offer.minPrice,"error: Insufficient payment eth");
            (bool seller, ) = _offer.seller.call{value: sellerAmount}("");require(seller);
            (bool dev, ) = devFundAddress.call{value: _msgValue().sub(sellerAmount)}("");require(dev);

        }

        if(nftContractList[_offer.nftAddress].isERC1155){
            balances[_offer.nftAddress][_offer.tokenID] = balances[_offer.nftAddress][_offer.tokenID].sub(_offer.number);
            IERC1155(_offer.nftAddress).safeTransferFrom(address(this), _msgSender(), _offer.tokenID, _offer.number, "0x0");
        }else{
            balances[_offer.nftAddress][_offer.tokenID] = 0;
            IERC721(_offer.nftAddress).safeTransferFrom(address(this), _msgSender(), _offer.tokenID, "0x0");
        }
        
        _offer.isForSale = false;
        uint256[] storage saless = accountSalesList[_offer.seller];

        for (uint256 i = 0; i < saless.length; i++) {
            if (saless[i] == _index) {
                deleteElement(saless,i);
                break;
            }
        }
        for (uint256 i = 0; i < salesList.length; i++) {
            if (salesList[i] == _index) {
                deleteElement(salesList,i);
                break;
            }
        }

        uint256[] storage solds = accountSoldsList[_offer.seller];
        solds.push(_index);
        soldsList.push(_index);

        emit BuyNFT(_index,_msgSender(),block.timestamp);

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
