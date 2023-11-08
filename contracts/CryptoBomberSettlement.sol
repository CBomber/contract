// SPDX-License-Identifier: MIT
// https://cbomber.io
// CryptoBomberSettlement
pragma solidity 0.8.8;

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


library ECDSA {

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }
        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }

    function VerifyMessage(bytes32 _hashedMessage, bytes memory _signature , address signerAddress) internal pure returns (bool) {
        address signer = recover(_hashedMessage,_signature);
        if(signer == signerAddress)
            return true;
        else
            return false;
    }

}

interface IERC1155 {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}

interface IData{
    function addExp(address _user,uint256 _value) external;
    function exp(address _user) external view returns(uint256);
    function addCredit(address _user,uint256 _value) external;
    function credit(address _user) external view returns(uint256);
    function setReferrer(address _user,uint256 _code) external;
    function addInvitation(address _referrer,uint256 _value) external;
    function referrerCodeAssociatedAddress(uint256 _code) external view returns(address);
    function referrerCode(address _user) external view returns(uint256);
    function referrerAddress(address _user) external view returns(address);
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

contract CryptoBomberSettlement is Ownable, Pausable{

    using SafeMath for uint256;
    using ECDSA for *;

    struct userInfo {
        address user; 
        uint256 count; 
        uint256 lasttime;
        bool issubmit;
    }

    mapping(address => uint256) signInLastTime;
    mapping(address => userInfo) private userInfoMap;
    mapping(bytes32 => bool) private signerBytesMap;
    mapping (address => bool) private gameDaoUser;

    address private signerAddress;
    uint256 private INTERVAL_TIME = 1 minutes;
    uint256 private SIGNIN_INTERVAL_TIME = 24 hours;
    uint256 private levelLimit = 6;
    uint256 private scoreBase = 10;
    uint256[] private invitationCredits = [5,1];
    uint256 private signInCredit = 2;
    bool private isSignInState = false;

    address private propsNft;
    address private data;

    event Submit(address user,uint256 score,uint256 time);
    event AwardNFT(address user,address nftAddress,uint256 tokenid,uint256 number,uint256 time);

    constructor (address _signer,address _propsNft,address _data) {
        signerAddress = _signer;
        propsNft = _propsNft;
        data = _data;
        pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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

    function exp(address _user) public view returns(uint256){
        return IData(data).exp(_user);
    }

    function credit(address _user) public view returns(uint256){
        return IData(data).credit(_user);
    }

    function getDataAddress() public view returns(address){
        return data;
    }

    function setDataAddress(address _data) public onlyOwner{
        data = _data;
    }

    function getUserisSubmit(address _account) public view returns(bool){
        return userInfoMap[_account].issubmit;
    }

    function getUserSubmitCount(address _account) public view returns(uint256){
        return userInfoMap[_account].count;
    }

    function getUserSubmitLastTime(address _account) public view returns(uint256){
        return userInfoMap[_account].lasttime;
    }

    function getScoreBase() public view returns(uint256){
        return scoreBase;
    }

    function setScoreBase(uint256 _value) public onlyGameDao{
        scoreBase = _value;
    }

    function getInvitationCredit() public view returns(uint256[] memory){
        return invitationCredits;
    }

    function setInvitationCredit(uint256[] memory _values) public onlyGameDao{
        invitationCredits = _values;
    }

    function getIsSignInState() public view returns(bool){
        return isSignInState;
    }

    function setIsSignInState(bool _value) public onlyGameDao{
        isSignInState = _value;
    }

    function _setReferrer(uint256 _code) internal {
        address referrer = IData(data).referrerCodeAssociatedAddress(_code);
        if(referrer != address(0) && IData(data).referrerCode(_msgSender()) == 0 && referrer != _msgSender()){
            IData(data).setReferrer(_msgSender(),_code);
            IData(data).addInvitation(referrer,1);
        }
    }

    function _addInvitationCredits() internal{
        address _address = _msgSender();
        for(uint256 index = 0; index < invitationCredits.length ; ++index){
            if(IData(data).referrerCode(_address) > 0){
                IData(data).addCredit(IData(data).referrerAddress(_address),invitationCredits[index]);
                _address = IData(data).referrerAddress(_address);
            }else{
                break;
            }
        }
    }

    function setReferrer(uint256 _code) public {
        _setReferrer(_code);
    }

    function setNftAddress(address newNFTAddress) public onlyOwner{
        propsNft = newNFTAddress;
    }

    function getNftAddress() public view returns(address){
        return propsNft;
    }

    function setIntervalTime(uint256 newTime) public onlyGameDao{
        INTERVAL_TIME = newTime;
    }

    function getIntervalTime() public view returns(uint256){
        return INTERVAL_TIME;
    }

    function setSignerAddress(address newAddress) public onlyOwner {
        signerAddress = newAddress;
    }

    function getSignerAddress() public view returns(address){
        return signerAddress;
    }

    function setLevelLimit(uint256 newLevel) public onlyOwner{
        levelLimit = newLevel;
    }

    function getLevelLimit() public view returns(uint256){
        return levelLimit;
    }

    function getSignInCredit() public view returns(uint256){
        return signInCredit;
    }

    function setSignInCredit(uint256 _value) public onlyGameDao{
        signInCredit = _value;
    }

    function submit(bytes32 _hashedMessage,bytes memory _signature, uint256 _score, uint256 code) public whenNotPaused{
        //it's not public.
    }

    function signIn() public {
        require(isSignInState,'error: Exchange not enabled');
        require(block.timestamp.sub(signInLastTime[_msgSender()]) >= SIGNIN_INTERVAL_TIME,"error: Insufficient interval time");
        IData(data).addCredit(_msgSender(),signInCredit);
        signInLastTime[_msgSender()] = block.timestamp;
    }

    function getSignInLastTime(address _user) public view returns(uint256){
        return signInLastTime[_user];
    }
}
