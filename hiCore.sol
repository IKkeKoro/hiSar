// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./interfaces/iMembers.sol";
import "./interfaces/iToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
//____________________________________________________________________________________________________//
contract hiCore is AccessControl{
    address VOTScontract;
    address MEMBERScontract;
    address PROJECTScontract;
    address DONATIONScontract;

    address DEVcontract;
    address USDcontract;

    address FUNDpool;
    address POTpool;
    constructor(){
        DEVcontract = msg.sender;
       _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }
    mapping (uint16 => string) category;
//ADMIN_______________________________________________________________________________________________//
    function updateVots(address _vots)external onlyRole(DEFAULT_ADMIN_ROLE){
        VOTScontract = _vots;
    }

    function updateProjects(address _projects)external onlyRole(DEFAULT_ADMIN_ROLE){
        PROJECTScontract = _projects;
    }

    function updateMembers(address _members)external onlyRole(DEFAULT_ADMIN_ROLE){
        MEMBERScontract = _members;
    }

    function updateUsd(address _usd)external onlyRole(DEFAULT_ADMIN_ROLE){
        USDcontract = _usd;
    }

    function updatePot(address _pot)external onlyRole(DEFAULT_ADMIN_ROLE){
        POTpool = _pot;
    }

    function updateFund(address _fund)external onlyRole(DEFAULT_ADMIN_ROLE){
        FUNDpool = _fund;
    }

    function updateDev(address _dev)external onlyRole(DEFAULT_ADMIN_ROLE){
        DEVcontract = _dev;
    }

    function updateCategory(uint16 _id, string memory _category)external onlyRole(DEFAULT_ADMIN_ROLE){
        category[_id] = _category;
    }
//VIEW________________________________________________________________________________________________//
    function getVots()external view returns(address _vots){
        _vots = VOTScontract;
    }

    function getProjects()external view returns(address _projects){
        _projects = PROJECTScontract;
    }

    function getMembers()external view returns(address _members){
        _members = MEMBERScontract;
    }

    function getDonations()external view returns(address _donations){
        _donations = DONATIONScontract;
    }

    function getUsd()external view returns(address _usd){
        _usd = USDcontract;
    }

    function getPot()external view returns(address _pot){
        _pot = POTpool;
    }

    function getFund()external view returns(address _fund){
        _fund = FUNDpool;
    }

    function getDev()external view returns(address _dev){
        _dev = DEVcontract;
    }

    function getCategory(uint16 _id)external view returns(string memory _category){
        _category = category[_id];
    }

    function getCategories(uint16 _amount)external view returns(string[] memory _category){
        for(uint16 i=0;i<_amount;i++){
            _category[i] = category[i];
        }
        
    }
//____________________________________________________________________________________________________//
}