// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './libraries/Operators.sol';
import './tokens/ERC20TestToken.sol';
import './tokens/ERC677TestToken.sol';
import './tokens/ERC20TestTokenWithPermit.sol';
import './tokens/interfaces/IMintable.sol';

contract Faucet is Operators {

    struct Drip {
        address token;
        uint256 amount;
    }

    Drip[] public drips;

    mapping(uint256 => mapping(address => bool)) hasDripClaimed;

    constructor() {
        _initialize();
    }

    function _initialize() internal {
        IMintable FRAX = new ERC20TestTokenWithPermit('Frax', 'FRAX', 18, address(this));
        _addDrip(address(FRAX), 5000 * 1e18);

        IMintable USDT = new ERC20TestToken('Tether USD', 'USDT', 6, address(this));
        _addDrip(address(USDT), 5000 * 1e6);

        IMintable BUSD = new ERC20TestToken('Binance USD', 'BUSD', 18, address(this));
        _addDrip(address(BUSD), 5000 * 1e18);

        IMintable SLP = new ERC20TestToken('Smooth Love Potion', 'SLP', 0, address(this));
        _addDrip(address(SLP), 5000000);

        IMintable CRV = new ERC20TestToken('Curve DAO Token', 'CRV', 18, address(this));
        _addDrip(address(CRV), 6000 * 1e18);

        IMintable SYNC = new ERC20TestTokenWithPermit('SyncSwap', 'SYNC', 18, address(this));
        _addDrip(address(SYNC), 10000 * 1e18);

        IMintable MLTT = new ERC677TestToken('Matter Labs Trial Token', 'MLTT', 10, address(this));
        _addDrip(address(MLTT), 500 * 1e10);

        IMintable SHIB = new ERC677TestToken('Shiba Inu', 'SHIB', 18, address(this));
        _addDrip(address(SHIB), 500000000 * 1e18);

        IMintable renBTC = new ERC20TestToken('renBTC', 'renBTC', 8, address(this));
        _addDrip(address(renBTC), 25e7); // 0.25

        IMintable stETH = new ERC20TestToken('Lido Staked Ether', 'stETH', 18, address(this));
        _addDrip(address(stETH), 5 * 1e18);

        IMintable AAVE = new ERC20TestToken('Aave', 'AAVE', 18, address(this));
        _addDrip(address(AAVE), 70 * 1e18);

        IMintable MKR = new ERC20TestToken('Maker', 'MKR', 18, address(this));
        _addDrip(address(MKR), 5 * 1e18);
    }

    function allDrips() external view returns (Drip[] memory) {
        return drips;
    }

    function dripsLength() external view returns (uint256) {
        return drips.length;
    }

    function _addDrip(address token, uint256 amount) internal {
        drips.push(Drip(token, amount));
    }

    function addDrip(address token, uint256 amount) external onlyOperators {
        require(token != address(0), "Invalid token");
        require(amount != 0, "Invalid amount");
        _addDrip(token, amount);
    }

    function claim(uint256 _dripId) external {
        require(_dripId < drips.length, "Drip not exists");
        require(!hasDripClaimed[_dripId][msg.sender], "Drip already claimed");

        hasDripClaimed[_dripId][msg.sender] = true;

        Drip memory _drip = drips[_dripId];
        IMintable(_drip.token).mint(msg.sender, _drip.amount);
    }

    function claimMany(uint256[] memory _dripsToClaim) external {
        uint256 _dripsLength = drips.length;

        for (uint256 i = 0; i < _dripsToClaim.length; ) {
            uint256 _dripId = _dripsToClaim[i];
            require(_dripId < _dripsLength, "Drip not exists");

            if (hasDripClaimed[_dripId][msg.sender]) {
                continue;
            } else {
                hasDripClaimed[_dripId][msg.sender] = true;
            }

            Drip memory _drip = drips[_dripId];
            IMintable(_drip.token).mint(msg.sender, _drip.amount);

            unchecked {
                ++i;
            }
        }
    }

    function claimAll() external {
        uint256 _dripsLength = drips.length;

        for (uint256 i = 0; i < _dripsLength; ) {
            if (hasDripClaimed[i][msg.sender]) {
                continue;
            } else {
                hasDripClaimed[i][msg.sender] = true;
            }
            
            Drip memory _drip = drips[i];
            IMintable(_drip.token).mint(msg.sender, _drip.amount);

            unchecked {
                ++i;
            }
        }
    }
}