// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './libraries/Ownable.sol';
import './tokens/ERC20TestToken.sol';
import './tokens/ERC677TestToken.sol';
import './tokens/ERC20TestTokenWithPermit.sol';
import './tokens/interfaces/IMintable.sol';

contract Faucet is Ownable {

    mapping(address => bool) operators;

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
        IMintable frax = new ERC20TestTokenWithPermit('Frax', 'FRAX', 18, address(this));
        _addDrip(address(frax), 10000 * 1e18);

        IMintable usdt = new ERC20TestToken('Tether USD', 'USDT', 6, address(this));
        _addDrip(address(usdt), 10000 * 1e6);

        IMintable busd = new ERC20TestToken('Binance USD', 'BUSD', 18, address(this));
        _addDrip(address(busd), 10000 * 1e18);

        IMintable slp = new ERC20TestToken('Smooth Love Potion', 'SLP', 0, address(this));
        _addDrip(address(slp), 5000000);

        IMintable crv = new ERC20TestToken('Curve DAO Token', 'CRV', 18, address(this));
        _addDrip(address(crv), 50000 * 1e18);

        IMintable sync = new ERC20TestTokenWithPermit('SyncSwap', 'SYNC', 18, address(this));
        _addDrip(address(sync), 1000 * 1e18);

        IMintable mltt = new ERC677TestToken('Matter Labs Trial Token', 'MLTT', 10, address(this));
        _addDrip(address(mltt), 1000000 * 1e10);

        IMintable shib = new ERC677TestToken('Shiba Inu', 'SHIB', 18, address(this));
        _addDrip(address(shib), 5000000000 * 1e18);

        IMintable renbtc = new ERC20TestToken('renBTC', 'renBTC', 8, address(this));
        _addDrip(address(renbtc), 1e8);
    }

    function allDrips() external view returns (Drip[] memory) {
        return drips;
    }

    function dripsLength() external view returns (uint256) {
        return drips.length;
    }

    function isOperator(address account) public view returns (bool) {
        return account == owner() || operators[account];
    }

    modifier onlyOperators() {
        require(isOperator(msg.sender), "Not operator");
        _;
    }

    function setOperator(address account, bool status) external onlyOwner {
        operators[account] = status;
    }

    function _addDrip(address token, uint256 amount) internal {
        drips.push(Drip(token, amount));
    }

    function addDrip(address token, uint256 amount) external onlyOperators {
        require(token != address(0), "Invalid token");
        require(amount != 0, "Invalid amount");
        _addDrip(token, amount);
    }

    function claim(uint256 dripId) external {
        require(dripId < drips.length, "Drip not exists");

        if (!isOperator(msg.sender)) {
            require(!hasDripClaimed[dripId][msg.sender], "Drip already claimed");
            hasDripClaimed[dripId][msg.sender] = true;
        }

        Drip memory drip = drips[dripId];
        IMintable(drip.token).mint(msg.sender, drip.amount);
    }

    function claimMany(uint256[] memory dripIds) external {
        uint256 _dripsLength = drips.length;
        bool _isOperator = isOperator(msg.sender);

        for (uint256 i = 0; i < dripIds.length; ) {
            uint256 dripId = dripIds[i];
            require(dripId < _dripsLength, "Drip not exists");

            if (!_isOperator) {
                if (hasDripClaimed[dripId][msg.sender]) {
                    continue;
                } else {
                    hasDripClaimed[dripId][msg.sender] = true;
                }
            }

            Drip memory drip = drips[dripId];
            IMintable(drip.token).mint(msg.sender, drip.amount);

            unchecked {
                ++i;
            }
        }
    }

    function claimAll() external {
        uint256 _dripsLength = drips.length;
        bool _isOperator = isOperator(msg.sender);

        for (uint256 i = 0; i < _dripsLength; ) {
            if (!_isOperator) {
                if (hasDripClaimed[i][msg.sender]) {
                    continue;
                } else {
                    hasDripClaimed[i][msg.sender] = true;
                }
            }

            Drip memory drip = drips[i];
            IMintable(drip.token).mint(msg.sender, drip.amount);

            unchecked {
                ++i;
            }
        }
    }
}