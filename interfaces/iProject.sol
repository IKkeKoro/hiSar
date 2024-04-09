// SPDX-License-Identifier: MIT
import "./iMembers.sol";
import "./iToken.sol";
import "./iCore.sol";
pragma solidity ^0.8.18;

interface iProject {
    struct Project{
        string    title;
        address   creator;
        uint64    id;
        uint8[4]  pies;    

        uint8     stages;
        uint8     currentStage;
        uint      stageDeadline;
        uint16    category;
        
        uint[]    vestingPerStage;
        uint      investmentsNeed;
        uint      investmentsGet;
        uint      unlockedInvestments;

        uint      totalVots;
        uint      totalIncome;

        uint64[]  membersId;
        bool      active;
    }

    function _changeStagesAndInvestments(uint8 _stages,uint _investmentsNeed,uint[] memory _vestingPerStage)external;

    function _changeDeadline(uint _months)external;

    function _addIncome(iToken _USD, address _POTcontract, address _sender, uint _usd, bool creatorPie)external returns(uint _amount);

    function _addFiles(string[] memory _files)external;

    function _deleteFile(uint8 _fileId)external;

    function _unlockInvestments(iToken _USD)external returns(uint _amount);

    function _beginStageValidation()external;
//_____________________________________________________________________________________________________//
    function _investInProject(iToken _USD, iMembers _Members, address _sender, uint _usd)external returns(uint64 _memberId);

    function _withdrawInvestments(iToken _USD, address _POTcontract,address _sender, uint _usd)external;

    function _votsForProject(iToken _Vots, iMembers _Members, address _sender, uint _vots)external returns(uint64 _memberId);

    function _votsForStage(iMembers _Members, address _sender, bool _up)external;

    function _withdrawIncome(iToken _USD, iMembers _Members, address _sender)external returns(uint64 _memberId, uint _income, uint _totalIncome);    
//_____________________________________________________________________________________________________//
    function _nextStage(uint8 _stage)external;

    function _nextRound(uint8 _round)external;

    function _toggleStageValidation()external returns(bool _active);

    function _toggleProject()external;

    function _changeCategory(uint16 _category)external;
    
    function _increaseDeadline(uint _months)external;

    function _updateCore(iCore _Core)external;
//_____________________________________________________________________________________________________//
    function getProject()external view returns(Project memory _project);

    function getTitle()external view returns(string memory _title);

    function getCreator()external view returns(address _creator);

    function getId()external view returns(uint64 _id);

    function getPies()external view returns(uint8[4] memory _pies);

    function getStages()external view returns(uint8 _stages);

    function getCurrentStage()external view returns(uint8 _currentStage);
    
    function getDeadline()external view returns(uint _stageDeadline);

    function getCategory()external view returns(string memory _category);

    function getRequirementInvestments()external view returns(uint _investmentsNeed);

    function getTotalInvestments()external view returns(uint _investmentsGet);

    function getTotalVots()external view returns(uint _totalVots);

    function getTotalIncome()external view returns(uint _totalIncome);

    function getFiles()external view returns(string[] memory _files);

    function getProjectMembers()external view returns(uint _number, uint64[] memory _members);

    function getUpDownVots(uint8 _stage)external view returns(uint[2] memory _upDownVots);

    function getMemberUpDownVots(uint64 _memberId,uint8 _stage)external view returns(uint8 _upDownVots);

    function getStatus()external view returns(bool _active);

    function getStageStatus()external view returns(bool _stageActive);
}