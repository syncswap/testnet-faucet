// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ERC20TestToken.sol";
import "./interfaces/IERC677.sol";
import "./interfaces/IERC677Receiver.sol";

contract ERC677TestToken is IERC677, ERC20TestToken {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address _faucet
    ) ERC20TestToken(name, symbol, decimals, _faucet) {}

    /**
     * @dev transfer token to a specified address.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value)
        public
        override(IERC20, ERC20Standard)
        validRecipient(_to)
        returns (bool success)
    {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value)
        public
        override(IERC20, ERC20Standard)
        validRecipient(_spender)
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        override(IERC20, ERC20Standard)
        validRecipient(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this));
        _;
    }

    /**
     * @dev transfer token to a contract address with additional data if the recipient is a contact.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @param _data The extra data to be passed to the receiving contract.
     */
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public override returns (bool success) {
        super.transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        _contractFallback(_to, _value, _data);
        return true;
    }

    function _contractFallback(
        address _to,
        uint256 _value,
        bytes memory _data
    ) private {
        IERC677Receiver receiver = IERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }
}
