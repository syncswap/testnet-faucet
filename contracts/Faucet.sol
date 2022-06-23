// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './libraries/Operators.sol';
import './tokens/ERC20TestToken.sol';
import './tokens/ERC677TestToken.sol';
import './tokens/ERC20TestTokenWithPermit.sol';
import './tokens/interfaces/IMintable.sol';

contract Faucet is Operators {

    /// @dev Drip info.
    struct Drip {
        /// @dev Whether the drip is available for claim.
        bool active;

        /// @dev Address of the token to drip.
        address token;

        /// @dev Amount of the drip token.
        uint256 amount;
    }

    /**
     * @dev All drips.
     */
    Drip[] public drips;

    /**
     * @dev Whether the drip has been claimed by the account.
     */
    mapping(uint256 => mapping(address => bool)) public hasDripClaimed;

    /**
     * @dev Initializes the contract and default drips.
     */
    constructor() {
        _initialize();
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initialize default test tokens and drips (12).
     */
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

    function _addDrip(address _token, uint256 _amount) internal {
        Drip memory _drip = Drip({
            active: true,
            token: _token,
            amount: _amount
        });
        drips.push(_drip);
    }

    /*//////////////////////////////////////////////////////////////
        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns all drips.
     */
    function allDrips() external view returns (Drip[] memory) {
        return drips;
    }

    /**
     * @dev Returns length of all drips.
     */
    function dripsLength() external view returns (uint256) {
        return drips.length;
    }

    /// @dev Status of drip (0-3).
    enum DripStatus {
        AVAILABLE,
        SUSPENDED,
        CLAIMED,
        SUSPENDED_AND_CLAIMED
    }

    /**
     * @dev Returns status of all drips as of given account.
     */
    function getDripStatus(address account) external view returns (DripStatus[] memory status) {
        uint256 _dripsLength = drips.length;
        status = new DripStatus[](_dripsLength);

        for (uint256 i = 0; i < _dripsLength; ) {
            bool _isActive = drips[i].active;
            bool _hasClaimed = hasDripClaimed[i][account];

            if (_isActive) {
                status[i] = (_hasClaimed ? DripStatus.CLAIMED : DripStatus.AVAILABLE);
            } else {
                status[i] = (_hasClaimed ? DripStatus.SUSPENDED_AND_CLAIMED : DripStatus.SUSPENDED);
            }

            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Adds a drip.
     */
    function addDrip(address _token, uint256 _amount) external onlyOperators {
        require(_token != address(0), "Invalid token");
        require(_amount != 0, "Invalid amount");
        _addDrip(_token, _amount);
    }

    /**
     * @dev Sets whether a drip is available for claim.
     */
    function setDripActive(uint256 _dripId, bool _active) external onlyOperators {
        require(_dripId < drips.length, "Drip not exists");
        drips[_dripId].active = _active;
    }

    /**
     * @dev Mint test token and send to recipient.
     */
    function mint(address _token, uint256 _amount, address _to) external onlyOperators {
        IMintable(_token).mint(_to, _amount);
    }

    /*//////////////////////////////////////////////////////////////
        USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Claims a drip by its id.
     *
     * Note it will reverts if drip has already claimed.
     */
    function claim(uint256 _dripId) external {
        require(_dripId < drips.length, "Drip not exists");

        Drip memory _drip = drips[_dripId];

        // Reverts if drip is not active.
        require(_drip.active, "Drip is not active");

        // Reverts if drip has already claimed by caller.
        require(!hasDripClaimed[_dripId][msg.sender], "Drip already claimed");

        hasDripClaimed[_dripId][msg.sender] = true;
        IMintable(_drip.token).mint(msg.sender, _drip.amount);
    }

    /**
     * @dev Claim many drips by their ids.
     *
     * Note drips that are already claimed will be skipped.
     */
    function claimMany(uint256[] memory _dripsToClaim) external {
        uint256 _dripsLength = drips.length;

        for (uint256 i = 0; i < _dripsToClaim.length; ) {
            uint256 _dripId = _dripsToClaim[i];
            require(_dripId < _dripsLength, "Drip not exists");

            Drip memory _drip = drips[_dripId];

            // Skips if drip is not active.
            if (!_drip.active) {
                unchecked {
                    ++i;
                }
                continue;
            }

            // Skips if drip has already claimed by caller.
            if (hasDripClaimed[_dripId][msg.sender]) {
                unchecked {
                    ++i;
                }
                continue;
            }

            hasDripClaimed[_dripId][msg.sender] = true;
            IMintable(_drip.token).mint(msg.sender, _drip.amount);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Claim all created drips.
     *
     * Note drips that are already claimed will be skipped without reverts.
     */
    function claimAll() external {
        uint256 _dripsLength = drips.length;

        for (uint256 i = 0; i < _dripsLength; ) {
            Drip memory _drip = drips[i];

            // Skips if drip is not active (or not exists).
            if (!_drip.active) {
                unchecked {
                    ++i;
                }
                continue;
            }

            // Skips if drip has already claimed by caller.
            if (hasDripClaimed[i][msg.sender]) {
                unchecked {
                    ++i;
                }
                continue;
            }

            hasDripClaimed[i][msg.sender] = true;
            IMintable(_drip.token).mint(msg.sender, _drip.amount);

            unchecked {
                ++i;
            }
        }
    }
}