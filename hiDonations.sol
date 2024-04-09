// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./interfaces/iToken.sol";
import "./interfaces/iCore.sol";
import "./interfaces/iMembers.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
//____________________________________________________________________________________________________//
contract hiDonations is AccessControl{
    struct Fund{
        address creator;
        string  title;
        uint16  category;

        uint    usdDonations;
        bool    active;
    }
    bytes32 MODERATOR; 
    mapping (uint64 => Fund) funds;
    uint64  id;
    iCore Core;
    constructor(){
        MODERATOR = bytes32(bytes("MODERATOR"));
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        _grantRole(MODERATOR,msg.sender);
    }
    event NewFund(uint64 id,string title,address creator);
//ADMIN_________________________________________________________________________________________________//
    function updateCore(iCore _Core)external onlyRole(DEFAULT_ADMIN_ROLE){
        Core = _Core;
    }

    function updateCategory(uint64 _id, uint16 _category)external onlyRole(MODERATOR){
        funds[_id].category = _category;
    }
//CREATOR______________________________________________________________________________________________//
    function createFund(string memory _title)external{
        iMembers Members = getMembers();
        uint64 memberId = Members.getMemberId(msg.sender);
        require(memberId !=0,"You are not registered yet");
        require(Members.getVerification(memberId), "You need to pass verification");
        funds[id] = Fund(
            msg.sender,
            _title,
            0,
            0,
            true
        );
        emit NewFund(id,_title,msg.sender);
        id++;
    }

    function toggleFund(uint64 _id,bool _active)external{
        require(msg.sender == funds[_id].creator || hasRole(MODERATOR,msg.sender));
        funds[_id].active = _active;
    }
//USER_________________________________________________________________________________________________//
    function donation(uint64 _id, uint _usd)external{
        require(funds[_id].active,"Can't donate for now");
        iToken USD = getUsd();
        USD.transferFrom(msg.sender,funds[_id].creator,_usd * 10 ** USD.decimals());
        funds[_id].usdDonations += _usd;
    }
//VIEW_________________________________________________________________________________________________//
    function getFund(uint64 _id)external view returns(Fund memory _fund){
        _fund = funds[_id];
    }

    function getCore()external view returns(iCore _Core){
        _Core = Core;
    }

    function getCreator(uint64 _id)external view returns(address _creator){
        _creator = funds[_id].creator;
    }

    function getDonations(uint64 _id)external view returns(uint _usd){
        _usd = funds[_id].usdDonations;
    }

    function getCategory(uint64 _id)external view returns(string memory _category){
        _category = Core.getCategory(funds[_id].category);
    }

    function getFunds(uint64 _id, uint64 _amount)external view returns(Fund[] memory _funds){
        if(_amount == 0)
           _amount  = id-_id;
        require(_id+_amount<=id,"Wrong ids");
        _funds = new Fund[](_amount);
        for(uint64 i=_id; i<_amount+_id;i++){
            Fund memory item = funds[i];
            _funds[i] = item;
        }
    }
//INTERNAL_____________________________________________________________________________________________//
    function getMembers()internal view returns(iMembers Members) {
        Members = iMembers(Core.getMembers());
    }

    function getUsd()internal view returns(iToken Usd){
        Usd = iToken(Core.getUsd());
    } 
//____________________________________________________________________________________________________//
}