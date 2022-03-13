import { Wallet } from "@ethersproject/wallet";
import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import { Controller, Replica } from "../types";
import * as crypto from "crypto";
import { abi as ReplicaABI } from "../artifacts/contracts/Replica.sol/Replica.json";
import { Contract } from "@ethersproject/contracts";

describe("Controller", () => {
  const loadFixture = waffle.createFixtureLoader(
    waffle.provider.getWallets(),
    waffle.provider
  );

  async function fixture([wallet, other]: Wallet[]) {
    const tmp = await ethers.getContractFactory("Controller");
    const controller = await tmp.deploy(
      wallet.address,
      other.address,
      other.address
    );
    return { controller: controller as Controller, wallet, other };
  }

  it("owner,proxy,implemention", async () => {
    const { controller, wallet, other } = await loadFixture(fixture);
    expect(await controller.owner()).eq(wallet.address, "owner");
    expect(await controller.proxy()).eq(other.address, "proxy");
  });

  it("implemention,setImplemention", async () => {
    const newimpl = "0x000000000000000000000000000000000000dEaD";

    const { controller, wallet, other } = await loadFixture(fixture);
    expect(await controller.implementation()).eq(
      other.address,
      "implementation"
    );

    await expect(
      controller.connect(other).changeImplemention(newimpl),
      "changeImplemention 403"
    ).to.be.revertedWith("403");

    await expect(controller.changeImplemention(newimpl), "changeImplemention")
      .to.emit(controller, "ChangeProxy")
      .withArgs(newimpl);
  });

  it("wallets,setWallet", async () => {
    const allowed = "0x000000000000000000000000000000000000dEaD";
    const { controller, other } = await loadFixture(fixture);

    await expect(
      controller.connect(other).setWallet(allowed, true),
      "setWallet 403"
    ).to.be.revertedWith("403");

    expect(await controller.wallets(allowed)).to.be.false;

    await expect(controller.setWallet(allowed, true), "SetWallet")
      .to.emit(controller, "SetWallet")
      .withArgs(allowed, true);

    expect(await controller.wallets(allowed)).to.be.true;

    await expect(controller.setWallet(allowed, false), "SetWallet")
      .to.emit(controller, "SetWallet")
      .withArgs(allowed, false);

    expect(await controller.wallets(allowed)).to.be.false;
  });

  it("changeProxy", async () => {
    const newProxyAddress = "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB";
    const { controller, other } = await loadFixture(fixture);

    await expect(
      controller.connect(other).changeProxy(newProxyAddress),
      "changeProxy 403"
    ).to.be.revertedWith("403");

    await expect(controller.changeProxy(newProxyAddress), "changeProxy")
      .to.emit(controller, "ChangeProxy")
      .withArgs(newProxyAddress);
  });

  it("createReplica,predictReplica,replicaCodeHash", async () => {
    const { controller, other } = await loadFixture(fixture);

    const replicaFactory = await ethers.getContractFactory("Replica");
    const replicaCodeHash = await controller.replicaCodeHash();
    expect(replicaCodeHash, "replicaCodeHash").to.be.eq(
      ethers.utils.keccak256(replicaFactory.bytecode)
    );

    const salts = new Array(3).fill(0).map(() => crypto.randomBytes(32));
    const replicas = salts.map((v) =>
      ethers.utils.getCreate2Address(controller.address, v, replicaCodeHash)
    );

    await expect(
      controller.connect(other).createReplica(salts),
      `createReplica 403`
    ).to.be.revertedWith("403");

    for (const [idx, salt] of salts.entries()) {
      expect(
        await controller.predictReplica(salt),
        `predictReplica ${idx}`
      ).to.be.eq(replicas[idx]);
    }

    expect(await controller.createReplica(salts), `createReplica`)
      .to.emit(controller, "CreateReplica")
      .withArgs(replicas[0])
      .to.emit(controller, "CreateReplica")
      .withArgs(replicas[1])
      .to.emit(controller, "CreateReplica")
      .withArgs(replicas[2]);
  });
});
