// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ERC20Standard.sol";
import "./interfaces/IMintable.sol";

contract ERC20TestToken is IMintable, ERC20Standard {
    address public immutable override faucet;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address _faucet
    ) ERC20Standard(name, symbol, decimals) {
        faucet = _faucet;
    }

    function mint(address to, uint256 value) external override {
        require(msg.sender == faucet, "Not faucet");
        _mint(to, value);
    }
}
