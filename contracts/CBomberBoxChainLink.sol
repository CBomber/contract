// SPDX-License-Identifier: MIT
// https://cbomber.io
// CBomberBoxChainLink
pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC1155 {
    
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address account, uint256 id, uint256 value) external ;
}

interface IData{
    function credit(address _user) external view returns(uint256);
    function subCredit(address _user,uint256 _value) external;
    function invitation(address _user) external view returns(uint256);
    function addCredit(address _user,uint256 _value) external;
}

interface  IPoolAdmin {
    function sendGas(uint256 value) external;
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract CBomberBoxChainLink is Ownable, Pausable{

    using SafeMath for uint256;
    using Address for address;
    AggregatorV3Interface internal dataFeed;

    address private rewardNFT;
    address private boxNFT;
    address private devFundAddress;
    address private data;

    uint256 private upgradeNumber = 2;
    uint256 private boxTokenIDMax = 6;
    uint256 public totalBoxOpened = 0;

    bool private isBoxUpgradeState = false;
    bool private isBoxExchangeState = false;
    bool private isBoxDestroyState = false;
    mapping (address => bool) private gameDaoUser;
    mapping (uint256 => uint256[]) positionContainTokenIDs;
    mapping (uint256 => uint256[]) boxContainPositions;
    mapping (uint256 => uint256[]) boxContainTokenNums;
    mapping (uint256 => uint256) needOpenBoxUsd;
    mapping(uint256 => uint256) boxRatio;
    mapping(uint256 => uint256) basicRatio;

    event Open(address user,uint256 rewardType,address contractorAddress,uint256 tokenid,uint256 number,uint256 boxID,uint256 time);
    event Upgrade(address user,uint256 tokenID,uint256 number,uint256 time);
    event Exchange(address user,uint256 tokenID,uint256 number,uint256 time);
    event Destroy(address user,uint256 tokenID,uint256 number,uint256 credit,uint256 time);

    constructor (address _basicNFT,address _propsNFT,address _devAddress,address _data) {
        rewardNFT = _basicNFT;
        boxNFT = _propsNFT;
        devFundAddress = _devAddress;
        data = _data;

        pause();

        initNeedOpenBoxGas();
        initBoxContainPositions();
        initBoxRatio();
        dataFeed = AggregatorV3Interface(0x59F1ec1f10bD7eD9B938431086bC1D9e233ECf41);//Scroll Goerli Testnet,eth usd
    }

    modifier onlyGameDao() {
        require(isGameDao(_msgSender()) || owner() == _msgSender(), "Role: caller does not have the GameDao role or above");
        _;
    }

    function isGameDao(address account) public view returns (bool) {
        return gameDaoUser[account];
    }

    function addGameDao(address account) public onlyOwner{
        gameDaoUser[account] = true;
    }

    function removeGameDao(address account) public onlyOwner{
        gameDaoUser[account] = false;
    }

    function initBoxContainPositions() internal {
        boxContainPositions[1] = [11,12];
        boxContainPositions[2] = [13,14];
        boxContainPositions[3] = [7,8,9,10];
        boxContainPositions[4] = [4,5,6];
        boxContainPositions[5] = [1,2,3];
        boxContainPositions[6] = [15,16,17];
    }

    function initNeedOpenBoxGas() internal {
        needOpenBoxUsd[1] = 100000000;
        needOpenBoxUsd[2] = 196000000;
        needOpenBoxUsd[3] = 288000000;
        needOpenBoxUsd[4] = 376000000;
        needOpenBoxUsd[5] = 460000000;
        needOpenBoxUsd[6] = 540000000;
    }

    function initBoxRatio() internal{
        boxRatio[1] = 50;
        boxRatio[2] = 102;
        boxRatio[3] = 156;
        boxRatio[4] = 212;
        boxRatio[5] = 260;
        boxRatio[6] = 330;
    }

    function getRewardNFT() public view returns(address){
        return rewardNFT;
    }

    function setRewardNFT(address _nft) public onlyOwner{
        rewardNFT = _nft;
    }

    function getBoxNFT() public view returns(address){
        return boxNFT;
    }

    function setBoxNFT(address _nft) public onlyOwner{
        boxNFT = _nft;
    }

    function getDevFundAddress() public view returns(address){
        return devFundAddress;
    }

    function setDevFundAddress(address _address) public onlyOwner{
        devFundAddress = _address;
    }

    function getDataAddress() public view returns(address){
        return data;
    }

    function setDataAddress(address _data) public onlyOwner{
        data = _data;
    }

    function getUpgradeNumber()public view returns(uint256){
        return upgradeNumber;
    }

    function setUpgradeNumber(uint256 _value) public onlyGameDao{
        upgradeNumber = _value;
    } 

    function getBoxTokenIDMax() public view returns(uint256){
        return boxTokenIDMax;
    }

    function setBoxTokenIDMax(uint256 _value) public onlyGameDao{
        boxTokenIDMax = _value;
    }

    function getBoxUpgradeState() public view returns(bool){
        return isBoxUpgradeState;
    }

    function setBoxUpgradeState(bool _value) public onlyGameDao{
        isBoxUpgradeState = _value;
    }

    function setBoxDestroyState(bool _value) public onlyGameDao{
        isBoxDestroyState = _value;
    }

    function getBoxDestroyState() public view returns(bool){
        return isBoxDestroyState;
    }

    function setBoxExchangeState(bool _value) public onlyGameDao{
        isBoxExchangeState = _value;
    }

    function getBoxExchangeState() public view returns(bool){
        return isBoxExchangeState;
    }

    function pause() public onlyOwner() {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updatePositionContainTokenIDs(uint256 _position, uint256[] memory _tokenIDs) public onlyGameDao{
        positionContainTokenIDs[_position] = _tokenIDs;
    }

    function getPositionContainTokenIDs(uint256 _position) public view returns(uint256[] memory){
        return positionContainTokenIDs[_position];
    }

    function updateBoxContainPositions(uint256 _boxTokenID, uint256[] memory _positions) public onlyGameDao{
        boxContainPositions[_boxTokenID] = _positions;
    }

    function getBoxContainPositions(uint256 _boxTokenID) public view returns(uint256[] memory){
        return boxContainPositions[_boxTokenID];
    }

    function updateBoxContainTokenNums(uint256 _boxTokenID,uint256[] memory _tokenNums) public onlyGameDao{
        boxContainTokenNums[_boxTokenID] = _tokenNums;
    }

    function getBoxContainTokenNums(uint256 _boxTokenID) public view returns(uint256[] memory){
        return boxContainTokenNums[_boxTokenID];
    }

    function updateBoxRatio(uint256 _tokenid,uint256 _value) public onlyGameDao{
        boxRatio[_tokenid] = _value;
    }

    function getBoxRatio(uint256 _tokenid) public view returns(uint256){
        return boxRatio[_tokenid];
    }

    function updateBasicRatio(uint256[] memory tokenids,uint256[] memory ratios) public onlyOwner{
        require(tokenids.length == ratios.length ,'error: tokenids and ratios length mismatch');
        for(uint index = 0 ; index < tokenids.length ; index ++){
            basicRatio[tokenids[index]] = ratios[index];
        }
    }

    function getBasicRatio(uint256 tokenid) public view returns(uint256){
        return basicRatio[tokenid];
    }

    function updateNeedOpenBoxUsd(uint256 _boxTokenID,uint256 _value) public onlyOwner{
        needOpenBoxUsd[_boxTokenID] = _value;
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function getNeedOpenBoxGas(uint256 _boxTokenID) public view returns(uint256){
        return needOpenBoxUsd[_boxTokenID] * (1 ether) / (uint256(getChainlinkDataFeedLatestAnswer()));
    }

    function setDataFeedAddress(address _adderss) public onlyOwner {
        dataFeed = AggregatorV3Interface(_adderss);
    }

    function getNeedOpenBoxUsd(uint256 _boxTokenID) public view returns(uint256){
        return needOpenBoxUsd[_boxTokenID];
    } 

    function executeRewardNFT(uint256 tokenID) internal{
        uint256[] memory positions = boxContainPositions[tokenID];
        uint256 positionIndex = random(positions.length);
        uint256[] memory tokenids = positionContainTokenIDs[positions[positionIndex]];
        uint256 tokenidIndex = random(tokenids.length);
        uint256 tokenid = tokenids[tokenidIndex];
        IERC1155(rewardNFT).mint(_msgSender(), tokenid, 1, '0x0');

        emit Open(_msgSender(),1,rewardNFT,tokenid,1,tokenID,block.timestamp);
    }

    function boxOpen(uint256 tokenID) public payable whenNotPaused{
        require(!_msgSender().isContract(),'error: Requestor is the contractual address');
        require(msg.value >= getNeedOpenBoxGas(tokenID),'error: Insufficient transmission of gas value');
        require(IERC1155(boxNFT).balanceOf(_msgSender(), tokenID) > 0 ,'error: Box balance is low');

        totalBoxOpened ++;

        IERC1155(boxNFT).burn(_msgSender(), tokenID,1);
        
        executeRewardNFT(tokenID);
       
        (bool s, ) = devFundAddress.call{value: msg.value}("");require(s);
       
    }

    function boxUpgrade(uint256 tokenID,uint256 number) public whenNotPaused{
        require(isBoxUpgradeState ,'error: Upgrades not enabled');
        require(tokenID < boxTokenIDMax,'error: Boxes are not upgradable' );
        require(number > 0,'error: The number of upgrades needs to be greater than 0');
        require(IERC1155(boxNFT).balanceOf(_msgSender(), tokenID) >= upgradeNumber.mul(number),'error: Insufficient number of nfts to be upgraded');

        IERC1155(boxNFT).burn(_msgSender(),tokenID,upgradeNumber.mul(number));
        IERC1155(boxNFT).mint(_msgSender(),tokenID.add(1),number,'0x0');

        emit Upgrade(_msgSender(),tokenID,number,block.timestamp);
    }

    function boxExchange(uint256 tokenID,uint256 number) public whenNotPaused{
        require(isBoxExchangeState,'error: Exchange not enabled');
        require(tokenID <= boxTokenIDMax,'error: tokenid exceeds the maximum');
        require(number > 0,'error: The number of upgrades needs to be greater than 0');
        require(boxRatio[tokenID] > 0 ,'error: The tokenid is not configured with a redemption ratio');
        require(IData(data).credit(_msgSender()) >= boxRatio[tokenID].mul(number),'error: Insufficient address values');

        IData(data).subCredit(_msgSender(), boxRatio[tokenID].mul(number));
        IERC1155(boxNFT).mint(_msgSender(),tokenID,number,'0x0');

        emit Exchange(_msgSender(),tokenID,number,block.timestamp);
    }

    function boxDestroy(uint256 tokenID,uint256 number) public whenNotPaused{
        require(isBoxDestroyState,'error: Exchange not enabled');
        require(number > 0,'error: The number of upgrades needs to be greater than 0');
        require(getBasicRatio(tokenID) > 0 ,'error: The tokenid is not configured with a redemption ratio');
        require(IERC1155(rewardNFT).balanceOf(_msgSender(), tokenID) >= number,'error: nft Insufficient balance');

        IERC1155(rewardNFT).burn(_msgSender(),tokenID,number);
        
        IData(data).addCredit(_msgSender(), getBasicRatio(tokenID).mul(number));

        emit Destroy(_msgSender(),tokenID,number,getBasicRatio(tokenID).mul(number),block.timestamp);
    }


    function random(uint number) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,
        block.difficulty,
        block.number,
        block.gaslimit,
        totalBoxOpened,
        msg.sender))) % number;
    }

}