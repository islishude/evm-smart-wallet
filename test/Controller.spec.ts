import { Wallet } from "@ethersproject/wallet";
import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import { Controller, Replica } from "../types";
import { abi as ReplicaABI } from "../artifacts/contracts/Replica.sol/Replica.json";
import { Contract } from "@ethersproject/contracts";

describe("Controller", () => {
  const loadFixture = waffle.createFixtureLoader(
    waffle.provider.getWallets(),
    waffle.provider
  );

  async function fixture([wallet, other]: Wallet[]) {
    const tmp = await ethers.getContractFactory("Controller");
    const controller = await tmp.deploy(wallet.address, other.address);
    return { controller: controller as Controller, wallet, other };
  }

  it("owner,proxy,implemention", async () => {
    const { controller, wallet, other } = await loadFixture(fixture);
    expect(await controller.owner()).eq(wallet.address, "owner");
    expect(await controller.proxy()).eq(other.address, "proxy");

    expect(await controller.implementation()).eq(
      ethers.utils.getContractAddress({ from: controller.address, nonce: 1 }),
      "implementation"
    );
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

  it("createReplica,predictReplica", async () => {
    const { controller, wallet, other } = await loadFixture(fixture);

    const impl = ethers.utils.getContractAddress({
      from: controller.address,
      nonce: 1,
    });

    const initcode =
      "0x3d602d80600a3d3981f3363d3d373d3d3d363d73" +
      impl.slice(2) +
      "5af43d82803e903d91602b57fd5bf3";

    const salt =
      "0x0000000000000000000000000000000000000000000000000000000000000000";
    const genaddr = ethers.utils.getCreate2Address(
      controller.address,
      salt,
      ethers.utils.keccak256(initcode)
    );

    expect(await controller.predictReplica(salt)).to.eq(
      genaddr,
      "predictReplica"
    );

    await expect(
      controller.connect(other).createReplica([salt]),
      "createReplica 403"
    ).to.be.revertedWith("403");

    expect(await controller.createReplica([salt]), "createReplica")
      .to.be.emit(controller, "CreateReplica")
      .withArgs(genaddr);

    // TODO: https://github.com/nomiclabs/hardhat/issues/1135
    // expect("initial").to.calledOnContractWith(genaddr, [controller.address]);

    const newReplica = new Contract(genaddr, ReplicaABI, wallet) as Replica;
    expect(await newReplica.controller()).to.eq(controller.address);
  });
});
