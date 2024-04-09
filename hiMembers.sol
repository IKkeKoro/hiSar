// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/iCore.sol";
//____________________________________________________________________________________________________//
contract hiMembers is AccessControl{
    struct Member{
        address wallet;
        string  username;
        string  image;
        bool    verified;

        uint8   subLevel;
        uint8   role;

        uint    votsClaimed;
        uint    votsUsed;

        uint    subTime;
        uint    claimTime;

        uint    invested;
        uint    withdrawn;
    }
    mapping (uint64  => Member)   member;
    mapping (address => uint64)   memberId;
    mapping (uint64  => uint64[]) myProjects;

    mapping (uint64  => mapping (uint64 => uint)) USDinvestments;
    mapping (uint64  => mapping (uint64 => uint)) VOTSinvestments;
    mapping (uint64  => mapping (uint64 => uint)) withdrawnIncomeAt;
    mapping (uint64  => uint64[]) votsInvestedIn;
    mapping (uint64  => uint64[]) investedIn;

    string[] roles;
    bytes32  ADMIN;
    bytes32  MODERATOR;

    iCore    Core;
    uint64   id; 
    
    event WithdrawInvestments(address  member,uint64 projectId,uint usd);
    event UsdInvestments (address  member,uint64 projectId,uint usd);
    event VotsInvestments(address member,uint64 projectId,uint vots);
    event Subscription(address member, uint8 subLevel, uint subTime);
    event Registration(address member, uint64 id);
    event NewRole (address member, string role);    
    event Withdraw(address member, uint usd);
    event Claim  (address member, uint vots);
//____________________________________________________________________________________________________//
    constructor(){
        id++;
        ADMIN = bytes32(bytes("Admin"));
        MODERATOR = bytes32(bytes("Moderator"));
        roles = ["Noname","Member","Moderator","Admin"];
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        _grantRole(ADMIN,msg.sender);
        _grantRole(MODERATOR,msg.sender);
        memberId[msg.sender] = id;
        member[id] = Member(
            msg.sender,
            "IKke",
            "",
            true,
            3,2,0,0,
            block.timestamp + 420 days,
            block.timestamp,
            0,0
        );
    }
//ADMIN_______________________________________________________________________________________________//
    function registration(address _wallet)external onlyRole(ADMIN){
        require(msg.sender != address(0),  "Zero address");
        require(!isContract(_wallet) || _wallet == Core.getPot(),"Not a wallet");
        member[id].wallet    = _wallet;
        member[id].claimTime = block.timestamp;
        emit Registration(_wallet,id);
        id++;
    }

    function updateSubscription(uint64 _id, uint8 _subLevel, uint _months)external onlyRole(ADMIN){
        require(member[_id].claimTime > 0, "Member is not registered yet");
        uint _subTime;
        if (_subLevel == member[_id].subLevel  && member[_id].subTime > 0) 
            _subTime   =  member[_id].subTime + (_months * 31 days);
        else
            _subTime = block.timestamp + (_months * 31 days); 
        member[_id].subLevel = _subLevel;
        member[_id].subTime  = _subTime;
        emit Subscription(member[_id].wallet, _subLevel, _subTime);
    } 

    function updateRole(uint64 _id, uint8 _role)external onlyRole(ADMIN){
        require(member[_id].claimTime > 0, "Member is not registered yet");
        require(_role < roles.length, "There is no such role");
        emit NewRole(member[_id].wallet, roles[_role]);
        member[_id].role = _role;
    }

    function updateVerification(uint64 _id, bool _verified)external onlyRole(MODERATOR){
        member[_id].verified = _verified;
    }

    function updateClaim(uint64 _id, uint _vots)external onlyRole(ADMIN){
        require(member[_id].claimTime > 0, "Member is not registered yet");
        member[_id].claimTime = block.timestamp;
        member[_id].votsClaimed += _vots; 
        emit Claim(member[_id].wallet, _vots);
    }

    function updateUSDinvestments(uint64 _id, uint64 _projectId, uint _usd, bool _increace)external onlyRole(ADMIN){
        require(member[_id].claimTime > 0, "Member is not registered yet");
        if(_increace){
            if(USDinvestments[_id][_projectId] == 0)
                investedIn[_id].push(_projectId);
            USDinvestments[_id][_projectId] += _usd; 
            member[_id].invested += _usd;
            emit UsdInvestments(member[_id].wallet, _projectId, _usd);
        } else {
            USDinvestments[_id][_projectId] -= _usd; 
            member[_id].invested -= _usd;
            emit WithdrawInvestments(member[_id].wallet, _projectId, _usd);      
        }
    }

    function updateVOTSinvestments(uint64 _id, uint64 _projectId, uint _vots)external onlyRole(ADMIN){
        require(member[_id].claimTime > 0, "Member is not registered yet");
        if(VOTSinvestments[_id][_projectId] == 0)
            votsInvestedIn[_id].push(_projectId);
        VOTSinvestments[_id][_projectId] += _vots;   
        member[_id].votsUsed += _vots; 
        emit VotsInvestments(member[_id].wallet, _projectId, _vots);   
    }

    function updateWithdraw(uint64 _id, uint64 _projectId, uint _usd, uint _withdrawnAt)external onlyRole(ADMIN){
        require(member[_id].claimTime > 0, "Member is not registered yet");
        require(_usd > 0, "Nothing to withdraw");
        member[_id].withdrawn += _usd;
        withdrawnIncomeAt[_id][_projectId] = _withdrawnAt;
        emit Withdraw(member[_id].wallet, _usd);
    }

    function updateProjects(uint64 _id, uint64 _projectId)external onlyRole(ADMIN){
        myProjects[_id].push(_projectId);
    }

    function updateRoles(string[] memory _roles)external onlyRole(DEFAULT_ADMIN_ROLE){
        roles = _roles;
    }

    function updateCore(iCore _Core)external onlyRole(DEFAULT_ADMIN_ROLE){
        Core = _Core;
    }
//USER_________________________________________________________________________________________________//
    function changeName(string memory _username) external{
        require(memberId[msg.sender] >0, "You are not registered yet");
        member[memberId[msg.sender]].username = _username;
    }

    function changeAvatar(string memory _image) external{
        require(memberId[msg.sender] >0, "You are not registered yet");
        member[memberId[msg.sender]].image = _image;
    }

//VIEW_________________________________________________________________________________________________//
    function getMember(uint64 _id)external view returns(Member memory _member){
        _member = member[_id];
    }

    function getUsername(uint64 _id)external view returns(string memory _username){
        _username = member[_id].username;
    }

    function getAvatar(uint64 _id)external view returns(string memory _avatar){
        _avatar = member[_id].image;
    }

    function getVerification(uint64 _id)external view returns(bool _verified){
        _verified = member[_id].verified;
    }
    
    function getMemberId(address _wallet)external view returns(uint64 _id){
        _id = memberId[_wallet];
    }
    
    function getWallet(uint64 _id)external view returns(address _wallet){
        _wallet = member[_id].wallet;
    }

    function getRole(uint64 _id)external view returns(string memory _role){
        _role = roles[member[_id].role];
    }

    function getSubLevel(uint64 _id)external view returns(uint8 _subLevel){
        _subLevel = member[_id].subLevel;
    }

    function getVotsClaimed(uint64 _id)external view returns(uint _votsClaimed){
        _votsClaimed = member[_id].votsClaimed;
    }

    function getVotsUsed(uint64 _id)external view returns(uint _votsUsed){
        _votsUsed = member[_id].votsUsed;
    }

    function getSubTime(uint64 _id)external view returns(uint _subTime){
        _subTime = member[_id].subTime;
    }

    function getClaimTime(uint64 _id)external view returns(uint _claimTime){
        _claimTime = member[_id].claimTime;
    }

    function getTotalInvestments(uint64 _id)external view returns(uint _usd){
        _usd = member[_id].invested;
    }

    function getTotalWithdrawal(uint64 _id)external view returns(uint _usd){
        _usd = member[_id].withdrawn;
    }

    function getUSDinvestmentsIn(uint64 _id, uint64 _projectId)external view returns(uint _usd){
        _usd = USDinvestments[_id][_projectId];
    }

    function getVOTSinvestmentsIn(uint64 _id, uint64 _projectId)external view returns(uint _vots){
        _vots = VOTSinvestments[_id][_projectId];
    }

    function getWithdrawnIncome(uint64 _id, uint64 _projectId)external view returns(uint _usd){
        _usd = withdrawnIncomeAt[_id][_projectId];
    }

    function getMyProjects(uint64 _id)external view returns(uint64[] memory _myProjects){
        _myProjects = myProjects[_id];
    }

    function getAllVotsInvestments(uint64 _id)external view returns(uint64[] memory _votsInvestedIn){
        _votsInvestedIn = votsInvestedIn[_id];
    }

    function getAllUsdInvestments(uint64 _id)external view returns(uint64[] memory _investedIn){
        _investedIn = investedIn[_id];
    }

    function getAllRoles()external view returns(string[] memory _roles){
        _roles = roles;
    }

    function getCore()external view returns(iCore _Core){
        _Core = Core;
    }

    function getId()external view returns(uint64 _id){
        _id = id;
    }

    function getMembers(uint64 _id, uint64 _amount)external view returns(Member[] memory _members){
        if(_amount == 0)
           _amount  = id-_id;
        require(_id+_amount<=id,"Wrong ids");
        _members = new Member[](_amount);
        for(uint64 i=_id; i<_amount+_id;i++){
            Member memory item = member[i];
            _members[i] = item;
        }
    }

    function getArrayMembers(uint64[] memory _ids)external view returns(Member[] memory _members){
        _members = new Member[](_ids.length);
        for(uint64 i=0; i<_ids.length;i++){
            Member memory item = member[_ids[i]];
            _members[i] =  item;
        }
    }
//INTERNAL____________________________________________________________________________________________//
    function isContract(address _address)private view returns(bool _isContract){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
//____________________________________________________________________________________________________//
}