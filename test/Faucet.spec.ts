import chai, { expect } from 'chai'
import { solidity } from 'ethereum-waffle'

import { deployFaucet, expandTo18Decimals } from './utils/helper'
import { Constants } from './utils/constants'
import { Fixtures } from './utils/fixtures'

const hre = require("hardhat");
chai.use(solidity)

describe('Faucet', () => {
    it('claim', async () => {
        const faucet = await deployFaucet();

        const accounts = await hre.ethers.getSigners();
        await expect(faucet.connect(accounts[1]).claim(1));
        await expect(faucet.connect(accounts[1]).claim(1)).to.be.revertedWith('Drip already claimed');
        await expect(faucet.connect(accounts[1]).claim(99)).to.be.revertedWith('Drip not exists');
    });

    it('claimMany', async () => {
        const faucet = await deployFaucet();

        const accounts = await hre.ethers.getSigners();
        await expect(faucet.connect(accounts[1]).claimMany([0, 2, 99])).to.be.revertedWith('Drip not exists');;
        await expect(faucet.connect(accounts[1]).claimMany([0, 2, 5]));
    });

    it('claimAll', async () => {
        const faucet = await deployFaucet();

        const accounts = await hre.ethers.getSigners();
        await expect(faucet.connect(accounts[1]).claimAll());
    });
});
