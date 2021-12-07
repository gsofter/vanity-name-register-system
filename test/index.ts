import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("Vanity Name Service", function () {
  this.timeout(100000);
  let vanityService: any;

  beforeEach(async function () {
    const VanityRegisterServiceContract = await ethers.getContractFactory(
      "VanityRegisterService"
    );

    vanityService = await VanityRegisterServiceContract.deploy();
    await vanityService.deployed();
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
});
