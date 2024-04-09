// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
interface iCore {
    function getDao() external view returns(address _dao);

    function getVots() external view returns(address _vots);

    function getProjects() external view returns(address _projects);

    function getMembers() external view returns(address _members);

    function getDonations()external view returns(address _donations);

    function getUsd() external view returns(address _usd);

    function getPot() external view returns(address _pot);

    function getFund() external view returns(address _fund);

    function getDev()external view returns(address _dev);

    function getCategory(uint16 _id)external view returns(string memory _category);
}