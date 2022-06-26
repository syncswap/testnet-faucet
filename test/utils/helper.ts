import { BigNumber, Contract } from 'ethers';
import {
    defaultAbiCoder,
    keccak256,
    solidityPack,
    toUtf8Bytes
} from 'ethers/lib/utils';
import { Constants } from './constants';

const hre = require("hardhat");

export function expandTo18Decimals(n: number): BigNumber {
    return BigNumber.from(n).mul(BigNumber.from(10).pow(18));
}

export function getDomainSeparator(name: string, tokenAddress: string) {
    return keccak256(
        defaultAbiCoder.encode(
            ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
            [
                keccak256(toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')),
                keccak256(toUtf8Bytes(name)),
                keccak256(toUtf8Bytes('1')),
                Constants.CHAIN_ID,
                tokenAddress
            ]
        )
    )
}

export async function getApprovalDigest(
    token: Contract,
    approve: {
        owner: string
        spender: string
        value: BigNumber
    },
    nonce: BigNumber,
    deadline: BigNumber
): Promise<string> {
    const name = await token.name()
    const DOMAIN_SEPARATOR = getDomainSeparator(name, token.address)
    return keccak256(
        solidityPack(
            ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
            [
                '0x19',
                '0x01',
                DOMAIN_SEPARATOR,
                keccak256(
                    defaultAbiCoder.encode(
                        ['bytes32', 'address', 'address', 'uint256', 'uint256', 'uint256'],
                        [Constants.PERMIT_TYPEHASH, approve.owner, approve.spender, approve.value, nonce, deadline]
                    )
                )
            ]
        )
    )
}

export function encodePrice(reserve0: BigNumber, reserve1: BigNumber) {
    return [reserve1.mul(BigNumber.from(2).pow(112)).div(reserve0), reserve0.mul(BigNumber.from(2).pow(112)).div(reserve1)]
}

export async function deployAndInitializeFaucet(): Promise<Contract> {
    const Faucet = await hre.ethers.getContractFactory('Faucet');
    const faucet = await Faucet.deploy();
    await faucet.deployed();

    await createTokenAndAddDrip(faucet, TokenType.ERC20_WITH_PERMIT, 'Frax', 'FRAX', 18, 5000);
    await createTokenAndAddDrip(faucet, TokenType.ERC20, 'Tether USD', 'USDT', 6, 5000);
    await createTokenAndAddDrip(faucet, TokenType.ERC20, 'Binance USD', 'BUSD', 18, 5000);
    await createTokenAndAddDrip(faucet, TokenType.ERC20, 'Smooth Love Potion', 'SLP', 0, 5000000);
    await createTokenAndAddDrip(faucet, TokenType.ERC20, 'Curve DAO Token', 'CRV', 18, 6000);
    await createTokenAndAddDrip(faucet, TokenType.ERC20_WITH_PERMIT, 'Testnet Token', 'TEST', 18, 10000);
    await createTokenAndAddDrip(faucet, TokenType.ERC677, 'Matter Labs Trial Token', 'MLTT', 10, 500);
    await createTokenAndAddDrip(faucet, TokenType.ERC677, 'Shiba Inu', 'SHIB', 18, 500000000);
    await createTokenAndAddDrip(faucet, TokenType.ERC20_WITH_PERMIT, 'renBTC', 'renBTC', 8, 1);
    await createTokenAndAddDrip(faucet, TokenType.ERC20, 'Lido Staked Ether', 'stETH', 18, 5);
    await createTokenAndAddDrip(faucet, TokenType.ERC20, 'Aave', 'AAVE', 18, 70);
    await createTokenAndAddDrip(faucet, TokenType.ERC20_WITH_PERMIT, 'Maker', 'MKR', 18, 5);

    return faucet;
}

export async function deployERC20TestToken(name: string, symbol: string, decimals: number, faucet: string): Promise<Contract> {
    const ERC20TestToken = await hre.ethers.getContractFactory('ERC20TestToken');
    const token = await ERC20TestToken.deploy(name, symbol, decimals, faucet);
    await token.deployed();
    return token;
}

export async function mineBlock(): Promise<void> {
    await hre.network.provider.send("hardhat_mine");
}

export async function mineBlockAfter(seconds: number): Promise<void> {
    await setTimeout(await hre.network.provider.send("hardhat_mine"), seconds * 1000);
}

enum TokenType {
    ERC20 = 'ERC20TestToken',
    ERC20_WITH_PERMIT = 'ERC20TestTokenWithPermit',
    ERC677 = 'ERC677TestToken'
}

export async function createTokenAndAddDrip(faucet: Contract, type: TokenType, name: string, symbol: string, decimals: number, dripAmount: number) {
    const contractFactory = await hre.ethers.getContractFactory(type);
    const token = await contractFactory.deploy(name, symbol, decimals, faucet.address);
    await token.deployed();

    const response = await faucet.addDrip(token.address, BigNumber.from(10).pow(decimals).mul(dripAmount)); // expandToDecimals
    await response.wait();

    return token;
}