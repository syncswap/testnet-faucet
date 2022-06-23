import { BigNumber, Contract } from 'ethers';
import {
    defaultAbiCoder,
    keccak256,
    solidityPack,
    toUtf8Bytes
} from 'ethers/lib/utils';
import { Provider, Web3Provider } from 'zksync-web3';
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

export async function deployFaucet(): Promise<Contract> {
    const Faucet = await hre.ethers.getContractFactory('Faucet');
    const faucet = await Faucet.deploy();
    await faucet.deployed();
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