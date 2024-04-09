// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./interfaces/iToken.sol";
import "./interfaces/iCore.sol";
//____________________________________________________________________________________________________//
contract hiProjectBank{
    uint64 id;
    iCore  Core;
    constructor(uint64 _id, iCore _Core){
        id = _id;
        Core = _Core;
    }
    modifier onlyMain{
        require(msg.sender == Core.getProjects(),'Only main contract');
        _;
    }
//ADMIN_______________________________________________________________________________________________//
    function updateCore(iCore _Core)external onlyMain(){
        Core = _Core;
    }
    function sendIncome(address _wallet, uint _usd)external onlyMain(){
        require(_usd<=getUsdBalance(),"Can't withdraw");
        getUsd().transfer(_wallet,_usd);
    }
//VIEW________________________________________________________________________________________________//
    function getUsdBalance()public view returns(uint _usd){
        _usd = getUsd().balanceOf(address(this));
    }

    function getProjcetId()external view returns(uint64 _id){
        _id = id;
    }
//INTERNAL____________________________________________________________________________________________//
    function getUsd()internal view returns(iToken Usd){
        Usd = iToken(Core.getUsd());
    } 
}