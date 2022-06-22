// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

interface IERC677 is IERC20, IERC20Metadata {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );

    function transferAndCall(
        address,
        uint256,
        bytes memory
    ) external returns (bool);
}