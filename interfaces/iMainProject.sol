// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
interface iMainProject {
    function investInProject(uint64 _id, uint _usd)external;

    function withdrawIncome(uint64 _id)external returns(uint _income);
}