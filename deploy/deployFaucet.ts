import { utils, Wallet } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

import * as secrets from "../secrets.json";

const feeToken: string | undefined = '';

let deployer: Deployer;
let faucet: ethers.Contract;

enum TokenType {
    ERC20 = 'ERC20TestToken',
    ERC20_WITH_PERMIT = 'ERC20TestTokenWithPermit',
    ERC677 = 'ERC677TestToken'
}

async function createTokenAndAddDrip(type: TokenType, name: string, symbol: string, decimals: number, dripAmount: number) {
    console.log(`Deploying ${name} (${symbol}) as decimals ${decimals} and type ${type}`);
    const artifact = await deployer.loadArtifact(type);
    const token = await deployer.deploy(artifact, [name, symbol, decimals, faucet.address], feeToken ? {
        feeToken: feeToken
    } : undefined);

    await token.deployed();
    console.log(`Token ${symbol} has been successfully deployed to ${token.address}.`);

    console.log(`Adding drip for ${symbol} (amount ${dripAmount})..`);
    const response = await faucet.addDrip(token.address, ethers.BigNumber.from(10).pow(decimals).mul(dripAmount)); // expandToDecimals
    const receipt = await response.wait();
    if (receipt.status !== 1) {
        throw Error(`Transaction reverted when adding drip ${symbol}`);
    }
    console.log(`Added drip for ${symbol} successfully.`);

    return token;
}

export default async function (hre: HardhatRuntimeEnvironment) {
    // Initialize deployer.
    const wallet = new Wallet(secrets.privateKey);
    deployer = new Deployer(hre, wallet);
    console.log(`Use account ${wallet.address} as deployer.`);

    console.log(`Deploying faucet contract..`);
    const artifact = await deployer.loadArtifact('Faucet');
    faucet = await deployer.deploy(artifact, [], feeToken ? {
        feeToken: feeToken
    } : undefined);

    await faucet.deployed();
    console.log(`Faucet has been successfully deployed to ${faucet.address}.`);

    console.log(`Adding default drips..`);
    await createTokenAndAddDrip(TokenType.ERC20_WITH_PERMIT, 'Frax', 'FRAX', 18, 5000);
    await createTokenAndAddDrip(TokenType.ERC20, 'Tether USD', 'USDT', 6, 5000);
    await createTokenAndAddDrip(TokenType.ERC20, 'Binance USD', 'BUSD', 18, 5000);
    await createTokenAndAddDrip(TokenType.ERC20, 'Smooth Love Potion', 'SLP', 0, 5000000);
    await createTokenAndAddDrip(TokenType.ERC20, 'Curve DAO Token', 'CRV', 18, 6000);
    await createTokenAndAddDrip(TokenType.ERC20_WITH_PERMIT, 'Testnet Token', 'TEST', 18, 10000);
    await createTokenAndAddDrip(TokenType.ERC677, 'Matter Labs Trial Token', 'MLTT', 10, 500);
    await createTokenAndAddDrip(TokenType.ERC677, 'Shiba Inu', 'SHIB', 18, 500000000);
    await createTokenAndAddDrip(TokenType.ERC20_WITH_PERMIT, 'renBTC', 'renBTC', 8, 1);
    await createTokenAndAddDrip(TokenType.ERC20, 'Lido Staked Ether', 'stETH', 18, 5);
    await createTokenAndAddDrip(TokenType.ERC20, 'Aave', 'AAVE', 18, 70);
    await createTokenAndAddDrip(TokenType.ERC20_WITH_PERMIT, 'Maker', 'MKR', 18, 5);

    const dripAmount = await faucet.dripsLength();
    console.log(`Total drip amount ${dripAmount}`);
    console.log(`Faucet has been deployed and initialized successfully.`);
}
