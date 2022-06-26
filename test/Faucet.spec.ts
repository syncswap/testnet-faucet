import chai, { expect } from 'chai'
import { solidity } from 'ethereum-waffle'

import { deployERC20TestToken, deployAndInitializeFaucet } from './utils/helper'
import { Constants } from './utils/constants'

const hre = require("hardhat");
chai.use(solidity)

describe('Faucet', () => {

    it('dripsLength', async () => {
        const faucet = (await deployAndInitializeFaucet());
        await expect(await faucet.dripsLength()).to.eq(12);
    });

    it('allDrips', async () => {
        const faucet = (await deployAndInitializeFaucet());
        await expect((await faucet.allDrips()).length).to.eq(12);
    });

    it('getDripStatus', async () => {
        const account = (await hre.ethers.getSigners())[0];
        const faucet = (await deployAndInitializeFaucet()).connect(account);

        await expect(await faucet.getDripStatus(account.address)).to.eql(Array(12).fill(0));
        await expect(faucet.setDripActive(0, false));

        let statusExpected = Array(12).fill(0);
        statusExpected[0] = 2;
        await expect(await faucet.getDripStatus(account.address)).to.eql(statusExpected);

        await expect(faucet.claim(1));
        statusExpected[1] = 1;
        await expect(await faucet.getDripStatus(account.address)).to.eql(statusExpected);

        await expect(faucet.setDripActive(1, false));
        statusExpected[1] = 3;
        await expect(await faucet.getDripStatus(account.address)).to.eql(statusExpected);
    });

    it('addDrip:claim', async () => {
        const account = (await hre.ethers.getSigners())[0];
        const faucet = (await deployAndInitializeFaucet()).connect(account);
        const token = await deployERC20TestToken('Test Token', 'TEST', 18, faucet.address);

        const tokenInvalid = await deployERC20TestToken('Test Token', 'TEST', 18, account.address);
        await expect(faucet.addDrip(tokenInvalid.address, 100)).to.be.revertedWith("Invalid token to drip");
        await expect(faucet.addDrip(Constants.ZERO_ADDRESS, 100)).to.be.reverted; // Without reason

        await expect(await faucet.addDrip(token.address, 100));
        await expect(await faucet.dripsLength()).to.eq(13);
        await expect((await faucet.drips(12)).token).to.eq(token.address);

        await expect(faucet.claim(12))
            .to.emit(token, 'Transfer')
            .withArgs(Constants.ZERO_ADDRESS, account.address, 100);

        await expect(faucet.setDripActive(12, false));
        await expect(faucet.claim(12)).to.be.revertedWith('Drip is not active');
    });

    it('addDrip:claimMany', async () => {
        const account = (await hre.ethers.getSigners())[0];
        const faucet = (await deployAndInitializeFaucet()).connect(account);
        const token = await deployERC20TestToken('Test Token', 'TEST', 18, faucet.address);

        await expect(await faucet.addDrip(token.address, 100));
        await expect(faucet.claimMany([5, 10, 12]))
            .to.emit(faucet, 'ClaimDrips')
            .withArgs(3, 3)
            .to.emit(token, 'Transfer')
            .withArgs(Constants.ZERO_ADDRESS, account.address, 100);
    });

    it('addDrip:claimAll', async () => {
        const account = (await hre.ethers.getSigners())[0];
        const faucet = (await deployAndInitializeFaucet()).connect(account);
        const token = await deployERC20TestToken('Test Token', 'TEST', 18, faucet.address);

        await expect(await faucet.addDrip(token.address, 100));
        await expect(faucet.claimAll())
            .to.emit(faucet, 'ClaimDrips')
            .withArgs(13, 13)
            .to.emit(token, 'Transfer')
            .withArgs(Constants.ZERO_ADDRESS, account.address, 100);
    });

    it('claim', async () => {
        const account = (await hre.ethers.getSigners())[1];
        const faucet = (await deployAndInitializeFaucet()).connect(account);

        await expect(faucet.claim(0));
        await expect(faucet.claim(0)).to.be.revertedWith('Drip already claimed');
        await expect(faucet.claim(20)).to.be.revertedWith('Drip not exists');
    });

    it('claim:active', async () => {
        const account = (await hre.ethers.getSigners())[0];
        const faucet = (await deployAndInitializeFaucet()).connect(account);

        await expect(faucet.setDripActive(0, false));
        await expect(faucet.claim(0)).to.be.revertedWith('Drip is not active');

        await expect(faucet.setDripActive(0, true));
        await expect(faucet.claim(0));
    });

    it('claimMany', async () => {
        const account = (await hre.ethers.getSigners())[1];
        const faucet = (await deployAndInitializeFaucet()).connect(account);

        await expect(faucet.claimMany([0, 2, 5, 20])).to.be.revertedWith('Drip not exists');

        await expect(faucet.claimMany([0, 2, 5]))
            .to.emit(faucet, 'ClaimDrips')
            .withArgs(3, 3);

        await expect(faucet.claimMany([0, 1, 2]))
            .to.emit(faucet, 'ClaimDrips')
            .withArgs(3, 1);
    });

    it('claimAll', async () => {
        const account = (await hre.ethers.getSigners())[1];
        const faucet = (await deployAndInitializeFaucet()).connect(account);

        await expect(faucet.claimAll())
            .to.emit(faucet, 'ClaimDrips')
            .withArgs(12, 12);
    });

    it('claimAll:part', async () => {
        const account = (await hre.ethers.getSigners())[0];
        const faucet = (await deployAndInitializeFaucet()).connect(account);

        await expect(faucet.claim(2));
        await expect(faucet.setDripActive(10, false));
        await expect(faucet.claimAll())
            .to.emit(faucet, 'ClaimDrips')
            .withArgs(12, 10);

        await expect(faucet.setDripActive(10, true));
        await expect(faucet.claimAll())
            .to.emit(faucet, 'ClaimDrips')
            .withArgs(12, 1);
    });
});
