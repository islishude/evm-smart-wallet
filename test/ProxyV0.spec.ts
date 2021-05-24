import { Wallet } from "@ethersproject/wallet";
import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import { Controller, MemeToken, ProxyV0, Replica, TestToken } from "../types";
import { abi as ReplicaABI } from "../artifacts/contracts/Replica.sol/Replica.json";
import { Contract } from "@ethersproject/contracts";
import { randomBytes } from "@ethersproject/random";

describe("ProxyV0", () => {
  const loadFixture = waffle.createFixtureLoader(
    waffle.provider.getWallets(),
    waffle.provider
  );

  async function fixture([wallet, other]: Wallet[]) {
    const proxyV0Factory = await ethers.getContractFactory("ProxyV0");
    const proxyV0 = await proxyV0Factory.deploy(wallet.address);

    const controllerFacotry = await ethers.getContractFactory("Controller");
    const controller = await controllerFacotry.deploy(
      wallet.address,
      proxyV0.address
    );

    const salt = randomBytes(32);
    const replicaAddress = ethers.utils.getCreate2Address(
      controller.address,
      salt,
      ethers.utils.keccak256(
        "0x3d602d80600a3d3981f3363d3d373d3d3d363d73" +
          ethers.utils
            .getContractAddress({
              from: controller.address,
              nonce: 1,
            })
            .slice(2) +
          "5af43d82803e903d91602b57fd5bf3"
      )
    );

    await controller.createReplica([salt]);
    const newReplica = new Contract(replicaAddress, ReplicaABI, wallet);

    const testTokenFactory = await ethers.getContractFactory("TestToken");
    const testToken = await testTokenFactory.deploy();

    const memeTokenFactory = await ethers.getContractFactory("MemeToken");
    const memeToken = await memeTokenFactory.deploy();

    return {
      controller: controller as Controller,
      proxy: proxyV0 as ProxyV0,
      replica: newReplica,
      testToken: testToken as TestToken,
      memeToken: memeToken as MemeToken,
      wallet,
      other,
    };
  }

  it("VERSION,owner", async () => {
    const { proxy, wallet } = await loadFixture(fixture);
    expect(await proxy.VERSION()).to.eq(0);
    expect(await proxy.owner()).to.eq(wallet.address);
  });

  it("transferEther", async () => {
    const { proxy, wallet, replica, other } = await loadFixture(fixture);
    await wallet.sendTransaction({ to: replica.address, value: 200 });
    expect(
      await proxy.transferEther(other.address, [
        { replica: replica.address, value: 200 },
      ])
    ).to.changeEtherBalances([replica, other], [-200, 200]);

    await expect(
      proxy
        .connect(other)
        .transferEther(other.address, [
          { replica: replica.address, value: 200 },
        ])
    ).to.revertedWith("403");
  });

  it("transferERC20Token", async () => {
    const { proxy, replica, other, testToken } = await loadFixture(fixture);

    await expect(
      proxy
        .connect(other)
        .transferERC20Token(testToken.address, other.address, true, [
          { replica: replica.address, value: 10000 },
        ])
    ).to.revertedWith("403");
    await testToken.transfer(replica.address, 10000);
    await proxy.transferERC20Token(testToken.address, other.address, true, [
      { replica: replica.address, value: 10000 },
    ]);

    expect(await testToken.balanceOf(replica.address)).to.eq(0);
    expect(await testToken.balanceOf(other.address)).to.eq(10000);
  });

  it("transferERC20TokenWithFeeBurned", async () => {
    const { proxy, replica, other, memeToken } = await loadFixture(fixture);

    await expect(
      proxy
        .connect(other)
        .transferERC20TokenWithFeeBurned(
          memeToken.address,
          replica.address,
          other.address,
          9800
        )
    ).to.revertedWith("403");

    await memeToken.transfer(replica.address, 10000);
    expect(await memeToken.balanceOf(replica.address)).to.eq(9800);

    expect(
      await proxy.transferERC20TokenWithFeeBurned(
        memeToken.address,
        replica.address,
        other.address,
        9800
      )
    )
      .to.emit(proxy, "TokenTransferFeeBurn")
      .withArgs(memeToken.address, other.address, 196);

    expect(await memeToken.balanceOf(other.address)).to.eq(9604);
  });

  it("dispatch", async () => {
    const { proxy, replica, other, testToken } = await loadFixture(fixture);

    await expect(
      proxy.connect(other).invoke(other.address, replica.address, "0x")
    ).to.revertedWith("403");

    await proxy.invoke(other.address, replica.address, "0x");
  });
});
