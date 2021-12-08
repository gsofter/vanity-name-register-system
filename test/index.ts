import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

let vanityService: any;
let userA: SignerWithAddress;
let userB: SignerWithAddress;
let owner: SignerWithAddress;

describe("Vanity Name Service", function () {
  this.timeout(100000);
  const sampleName = "sample_name";

  it("Should work: contract deployment", async function () {
    const VanityRegisterServiceContract = await ethers.getContractFactory(
      "VanityRegisterService"
    );

    vanityService = await VanityRegisterServiceContract.deploy();
    await vanityService.deployed();

    [owner, userA, userB] = await ethers.getSigners();
  });

  it("Should have correct public variables", async function () {
    expect(await vanityService.lockTime()).to.equal("7776000");
    expect(await vanityService.lockNamePrice()).to.equal(
      ethers.utils.parseEther("0.01").toString()
    );
    expect(await vanityService.lockNamePrice()).to.equal(
      ethers.utils.parseEther("0.01").toString()
    );
    expect(await vanityService.bytePrice()).to.equal(
      ethers.utils.parseEther("0.0001").toString()
    );
  });

  it("Should work: setLockNamePrice", async function () {
    await vanityService.setLockNamePrice(ethers.utils.parseEther("0.0001"));
    expect(await vanityService.lockNamePrice()).to.equal(
      ethers.utils.parseEther("0.0001")
    );
  });

  it("Should work: isNameAvailable", async function () {
    expect(
      await vanityService
        .connect(userA)
        .isNameAvailable(ethers.utils.toUtf8Bytes(sampleName))
    ).to.equal(true);
  });

  it("Should fail: registering a short name", async function () {
    await expect(
      vanityService
        .connect(userA)
        .isNameAvailable(ethers.utils.toUtf8Bytes("as"))
    ).to.be.revertedWith("Name is too short.");
  });

  it("Should fail: registering a long name", async function () {
    await expect(
      vanityService
        .connect(userA)
        .isNameAvailable(
          ethers.utils.toUtf8Bytes(
            "thisisveryveryveryveryveryveryveryveryveryveryveryveryveryveryverylongname"
          )
        )
    ).to.be.revertedWith("Name is too long.");
  });

  it("Should work: A prePregister", async function () {
    const hashedName = await vanityService
      .connect(userA)
      .getPreRegisterHash(ethers.utils.toUtf8Bytes(sampleName));
    await vanityService.connect(userA).preRegister(hashedName);
  });

  it("Should fail: registering a name for insufficient amount", async function () {
    await expect(
      vanityService
        .connect(userA)
        .register(ethers.utils.toUtf8Bytes(sampleName))
    ).to.be.revertedWith("Insufficient amount!");
  });

  it("Should fail: A registering a name for cooldown", async function () {
    await expect(
      vanityService
        .connect(userA)
        .register(ethers.utils.toUtf8Bytes(sampleName), {
          value: ethers.utils.parseEther("0.1"),
        })
    ).to.be.revertedWith("No available preRegister.");
  });

  it("Should fail: B trying to frontrun A", async function () {
    const hashedName = await vanityService
      .connect(userB)
      .getPreRegisterHash(ethers.utils.toUtf8Bytes(sampleName));
    await vanityService.connect(userB).preRegister(hashedName);
    const price = await vanityService
      .connect(userB)
      .getRegisterPrice(ethers.utils.toUtf8Bytes(sampleName));

    await expect(
      vanityService
        .connect(userB)
        .register(ethers.utils.toUtf8Bytes(sampleName), {
          value: price.toString(),
        })
    ).to.be.revertedWith("No available preRegister.");
  });

  it("Should work: A get price and register a name", async function () {
    await addEvmTime(400);
    await mineBlocks(1);

    const price = await vanityService
      .connect(userA)
      .getRegisterPrice(ethers.utils.toUtf8Bytes(sampleName));

    await vanityService
      .connect(userA)
      .register(ethers.utils.toUtf8Bytes(sampleName), {
        value: price.toString(),
      });
  });
});

async function getAccountBalance(address: string) {
  return await ethers.provider.getBalance(address);
}
async function addEvmTime(time: number) {
  await ethers.provider.send("evm_increaseTime", [time]);
}
async function mineBlocks(blockNumber: number) {
  while (blockNumber > 0) {
    blockNumber--;
    await ethers.provider.send("evm_mine", []);
  }
}
