// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './Ownable.sol';

abstract contract Operators is Ownable {
    mapping(address => bool) public operators;

    /**
     * @dev Throws if called by any account other than operator.
     */
    modifier onlyOperators() {
        require(isOperator(msg.sender), "Operators: Caller is not an operator");
        _;
    }

    /**
     * @dev Returns whether the account is operator or owner.
     */
    function isOperator(address account) public view virtual returns (bool) {
        return operators[account] || account == owner();
    }

    /**
     * @dev Sets operator permission for given account.
     */
    function setOperator(address account, bool status) public virtual onlyOwner {
        operators[account] = status;
    }
}