// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ERC20TestToken.sol";
import "../libraries/ECDSA.sol";
import "./interfaces/IERC20Permit.sol";

contract ERC20TestTokenWithPermit is IERC20Permit, ERC20TestToken {
    mapping(address => uint256) private _nonces;
    bytes32 private immutable _DOMAIN_SEPARATOR;
    // "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address _faucet
    ) ERC20TestToken(name, symbol, decimals, _faucet) {
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                //keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,

                keccak256(bytes(name)),

                //keccak256(bytes("1")),
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,
                
                280, // hardcode because block.chainid is unsupported in zkSync
                address(this)
            )
        );
    }

    function nonces(address owner) external view override returns (uint256) {
        return _nonces[owner];
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline, "EXPIRED");

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = ECDSA.toTypedDataHash(_DOMAIN_SEPARATOR, structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "INVALID_SIGNATURE");

        _approve(owner, spender, value);
    }
}
