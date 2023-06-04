const { ethers, waffle } = require("hardhat");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
chai.use(solidity);
const { expect } = chai;

const VOIDRITE = 1;
const VOIDTOUCHED = 2;

describe("Voidrite", function() {
    let Voidrite, voidrite, owner, addr1, cleaner;

    beforeEach(async function () {
        Voidrite = await ethers.getContractFactory("Voidrite");
        [owner, addr1, cleaner] = await ethers.getSigners();
        voidrite = await Voidrite.deploy();
        await voidrite.deployed();
        await voidrite.addAddressToCleaner(cleaner.address);
        await voidrite.toggleMinting(true); 
        await voidrite.setMintPrice(ethers.utils.parseEther("1"));
      });
    
      it("Should mint tokens", async function () {
        await voidrite.mint(5, { value: ethers.utils.parseEther("5") });
        const balance = await voidrite.balanceOf(owner.address, VOIDRITE);
        expect(balance).to.equal(60005);
      });
    
      it("Should fail to mint tokens if Ether sent is insufficient", async function () {
        await expect(voidrite.mint(5, { value: ethers.utils.parseEther("4") })).to.be.revertedWith("Ether value sent is not correct");
      });

      it("Should burn tokens using CleanerBurn", async function () {
        await voidrite.connect(cleaner).CleanerBurn(owner.address, VOIDRITE, 5);
        const balance = await voidrite.balanceOf(owner.address, VOIDRITE);
        expect(balance).to.equal(59995);
      });
    
      it("Should fail CleanerBurn if not cleaner", async function () {
        await expect(voidrite.connect(addr1).CleanerBurn(owner.address, VOIDRITE, 5)).to.be.revertedWith("You must be a cleaner");
      });
    
      it("Should burn tokens using CleanerBurnBatch", async function () {
        await voidrite.connect(cleaner).CleanerBurnBatch(owner.address, [VOIDRITE, VOIDTOUCHED], [5, 2]);
        const balanceVoidrite = await voidrite.balanceOf(owner.address, VOIDRITE);
        const balanceVoidtouched = await voidrite.balanceOf(owner.address, VOIDTOUCHED);
        expect(balanceVoidrite).to.equal(59995);
        expect(balanceVoidtouched).to.equal(59998);
      });
    
      it("Should fail CleanerBurnBatch if not cleaner", async function () {
        await expect(voidrite.connect(addr1).CleanerBurnBatch(owner.address, [VOIDRITE, VOIDTOUCHED], [5, 2])).to.be.revertedWith("You must be a cleaner");
      });
    
      it("Should transfer tokens using CleanerTransfer", async function () {
        await voidrite.connect(cleaner).CleanerTransfer(owner.address, addr1.address, VOIDRITE, 5);
        const balance = await voidrite.balanceOf(addr1.address, VOIDRITE);
        expect(balance).to.equal(5);
      });
    
      it("Should fail CleanerTransfer if not cleaner", async function () {
        await expect(voidrite.connect(addr1).CleanerTransfer(owner.address, addr1.address, VOIDRITE, 5)).to.be.revertedWith("Only cleaner can perform this action");
      });

      it("Should fail safeTransferFrom if trying to transfer VOIDTOUCHED", async function () {
        await expect(voidrite.safeTransferFrom(owner.address, addr1.address, VOIDTOUCHED, 5, [])).to.be.revertedWith("You can't transfer that");
    });
    
    it("Should perform safeTransferFrom correctly if transferring VOIDRITE", async function () {
        await voidrite.safeTransferFrom(owner.address, addr1.address, VOIDRITE, 5, []);
        const balance = await voidrite.balanceOf(addr1.address, VOIDRITE);
        expect(balance).to.equal(5);
    });
    
    it("Should fail to burn VOIDTOUCHED", async function () {
        await expect(voidrite.burn(owner.address, VOIDTOUCHED, 5)).to.be.revertedWith("You can't burn that");
    });
    
    it("Should burn VOIDRITE correctly", async function () {
        await voidrite.burn(owner.address, VOIDRITE, 5);
        const balance = await voidrite.balanceOf(owner.address, VOIDRITE);
        expect(balance).to.equal(59995);
    });
    
    it("Should fail _beforeTokenTransfer if transferring VOIDTOUCHED without CLEANER_ROLE", async function () {
        await expect(voidrite.safeTransferFrom(owner.address, addr1.address, VOIDTOUCHED, 5, [])).to.be.revertedWith("You can't transfer that");
    });
    
    describe("Deployment", function() {
        it("Should set the right owner", async function() {
            expect(await voidrite.hasRole(voidrite.ADMIN_ROLE(), owner.address)).to.equal(true);
        });

        it("Initial supply must be 60000 for VOIDRITE", async function() {
            expect(await voidrite.balanceOf(owner.address, voidrite.VOIDRITE())).to.equal(60000);
        });

        it("Initial supply must be 60000 for VOIDTOUCHED", async function() {
            expect(await voidrite.balanceOf(owner.address, voidrite.VOIDTOUCHED())).to.equal(60000);
        });
    });

    describe("Minting", function() {
   
        it("Should mint correctly", async function() {
            await voidrite.mint(5, { value: ethers.utils.parseEther("5") });
            expect(await voidrite.balanceOf(owner.address, voidrite.VOIDRITE())).to.equal(60005);
            expect(await voidrite.balanceOf(owner.address, voidrite.VOIDTOUCHED())).to.equal(60005);
        });
    });

    it("Should return the right URI after minting a token", async function () {
        const Voidrite = await ethers.getContractFactory("Voidrite");
        const voidrite = await Voidrite.deploy();
        await voidrite.deployed();
        const uri = await voidrite.uri(1);
        expect(uri).to.equal("ipfs://QmPBLbSjhBvv5JgepMSrzvAX9yAXDn3k4hfmmkeGQSirsd");
      });
    
      describe("Staking", function () {
        it("Should stake tokens", async function () {
          await voidrite.stake(1000);
          const stakerBalance = await voidrite.getStakerBalance(owner.address);
          expect(stakerBalance).to.equal(1000);
        });
    
        it("Should fail to stake more tokens than held", async function () {
          await expect(voidrite.stake(80000)).to.be.revertedWith("You cannot stake more tokens than you hold");
        });
    
        it("Should unstake tokens after cooldown period", async function () {
          await voidrite.stake(1000);
          await ethers.provider.send("evm_increaseTime", [24*60*60+1]); // Increase time by 1 day + 1 sec
          await ethers.provider.send("evm_mine"); // Mine another block
    
          await voidrite.unstake(500);
          const stakerBalance = await voidrite.getStakerBalance(owner.address);
          expect(stakerBalance).to.equal(500);
        });
    
        it("Should fail to unstake tokens before cooldown period", async function () {
          await voidrite.stake(1000);
          await expect(voidrite.unstake(500)).to.be.revertedWith("Cooldown period not met");
        });
      });
    
      describe("Buying and Selling", function () {
        beforeEach(async function () {
          await voidrite.setBuyPrice(ethers.utils.parseEther("1"));
          await voidrite.setSellPrice(ethers.utils.parseEther("0.8"));
          await voidrite.setMintPrice(ethers.utils.parseEther("1"));
          await voidrite.mint(5, { value: ethers.utils.parseEther("5") });
        });
    
        it("Should buy tokens", async function () {
            await voidrite.setMintPrice(ethers.utils.parseEther("1"));
            await voidrite.mint(5, { value: ethers.utils.parseEther("5") });
            await voidrite.sellVoidrite(5);
          await voidrite.buyVoidrite(5, {value: ethers.utils.parseEther("100")});
          const balance = await voidrite.balanceOf(owner.address, VOIDRITE);
          expect(balance).to.equal(60010);
        });
    
        it("Should fail to buy tokens if Ether sent is insufficient", async function () {
          await expect(voidrite.buyVoidrite(100, {value: ethers.utils.parseEther("50")})).to.be.revertedWith("Ether value sent is not correct");
        });
    
        it("Should sell tokens", async function () {
            await voidrite.setMintPrice(ethers.utils.parseEther("1"));
            await voidrite.mint(5, { value: ethers.utils.parseEther("5") });
            await voidrite.sellVoidrite(5);
          const balance = await voidrite.balanceOf(owner.address, VOIDRITE);
          expect(balance).to.equal(60005);
        });
      });
});
