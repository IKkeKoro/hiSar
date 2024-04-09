// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
interface iMembers {
    function registration(address _wallet) external;

    function updateSubscription(uint64 _id, uint8 _subLevel, uint _months) external;

    function updateRole(uint64 _id, uint8 _role) external; 

    function updateClaim(uint64 _id, uint _vots) external;

    function updateUSDinvestments(uint64 _id, uint64 _projectId, uint _usd, bool _increace) external;

    function updateVOTSinvestments(uint64 _id, uint64 _projectId, uint _vots) external;

    function updateWithdraw(uint64 _id, uint64 _projectId, uint _usd, uint _withdrawnAt) external;

    function updateRoles(string[] memory _roles) external; 
//____________________________________________________________________________________________________//
    function getMemberId(address _wallet) external view returns(uint64 _id);
    
    function getWallet(uint64 _id) external view returns(address _wallet);

    function getRole(uint64 _id) external view returns(string memory _role);

    function getAvatar(uint _id) external view returns(string memory _image);

    function getVerification(uint64 _id)external view returns(bool _verified);

    function getSubLevel(uint64 _id) external view returns(uint8 _subLevel);

    function getVotsClaimed(uint64 _id) external view returns(uint _votsClaimed);

    function getVotsUsed(uint64 _id) external view returns(uint _votsUsed);

    function getSubTime(uint64 _id) external view returns(uint _subTime);

    function getClaimTime(uint64 _id) external view returns(uint _claimTime);

    function getTotalInvestments(uint64 _id) external view returns(uint _usd);

    function getTotalWithdrawal(uint64 _id) external view returns(uint _usd);

    function getUSDinvestmentsIn(uint64 _id, uint64 _projectId) external view returns(uint _usd);

    function getVOTSinvestmentsIn(uint64 _id, uint64 _projectId) external view returns(uint _vots);

    function getWithdrawnIncome(uint64 _id, uint64 _projectId)external view returns(uint _usd);

    function getAllRoles() external view returns(string[] memory _roles);

    function getMyProjects(uint64 _id)external view returns(uint64[] memory _myProjects);
    
    function getAllVotsInvestments(uint64 _id)external view returns(uint64[] memory _votsInvestedIn);

    function getAllUsdInvestments(uint64 _id)external view returns(uint64[] memory _investedIn);

    function getId() external view returns(uint64 _id);
}