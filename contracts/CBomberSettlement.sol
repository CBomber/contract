// SPDX-License-Identifier: MIT
// https://cbomber.io
// CBomberSettlement
pragma solidity 0.8.20;

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

interface IData{
    function addExp(address _user,uint256 _value) external;
}

interface IERC1155 {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256) ;
}

contract CBomberSettlement is Ownable, Pausable{

    using SafeMath for uint256;
    using ECDSA for *;

    struct userInfo {
        uint256 count; 
        uint256 lasttime;
        uint256 lastTokenID;
        bool lastIsNft;
        bool issubmit;
    }

    mapping(address => userInfo) private userInfoMap;
    mapping(bytes32 => bool) private signerBytesMap;

    address public signerAddress;
    uint256 public INTERVAL_TIME = 1 minutes;
    uint256 public scoreBase = 10;

    address public basicNft;
    address public data;
    address[] public badges;
    uint256 public tokenIDLimit = 1907;
    uint256 public BASE_PERCENT = 10;

    mapping(address => uint256) badgePercent;
    
    event SetBasicTokenIDLimit(uint256 _limitValue);
    event SetBadgePercent(address _badge,uint256 _value);
    event SetScoreBase(uint256 score);
    event SetNftAddress(address _nft);
    event SetIntervalTime(uint256 _time);
    event SetSignerAddress(address _signer);
    event Submit(address user,uint256 score,uint256 time);
    event AwardNFT(address user,uint256 tokenid,uint256 time);

    constructor (address _signer,address _basic,address _data) {
        signerAddress = _signer;
        basicNft = _basic;
        data = _data;
        pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getUserInfo(address _account) public view returns(userInfo memory){
        return userInfoMap[_account];
    }

    function setBadgePercent(address _badge,uint256 _value) public onlyOwner {
        badgePercent[_badge] = _value;
        if(!judgmentBadges(_badge)) badges.push(_badge);

        emit SetBadgePercent(_badge,_value);
    }

    function judgmentBadges(address _badge) internal view returns(bool){
        for(uint index = 0 ; 0 < badges.length ; index ++){
            if(badges[index] == _badge) return true;
        }
        return false;
    }

    function setBasicTokenIDLimit(uint256 _limit) public onlyOwner{
        tokenIDLimit = _limit;

        emit SetBasicTokenIDLimit(_limit);
    }

    function setScoreBase(uint256 _value) public onlyOwner{
        scoreBase = _value;
        emit SetScoreBase(_value);
    }

    function setNftAddress(address newNFTAddress) public onlyOwner{
        basicNft = newNFTAddress;

        emit SetNftAddress(newNFTAddress);
    }

    function setIntervalTime(uint256 newTime) public onlyOwner{
        INTERVAL_TIME = newTime;
        emit SetIntervalTime(newTime);
    }

    function setSignerAddress(address newAddress) public onlyOwner {
        signerAddress = newAddress;
        emit SetSignerAddress(newAddress);
    }

    function submit(bytes32 _hashedMessage,bytes memory _signature, uint256 _score) public whenNotPaused{

        require(_score >0 ,"error: Score needs to be greater than 0");
        require(ECDSA.VerifyMessage(_hashedMessage,_signature,signerAddress), "error: Invalid signature");
        require(signerBytesMap[_hashedMessage] == false ,"error: Signature used");
        require(block.timestamp.sub(userInfoMap[_msgSender()].lasttime) >= INTERVAL_TIME,"error: Insufficient interval time");

        if(userInfoMap[_msgSender()].issubmit){
             userInfoMap[_msgSender()].count = userInfoMap[_msgSender()].count.add(1);
             userInfoMap[_msgSender()].lasttime = block.timestamp;
        }else{
            userInfoMap[_msgSender()] = userInfo({
                count : 1,
                lasttime : block.timestamp,
                lastTokenID : 0,
                lastIsNft : false,
                issubmit : true
            });
        }

        uint256 randomNum = random(100);

        uint256 percentNum = BASE_PERCENT;
        for(uint index = 0; index < badges.length ; index++){
            uint nftAmount = IERC721(badges[index]).balanceOf(_msgSender());
            if( nftAmount > 0){
                percentNum = percentNum.add(badgePercent[badges[index]].mul(nftAmount));
            }
        }
        
        if(randomNum.add(1) <= percentNum && _score >= scoreBase){
            uint256 tokenID = random(tokenIDLimit).add(1);
            IERC1155(basicNft).mint(_msgSender(),tokenID,1,'0x0');

            userInfoMap[_msgSender()].lastIsNft = true;
            userInfoMap[_msgSender()].lastTokenID = tokenID;

            emit AwardNFT(_msgSender(),tokenID,block.timestamp);
        }else{
            userInfoMap[_msgSender()].lastIsNft = false;
            userInfoMap[_msgSender()].lastTokenID = 0;
        }

        emit Submit(_msgSender(),_score,block.timestamp);
        IData(data).addExp(_msgSender(), _score);
    }

    function getPercentageOfNFT(address _account) public view returns (uint256){
        uint256 percentNum = BASE_PERCENT;
        for(uint index = 0; index < badges.length ; index++){
            uint nftAmount = IERC721(badges[index]).balanceOf(_account);
            if( nftAmount > 0){
                percentNum = percentNum.add(badgePercent[badges[index]].mul(nftAmount));
            }
        }
        return  percentNum > 100 ? 100 : percentNum;
    }

    function random(uint number) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,
        block.number,
        block.gaslimit,
        _msgSender()))) % number;
    }

}
