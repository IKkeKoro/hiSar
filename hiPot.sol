// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./interfaces/iCore.sol";
import "./interfaces/iMembers.sol";
import "./interfaces/iToken.sol";
import "./interfaces/iMainProject.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
//____________________________________________________________________________________________________//
contract hiPot is AccessControl{
    iCore Core;
    uint  totalIncome;
    bytes32  ADMIN;
    mapping (uint64 => uint) userWithdrawnAt;
    mapping (uint64 => uint) investedInProject;
    mapping (uint64 => uint) incomeFromProject;
    constructor(){
        ADMIN = bytes32(bytes("Admin"));
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        _grantRole(ADMIN,msg.sender);
    }
    event newIncome(uint64 id, uint income);
    event newInvest(uint64 id, uint usdInvested);
    event userWithdraw(uint64 memberId, uint income);
//ADMIN_______________________________________________________________________________________________//
    function investInProject(uint64 _id, uint _usd)external onlyRole(ADMIN){
        require(_usd * 10 ** iToken(Core.getUsd()).decimals() <= getAvailableFunds(),"not enough money");
        iMainProject(Core.getProjects()).investInProject(_id,_usd);
        investedInProject[_id] += _usd * 10 ** iToken(Core.getUsd()).decimals();
        emit newInvest(_id,_usd);
    }

    function claimIncomeFromProject(uint64 _id)external onlyRole(ADMIN){
        uint income = iMainProject(Core.getProjects()).withdrawIncome(_id);
        totalIncome += income;
        incomeFromProject[_id] += income;
        emit newIncome(_id, income);
    }

   function updateCore(iCore _Core)external onlyRole(DEFAULT_ADMIN_ROLE){
        Core = _Core;
    }
//USER________________________________________________________________________________________________//
    function userClaimsIncome()external{
        (uint64 memberId, uint income) = getUserIncome(msg.sender);
        userWithdrawnAt[memberId] = totalIncome;
        iToken(Core.getUsd()).transfer(msg.sender, income);
        emit userWithdraw(memberId, income);
    }
//VIEW________________________________________________________________________________________________//
    function getUserIncome(address _wallet)public view returns(uint64 _memberId, uint _income){
        _memberId = iMembers(Core.getMembers()).getMemberId(_wallet);
        uint pie = getUsedVots() / iMembers(Core.getMembers()).getVotsUsed(_memberId);
        uint withdrawIncome = totalIncome - userWithdrawnAt[_memberId];
        _income = withdrawIncome / pie;
    }

    function getInvestmentsInProject(uint64 _id)external view returns(uint _usd){
        _usd = investedInProject[_id];
    }

    function getIncomeFromProject(uint64 _id)external view returns(uint _usd){
        _usd = incomeFromProject[_id];
    }

    function getUsedVots()public view returns(uint _usedVots){
        _usedVots = iToken(Core.getVots()).getBurned();
    }

    function getCore()external view returns(iCore _Core){
        _Core = Core;
    }

    function getUsdBalance()public view returns(uint _usd){
        _usd = iToken(Core.getUsd()).balanceOf(address(this));
    }

    function getAvailableFunds()public view returns(uint _usd){
        _usd = getUsdBalance() - totalIncome;
    }

    function getTotalIncome()external view returns(uint _totalIncome){
        _totalIncome = totalIncome;
    }
//____________________________________________________________________________________________________//
}