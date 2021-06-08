import { deployMockContract } from "@ethereum-waffle/mock-contract";
import { Wallet } from "@ethersproject/wallet";
import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import { abi as ControllerABI } from "../artifacts/contracts/Controller.sol/Controller.json";

import { Replica } from "../types";

describe("Replica", () => {
  const loadFixture = waffle.createFixtureLoader(
    waffle.provider.getWallets(),
    waffle.provider
  );

  async function fixture([wallet, other]: Wallet[]) {
    const tmp = await ethers.getContractFactory("Replica");
    const replica = await tmp.deploy();
    return {
      replica: replica as Replica,
      wallet,
      other,
    };
  }

  it("controller", async () => {
    const { replica, wallet } = await loadFixture(fixture);
    expect(await replica.controller()).to.eq(ethers.constants.AddressZero);
    await replica.initial(wallet.address);
    expect(await replica.controller()).to.eq(wallet.address);
    await expect(replica.initial(wallet.address)).to.be.reverted;
  });

  it("receive", async () => {
    const { replica, wallet } = await loadFixture(fixture);
    await expect(
      await wallet.sendTransaction({
        to: replica.address,
        value: 100,
        gasLimit: 30000,
      })
    ).to.changeEtherBalance(replica, 100);
  });

  it("payable fallback", async () => {
    const { replica, wallet } = await loadFixture(fixture);
    await expect(
      await wallet.sendTransaction({
        to: replica.address,
        value: 100,
        gasLimit: 30000,
        data: "0xa9059cbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      })
    ).to.changeEtherBalance(replica, 100);
  });

  it("dispatch", async () => {
    const { replica, wallet, other } = await loadFixture(fixture);
    const mockController = await deployMockContract(wallet, ControllerABI);
    await replica.initial(mockController.address);
    await mockController.mock.proxy.returns(wallet.address);
    await expect(
      replica.connect(other).invoke(wallet.address, 0, "0x")
    ).to.revertedWith("403");
    await replica.invoke(wallet.address, 0, "0x");
  });
});
