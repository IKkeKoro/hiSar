// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./interfaces/iToken.sol";
import "./interfaces/iCore.sol";
import "./interfaces/iMembers.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
//____________________________________________________________________________________________________//
contract hiVots is ERC20,AccessControl{
    mapping (uint64 => uint16) bonusVots;
    mapping (uint64 => uint  ) bonusTime;

    uint16[]  subPrice;
    uint16[]  subIncome;
    uint16[]  poolShare; // 0-dev, 1-pot, 2-fund 
    bytes32 ADMIN;
    uint burned;
    uint minted;
    iCore Core;
    constructor() ERC20("Vots","vts") {
        subPrice  = [25, 50, 100,300];
        subIncome = [8 , 20, 50, 200];
        poolShare = [60, 30, 10];
        ADMIN = bytes32(bytes("ADMIN"));
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        _grantRole(ADMIN,msg.sender);
    }
//MEMBER______________________________________________________________________________________________//
    function buySubscription(uint8 _subLevel, uint _months)external{
        require(subPrice.length  > _subLevel,"Wrong level");
        require(msg.sender != address(0),"Zero address");
        iMembers Members = getMembers();
        iToken   Usd     = getUsd();
        uint     price   = _months * (subPrice[_subLevel] * 10 ** Usd.decimals());
        if(Members.getMemberId(msg.sender) == 0) 
            Members.registration(msg.sender);    
        uint64 id = Members.getMemberId(msg.sender);
        Usd.transferFrom(msg.sender,Core.getDev(), ((price * poolShare[0])/100));
        Usd.transferFrom(msg.sender,Core.getPot(), ((price * poolShare[1])/100));
        Usd.transferFrom(msg.sender,Core.getFund(),((price * poolShare[2])/100));
        Members.updateSubscription(id, _subLevel, _months);
    }

    function claim()external{
        require(msg.sender != address(0), "Zero address");
        iMembers Members = getMembers();
        uint64 id = Members.getMemberId(msg.sender);
        uint vots = getClaim(id);
        require(vots > 0, "Nothing to claim");
        Members.updateClaim(id, vots);
        _mint(msg.sender, vots);
        minted += vots;
    }
//ADMIN_______________________________________________________________________________________________//
    function updateSubscriptons(uint16[] memory _subPrice, uint16[] memory _subIncome)external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_subPrice.length == _subIncome.length, "[ ]==[ ]");
        subPrice  = _subPrice;
        subIncome = _subIncome; 
    }

    function updateBonus(uint64 _id, uint16 _vots, uint16 _weeks)external onlyRole(ADMIN){
        bonusVots[_id] = _vots;
        bonusTime[_id]  = block.timestamp + (_weeks * 1 weeks);
    }

    function updateCore(iCore _Core)external onlyRole(DEFAULT_ADMIN_ROLE){
        Core = _Core;
    }

    function updatePoolShare(uint16[3] memory _poolShare)external onlyRole(ADMIN){
        require(_poolShare[0] + _poolShare[1] + _poolShare[2] == 100, "wrong percentage");
        poolShare = _poolShare;
    }
//VIEW_______________________________________________________________________________________________//
    function getClaim(uint64 _id)public view returns(uint _vots){
        iMembers Members = getMembers();
        uint claimPeriod = (block.timestamp - Members.getClaimTime(_id)) / 7 days;
        _vots  = (subIncome[Members.getSubLevel(_id)] * claimPeriod) * 10 ** decimals();
        if (bonusTime[_id] > Members.getClaimTime(_id))
             _vots += (bonusVots[_id] * claimPeriod) * 10 ** decimals(); 
        if(Members.getClaimTime(_id) == 0)
            _vots = 0; 
    }

    function getBonus(uint64 _id)external view returns(uint16 _vots, uint _bonusTime){
        _vots = bonusVots[_id];
        _bonusTime = bonusTime[_id];
    }

    function getSubscriptionInfo()external view returns(uint16[] memory _subPrice,uint16[] memory _subIncome){
        _subPrice =  subPrice;
        _subIncome = subIncome;
    }

    function getBurned() external view returns(uint _burned){
        _burned = burned;
    }

    function getMinted() external view returns(uint _minted){
        _minted = minted;
    }
//INTERNAL____________________________________________________________________________________________//
   function transfer(address to, uint value)public override returns(bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        _burnAfterTransfer(to,value);
        return true;
    }

    function transferFrom(address from, address to, uint value)public override returns(bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        _burnAfterTransfer(to,value);
        return true;
    }

    function _burnAfterTransfer(address _from, uint _value)internal{
        _burn(_from,_value);
        burned+=_value;
    }

    function getMembers()internal view returns(iMembers Members) {
        Members = iMembers(Core.getMembers());
    }

    function getUsd()internal view returns(iToken Usd){
        Usd = iToken(Core.getUsd());
    }
//____________________________________________________________________________________________________//
}

