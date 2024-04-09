// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
interface iToken {

    function mint(address to,uint id) external;

    function burn(uint amount) external;

    function transferFrom(address from,address to,uint amount) external;

    function transfer(address to,uint amount) external;

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);
//VOTS_________________________________________________________________
    function getBurned() external view returns(uint _burned);  
}