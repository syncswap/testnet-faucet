// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IMintable {
    function faucet() external view returns (address);
    function mint(address to, uint256 value) external;
}