// SPDX-License-Identifier: MIT
// https://cbomber.io
// CryptoBomberData
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

contract CryptoBomberData is Ownable{

    using SafeMath for uint256;

    struct userInfo {
        uint256 code;
        uint256 referrerCode;
        uint256 exp; 
        uint256 credit; 
        uint256 invitation;
        bool state;
    }

    mapping (address => bool) private systemUser;
    mapping (address => bool) private gameDaoUser;
    mapping (address => userInfo) private userInfoMap;
    mapping(uint256 => address) private codes;

    uint256 private _currentReferrerCode = 0;

    event Register(address referrer,uint256 code,uint256 time);

    modifier onlySystem() {
        require(isSystem(_msgSender()) || owner() == _msgSender(), "Role: caller does not have the System role or above");
        _;
    }

    function isSystem(address account) public view returns (bool) {
        return systemUser[account];
    }

    function addSystem(address account) public onlyOwner{
        systemUser[account] = true;
    }

    function removeSystem(address account) public onlyOwner{
        systemUser[account] = false;
    }

    function getNextReferrerCode() public view returns (uint256) {
        return _currentReferrerCode.add(1);
    }

    function _getNextReferrerCode() internal view returns (uint256) {
        return _currentReferrerCode.add(1);
    }

    function _incrementReferrerCode() internal  {
        _currentReferrerCode ++;
    }
    
    function addExp(address _user,uint256 _value) public onlySystem{
         if(userInfoMap[_user].state){
            userInfoMap[_user].exp = userInfoMap[_user].exp.add(_value);
        }else{
            userInfoMap[_user] = userInfo({
            code : 0,
            referrerCode : 0,
            exp : _value,
            credit : 0,
            invitation : 0,
            state : true
            });
        }
    }

    function subExp(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].exp = userInfoMap[_user].exp.sub(_value);
    }

    function exp(address _user) public view returns(uint256){
        return userInfoMap[_user].exp;
    }

    function addCredit(address _user,uint256 _value) public onlySystem{
        if(userInfoMap[_user].state){
            userInfoMap[_user].credit = userInfoMap[_user].credit.add(_value);
        }else{
            userInfoMap[_user] = userInfo({
            code : 0,
            referrerCode : 0,
            exp : 0,
            credit : _value,
            invitation : 0,
            state : true
            });
        }
    }

    function addInvitation(address _referrer,uint256 _value) public onlySystem{
        if(userInfoMap[_referrer].state){
            userInfoMap[_referrer].invitation = userInfoMap[_referrer].invitation.add(_value);
        }else{
            userInfoMap[_referrer] = userInfo({
            code : 0,
            referrerCode : 0,
            exp : 0,
            credit : 0,
            invitation : _value,
            state : true
            });
        }
    }

    function subCredit(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].credit = userInfoMap[_user].credit.sub(_value);
    }

    function credit(address _user) public view returns(uint256){
        return userInfoMap[_user].credit;
    }

    function invitation(address _user) public view returns(uint256){
        return userInfoMap[_user].invitation;
    }

    function referrerCode(address _user) public view returns(uint256){
        return userInfoMap[_user].referrerCode;
    }

    function referrerAddress(address _user) public view returns(address){
        return codes[userInfoMap[_user].referrerCode];
    }

    function referrerCodeAssociatedAddress(uint256 _code) public view returns(address){
        return codes[_code];
    }

    function getRegisterReferrerCode(address _user) public view returns(uint256){
        return userInfoMap[_user].code;
    }

    function setReferrer(address _user,uint256 _code) public onlySystem{
        if(userInfoMap[_user].state){
            userInfoMap[_user].referrerCode = _code;
        }else{
            userInfoMap[_user] = userInfo({
            code : 0,
            referrerCode : _code,
            exp : 0,
            credit : 0,
            invitation : 0,
            state : true
            });
        }
    }

    function register() public {
        require(userInfoMap[_msgSender()].code == 0,"error: Address is registered");

        uint256 code = _getNextReferrerCode();
        codes[code] = _msgSender();
        if(userInfoMap[_msgSender()].state){
            userInfoMap[_msgSender()].code = code;
        }else{
            userInfoMap[_msgSender()] = userInfo({
            code : code,
            referrerCode : 0,
            exp : 0,
            credit : 0,
            invitation : 0,
            state : true
            });
        }
        _incrementReferrerCode();
        emit Register( _msgSender(),code,block.timestamp);
    }
}

