// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./hiProjectBank.sol";
import "./interfaces/iMembers.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
//____________________________________________________________________________________________________//
contract hiProjects is AccessControl{
    struct Project{
            string    title;
            string    description;
            string    image;

            address   creator;
            uint64    id;
            uint8[4]  pies;     // 0-platform pie,1-creator pie,2-members pie,3-investors pie;

            address   projectBank; 

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

            string[]  files;

            uint64[]  membersId;
            bool      active;
    }
    mapping (uint64 => Project) projects;

    struct StageVots{
        uint[2] upDownVots;
        mapping(uint64 => uint8) memberVots;
        uint8   round;
        bool    active;
    }
    mapping (uint64 => mapping(uint8 => StageVots)) stageVots;  

    bytes32 MODERATOR;
    uint[3] payments;  
    uint64  id;
    iCore Core;
    constructor(){
        payments  = [100,40,10]; // 0-100$ to create project 1-40$ to change stages and investments, 2-10$ for each month to increace deadline 
        MODERATOR = bytes32(bytes("Moderator"));
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        _grantRole(MODERATOR,msg.sender);
    }
    event AddIncome (uint64 id, uint usd);
    event StageActive(uint64 id, bool active);
    event CurrentStage(uint64 id, uint8 stage);
    event CurrentRound(uint64 id, uint8 round);
    event UpdateDeadline(uint64 id, uint time);
    event UnlockInvestments(uint64 id, uint usd);
    event ChangeCategory(uint64 id, uint16 category);
    event Investment(uint64 id,uint64 projectId,uint usd);
    event NewProject(uint64 id,string title,address creator);
    event VotsInvestment(uint64 id,uint64 projectId,uint vots);
    event UpdateStagesAndInvestments(uint64 id,uint8 stages,uint investmentsNeed);
//CREATOR_____________________________________________________________________________________________//
    function createProject
    (
        string memory _title, string memory _description, string memory _image, 
        uint8 _stages,uint _investmentsNeed,uint[] memory _vestingPerStage, uint8[4] memory _pies
    )
    external{
        require(_vestingPerStage.length == _stages,"Vesting length must be equal to stages");
        require((_pies[0]+_pies[1]+_pies[2]+_pies[3]) == 100, "Wrong percentage");
        require(_pies[0]>1 && _pies[2]>4 && _pies[3]>14,"Choose correct pies");
        require(msg.sender != address(0),  "Zero address");
        require(_stages > 2, "Add more stages");
        iMembers Members = getMembers();
        uint64 memberId = Members.getMemberId(msg.sender);
        require(memberId > 0, "You are not registered");
        require(Members.getVerification(memberId), "You need to pass verification");
        iToken USD = getUsd();
        USD.transferFrom(msg.sender,Core.getDev(),payments[0] * 10 ** USD.decimals());
        for (uint8 i=1; i<_vestingPerStage.length;i++)
            require(_vestingPerStage[i]>_vestingPerStage[i-1],"next unlock value must be more than previous");
        require(_vestingPerStage[_vestingPerStage.length-1] == _investmentsNeed,"Vesting value must be equal to requirement investments");
        hiProjectBank bank = new hiProjectBank(id, Core);
        uint64[] memory _members;
        string[] memory _files;
        projects[id] = Project(
            _title,
            _description,
            _image,
            msg.sender,
            id,
            _pies,
            address(bank),
            _stages +2,
            0,
            block.timestamp + 16 weeks,
            0,
            _vestingPerStage,
            _investmentsNeed,
            0,0,0,0,
            _files,
            _members,
            true
        );
        emit NewProject(id,_title,msg.sender);
        id++;
    }

    function changeStagesAndInvestments(uint64 _id,uint8 _stages,uint _investmentsNeed,uint[] memory _vestingPerStage)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator, "Not a creator");
        require(_stages > 2, "Add more stages");
        for (uint8 i=1; i<_vestingPerStage.length;i++)
            require(_vestingPerStage[i]>_vestingPerStage[i-1],"next unlock value must be more than previous");
        require(_vestingPerStage[_vestingPerStage.length-1] == _investmentsNeed,"Vesting value must be equal to requirement investments");
        require(_investmentsNeed >= project.investmentsNeed, "You already have more investments");
        iToken USD = getUsd();
        USD.transferFrom(msg.sender,Core.getDev(),payments[1] * 10 ** USD.decimals());
        project.stages = _stages;
        project.investmentsNeed = _investmentsNeed;
        project.vestingPerStage = _vestingPerStage;
        emit UpdateStagesAndInvestments(_id,_stages,_investmentsNeed);
    }

    function changeDeadline(uint64 _id, uint _months)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator, "Not a creator");
        iToken USD = getUsd();      
        USD.transferFrom(msg.sender,Core.getDev(),(_months * payments[2]) * 10 ** USD.decimals());  
        if (project.stageDeadline > block.timestamp)
            project.stageDeadline += _months * 31 days;
        else 
            project.stageDeadline  = block.timestamp + (_months * 31 days);
        emit UpdateDeadline(_id,_months);        
    }

    function addIncome(uint64 _id, uint _usd, bool _creatorPie)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator || hasRole(MODERATOR,msg.sender), "Not a creator");
        iToken USD = getUsd();
        USD.transferFrom(msg.sender,project.projectBank,_usd * 10 ** USD.decimals());
        USD.transfer(Core.getDev(), ((_usd * 10 ** USD.decimals()) * project.pies[0]) / 100);
        uint totalUsd = _usd;
        if(_creatorPie){
            project.totalIncome += _usd;
        }
        else{ 
            totalUsd += _usd + (_usd * project.pies[1]/100);
            project.totalIncome += totalUsd;
        }
        emit AddIncome(_id,totalUsd);
    }

    function changeTitle(uint64 _id, string memory _title)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator, "Not a creator");
        iToken USD = getUsd();
        USD.transferFrom(msg.sender,Core.getDev(),payments[2] * 10 ** USD.decimals());  
        projects[_id].title = _title;
    }

    function changeDescription(uint64 _id, string memory _description)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator, "Not a creator");
        iToken USD = getUsd();
        USD.transferFrom(msg.sender,Core.getDev(),payments[2] * 10 ** USD.decimals());  
        projects[_id].description = _description;
    }

    function changeImage(uint64 _id, string memory _image)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator, "Not a creator");
        projects[_id].image = _image;
    }

    function addFiles(uint64 _id, string[] memory _files)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator, "Not a creator");
        for(uint8 i=0;i<_files.length;i++){
            project.files.push(_files[i]);
        }
    }

    function deleteFile(uint64 _id, uint8 _fileId)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator, "Not a creator");
        require(_fileId<project.files.length,'Wrong id');
        project.files[_fileId] = project.files[project.files.length-1];
        project.files.pop();
    }

    function unlockInvestments(uint64 _id)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator, "Not a creator");
        require(project.currentStage > 1, "You need to end investments stage");
        iToken USD = getUsd();
        uint usd = project.vestingPerStage[project.currentStage - 2] - project.unlockedInvestments;
        require(usd > 0 , "Nothing to withdraw");
        hiProjectBank(project.projectBank).sendIncome(project.creator, usd * 10 ** USD.decimals());
        project.unlockedInvestments += usd;
        emit UnlockInvestments(_id,usd);
    }

    function beginStageValidation(uint64 _id)external{
        Project storage project = projects[_id];
        require(msg.sender == project.creator, "Not a creator");
        stageVots[_id][project.currentStage].active = true;
    }

//MEMBER______________________________________________________________________________________________//
    function investInProject(uint64 _id, uint _usd)external{
        Project storage project = projects[_id];
        iToken USD = getUsd();
        iMembers Members = getMembers();
        require((project.currentStage) > 0 && (project.investmentsNeed > project.investmentsGet) && project.active, "You can't invest now");
        require(_usd > 9,"Must be at least 10$");
        if(project.investmentsGet + _usd > project.investmentsNeed)
            _usd = project.investmentsNeed - project.investmentsGet;
        uint64 memberId = Members.getMemberId(msg.sender);
        if(Members.getUSDinvestmentsIn(memberId,project.id)==0 && Members.getVOTSinvestmentsIn(memberId,project.id)==0)
            project.membersId.push(memberId);
        project.investmentsGet += _usd;
        Members.updateUSDinvestments(memberId,_id,_usd,true);
        USD.transferFrom(msg.sender,project.projectBank,_usd * 10 ** USD.decimals());
        emit Investment(memberId, _id, _usd);
    }


    function withdrawInvestments(uint64 _id, uint _usd)external{
        Project storage project = projects[_id];
        iMembers Members = getMembers();
        uint64 memberId = Members.getMemberId(msg.sender);
        require(_usd <= Members.getUSDinvestmentsIn(memberId, _id),"Not enough investments");
        require((project.currentStage < 2) || (!project.active), "You can't withdraw now");
        require(_usd > 9, "Minimal withdraw is 10$");
        iToken USD = getUsd();
        if(project.active){
            uint usdFee = _usd/10; //10% fee for withdraw
            hiProjectBank(project.projectBank).sendIncome(msg.sender,(_usd - usdFee) * 10 ** USD.decimals());
            hiProjectBank(project.projectBank).sendIncome(Core.getDev(),usdFee * 10 ** USD.decimals());
        } else {
            hiProjectBank(project.projectBank).sendIncome(msg.sender,_usd * 10 ** USD.decimals());         
        }
        project.investmentsGet -= _usd;
        Members.updateUSDinvestments(memberId,_id,_usd,false);
    }

    function votsForProject(uint64 _id, uint _vots)external{
        Project storage project = projects[_id];
        require(_vots > 0, "Must be more than 0 vots");
        require(project.active && (project.currentStage == 0), 'You cant vote for now');
        iToken Vots = getVots();
        iMembers Members = getMembers();
        Vots.transferFrom(msg.sender,project.projectBank,_vots * 10 ** Vots.decimals());
        uint64 memberId = Members.getMemberId(msg.sender);
        if(Members.getUSDinvestmentsIn(memberId,project.id)==0 && Members.getVOTSinvestmentsIn(memberId,project.id)==0)
            project.membersId.push(memberId);
        Members.updateVOTSinvestments(memberId,_id,_vots);
        emit VotsInvestment(memberId,_id,_vots); 
    }

    function votsForStage(uint64 _id, bool _up)external{
        Project storage project = projects[_id];
        iMembers Members = getMembers();
        uint64 memberId = Members.getMemberId(msg.sender);        
        require(Members.getUSDinvestmentsIn(memberId,project.id)>0 || Members.getVOTSinvestmentsIn(memberId,project.id)>0,"You are not the investor");
        require(stageVots[_id][project.currentStage].memberVots[memberId]<stageVots[_id][project.currentStage].round + 1,"already voted");
        require(stageVots[_id][project.currentStage].active,'Can`t vote for now');
        if(_up)
            stageVots[_id][project.currentStage].upDownVots[0]++;
        else
            stageVots[_id][project.currentStage].upDownVots[1]++;
        stageVots[_id][project.currentStage].memberVots[memberId]++; 
    }

    function withdrawIncome(uint64 _id)external returns(uint _income){
        Project storage project = projects[_id];
        iMembers Members= getMembers();
        iToken USD      = getUsd();
        uint64 memberId = Members.getMemberId(msg.sender);
        uint income     = (project.totalIncome - Members.getWithdrawnIncome(memberId,project.id)) * 10 ** USD.decimals();
        //usd investments        
        uint usdIn      = Members.getUSDinvestmentsIn(memberId,project.id) * 10 ** USD.decimals(); 
        uint usdPie;
        uint investPie  = income * project.pies[3]/100;
        if(usdIn > 0)
            usdPie      = project.investmentsNeed * 10 ** USD.decimals() / usdIn;       
        uint usdIncome;
        if(usdPie >0)
            usdIncome   = investPie / usdPie;
        //vots investments
        uint votsIn     = Members.getVOTSinvestmentsIn(memberId,project.id);
        uint membersPie = income * project.pies[2]/100; 
        uint votsPie;
        if(votsIn >0)
             votsPie    = project.totalVots  / votsIn;
        uint votsIncome; 
        if(votsPie>0)
            votsIncome  = (membersPie / votsPie) / 10000;
        //_______________________________________
        uint totalIncome = usdIncome + votsIncome;
        hiProjectBank(project.projectBank).sendIncome(msg.sender,(totalIncome));
        Members.updateWithdraw(memberId,_id,income,totalIncome);
        return(income);
    }
//MODERATOR___________________________________________________________________________________________//
    function nextStage(uint64 _id, uint8 _stage)external onlyRole(MODERATOR){
        Project storage project = projects[_id];
        require(_stage <= project.stages, "Wrong stage");
        project.currentStage = _stage;
        emit CurrentStage(_id, _stage);
    }

    function nextRound(uint64 _id,uint8 _round)external onlyRole(MODERATOR){
        Project storage project = projects[_id];
        stageVots[_id][project.currentStage].round = _round;
        emit CurrentRound(_id, _round);
    }

    function toggleStageValidation(uint64 _id)external onlyRole(MODERATOR){
        Project storage project = projects[_id];
        stageVots[_id][project.currentStage].active = !stageVots[_id][project.currentStage].active;
        emit StageActive(_id, stageVots[_id][project.currentStage].active);
    }

    function changeCategory(uint64 _id,uint16 _category)external onlyRole(MODERATOR){
        Project storage project = projects[_id];
        project.category = _category;
        emit ChangeCategory(_id, _category);
    }
//ADMIN_______________________________________________________________________________________________//
    function toggleProject(uint64 _id)external onlyRole(DEFAULT_ADMIN_ROLE){
        Project storage project = projects[_id];
        project.active = !project.active;
    }
    
    function increaseDeadline(uint64 _id, uint _months)external onlyRole(DEFAULT_ADMIN_ROLE){
        Project storage project = projects[_id];
        project.stageDeadline += _months * 31 days;
        emit UpdateDeadline(_id,_months);        
    }

    function updateCore(iCore _Core,uint64 _from, uint64 _to)external onlyRole(DEFAULT_ADMIN_ROLE){
        Core = _Core;
        for(uint64 i=_from; i<_to;i++){
            hiProjectBank bank = hiProjectBank(projects[i].projectBank);
            bank.updateCore(_Core);
        }
    }

    function updatePrice(uint[3] memory _payments)external onlyRole(DEFAULT_ADMIN_ROLE){
        payments = _payments;
    }
//VIEW_________________________________________________________________________________________________//
   function getProject(uint64 _id)public view returns(Project memory _project){
        _project = projects[_id];
    }

    function getCategory(uint64 _id)external view returns(string memory _category){
        _category = Core.getCategory(projects[_id].category);
    }

    function getFiles(uint64 _id)external view returns(string[] memory _files){
        _files = projects[_id].files;        
    }

    function getProjectMembers(uint64 _id)external view returns(uint _number, uint64[] memory _members){
        _members = projects[_id].membersId;
        _number  = projects[_id].membersId.length;
    }

    function getUpDownVots(uint64 _id, uint8 _stage)external view returns(uint[2] memory _upDownVots){
        _upDownVots = stageVots[_id][_stage].upDownVots;
    }

    function getMemberUpDownVots(uint64 _memberId,uint64 _id,uint8 _stage)external view returns(uint8 _upDownVots){
        _upDownVots = stageVots[_id][_stage].memberVots[_memberId];
    }


    function getStageStatus(uint64 _id, uint8 _stage)external view returns(bool _stageActive){
        _stageActive = stageVots[_id][_stage].active;    
    }

    function getProjects(uint64 _id, uint64 _amount)external view returns(Project[] memory _projects){
        if(_amount == 0)
           _amount  = id-_id;
        require(_id+_amount<=id,"Wrong ids");
        _projects = new Project[](_amount);
        for(uint64 i=_id; i<_amount+_id;i++){
            Project memory item = projects[_id];
            _projects[i] =  item;
        }
    }

    function getArrayProjects(uint64[] memory _ids)external view returns(Project[] memory _projects){
        _projects = new Project[](_ids.length);
        for(uint64 i=0; i<_ids.length;i++){
            Project memory item =  projects[_ids[i]];
            _projects[i] =  item;
        }
    }
//INTERNAL____________________________________________________________________________________________//
    function getMembers()internal view returns(iMembers Members) {
        Members = iMembers(Core.getMembers());
    }

    function getUsd()internal view returns(iToken Usd){
        Usd = iToken(Core.getUsd());
    } 

    function getVots()internal view returns(iToken Vots){
        Vots = iToken(Core.getVots());
    }  
}