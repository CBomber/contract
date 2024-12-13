// SPDX-License-Identifier: MIT
// https://cbomber.io
// CBomberData
pragma solidity ^0.8.20;

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

contract CBomberData is Ownable{

    using SafeMath for uint256;

    struct userInfo {
        address referrer;
        uint256 exp; 
        uint256 credit; 
        uint256 invitation;
        bool isReferrer;
        bool state;
    }

    mapping (address => bool) private systemUser;
    mapping (address => userInfo) private userInfoMap;

    event Register(address referrer,uint256 time);
    event System(address _account,bool _state);
    event AddExp(address _account,uint256 _value);
    event SubExp(address _account,uint256 _value);
    event AddCredit(address _account,uint256 _value);
    event AddInvitation(address _account,uint256 _value);
    event SubCredit(address _account,uint256 _value);
    event SetReferrer(address _account,address _referrer);

    modifier onlySystem() {
        require(isSystem(_msgSender()) || owner() == _msgSender(), "Role: caller does not have the System role or above");
        _;
    }

    function isSystem(address account) public view returns (bool) {
        return systemUser[account];
    }

    function addSystem(address account) public onlyOwner{
        systemUser[account] = true;
        emit System(account,true);
    }

    function removeSystem(address account) public onlyOwner{
        systemUser[account] = false;
        emit System(account,false);
    }
    
    function addExp(address _user,uint256 _value) public onlySystem{
         if(userInfoMap[_user].state){
            userInfoMap[_user].exp = userInfoMap[_user].exp.add(_value);
        }else{
            userInfoMap[_user] = userInfo({
            referrer : address(0),
            exp : _value,
            credit : 0,
            invitation : 0,
            isReferrer : false,
            state : true
            });
        }
        emit AddExp(_user,_value);
    }

    function subExp(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].exp = userInfoMap[_user].exp.sub(_value);
        emit SubExp(_user,_value);
    }

    function exp(address _user) public view returns(uint256){
        return userInfoMap[_user].exp;
    }

    function addCredit(address _user,uint256 _value) public onlySystem{
        if(userInfoMap[_user].state){
            userInfoMap[_user].credit = userInfoMap[_user].credit.add(_value);
        }else{
            userInfoMap[_user] = userInfo({
            referrer : address(0),
            exp : 0,
            credit : _value,
            invitation : 0,
            isReferrer : false,
            state : true
            });
        }
        emit AddCredit(_user,_value);
    }

    function addInvitation(address _referrer,uint256 _value) public onlySystem{
        if(userInfoMap[_referrer].state){
            userInfoMap[_referrer].invitation = userInfoMap[_referrer].invitation.add(_value);
        }else{
            userInfoMap[_referrer] = userInfo({
            referrer : address(0),
            exp : 0,
            credit : 0,
            invitation : _value,
            isReferrer : false,
            state : true
            });
        }
        emit AddInvitation(_referrer,_value);
    }

    function subCredit(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].credit = userInfoMap[_user].credit.sub(_value);
        emit SubCredit(_user,_value);
    }

    function credit(address _user) public view returns(uint256){
        return userInfoMap[_user].credit;
    }

    function invitation(address _user) public view returns(uint256){
        return userInfoMap[_user].invitation;
    }


    function referrerAddress(address _user) public view returns(address){
        return userInfoMap[_user].referrer;
    }

    function setReferrer(address _user,address _referrer) public onlySystem{
        if(userInfoMap[_user].state){
            userInfoMap[_user].referrer = _referrer;
        }else{
            userInfoMap[_user] = userInfo({
            referrer : _referrer,
            exp : 0,
            credit : 0,
            invitation : 0,
            isReferrer : false,
            state : true
            });
        }
    }

    function register() public {
        require(userInfoMap[_msgSender()].isReferrer == false,"error: Address is registered");

        if(userInfoMap[_msgSender()].state){
            userInfoMap[_msgSender()].isReferrer = true;
        }else{
            userInfoMap[_msgSender()] = userInfo({
            referrer : address(0),
            exp : 0,
            credit : 0,
            invitation : 0,
            isReferrer : true,
            state : true
            });
        }
        emit Register( _msgSender(),block.timestamp);
    }
}



