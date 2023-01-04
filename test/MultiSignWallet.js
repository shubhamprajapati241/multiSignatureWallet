const { expect } = require("chai");
const { ethers } = require("hardhat");
const { EDIT_DISTANCE_THRESHOLD } = require("hardhat/internal/constants");

// converting number into ethers
const numberToEthers = (number) => {
  return ethers.utils.parseUnits(number.toString(), "ether");
};

describe("MultiSignature Wallet", () => {
  let multiSignWallet; // for contract

  let owner1, owner2, owner3; // for owners
  let owners;
  let other1, other2; // for other users
  let numConfirmationRequired = 2;

  beforeEach(async () => {
    [owner1, owner2, owner3, other1, other2] = await ethers.getSigners();
    owners = [owner1.address, owner2.address, owner3.address];

    // console.log(owners);

    const MultiSignWallet = await ethers.getContractFactory("MultiSignWallet");
    multiSignWallet = await MultiSignWallet.deploy(
      owners,
      numConfirmationRequired
    );
  });

  describe("Deployment", () => {
    it("has the owners", async () => {
      let result = await multiSignWallet.owners(0);
      expect(result).to.be.equal(owner1.address);

      result = await multiSignWallet.owners(1);
      expect(result).to.be.equal(owner2.address);

      result = await multiSignWallet.owners(2);
      expect(result).to.be.equal(owner3.address);
    });

    it("has the number of confirmation", async () => {
      const result = await multiSignWallet.numConfirmationsRequired();
      expect(result).to.be.equal(numConfirmationRequired);
    });

    it("transaction count will 0", async () => {
      const count = await multiSignWallet.getTransactionCount();
      expect(count).to.be.equal(0);
    });

    it("Checking isOwner for Owner", async () => {
      const result = await multiSignWallet.isOwner(owner1.address);
      expect(result).to.be.equal(true);
    });

    it("Checking isOwner for others", async () => {
      const result = await multiSignWallet.isOwner(other1.address);
      expect(result).to.be.equal(false);
    });

    // it("getting owners", async () => {
    //   const result = await multiSignWallet.getOwners();
    //   console.log(result);
    //   expect(result).to.be.equal(owners);
    // });
  });

  describe("Deposit ethers", () => {
    const option = { value: numberToEthers(10) }; // depositing 10 ethers
    let balanceBefore;

    beforeEach(async () => {
      balanceBefore = await ethers.provider.getBalance(owner1.address);
      let transaction = await multiSignWallet
        .connect(owner1)
        .depositEth(option);
      await transaction.wait();
    });

    it("Updating the owner balance", async () => {
      const balanceAfter = await ethers.provider.getBalance(owner1.address);
      expect(balanceAfter).to.be.lessThan(balanceBefore);
    });

    it("Updating the contract balance", async () => {
      const contractbalance = await multiSignWallet.getContractBalance();
      expect(contractbalance).to.be.equal(option.value);
    });

    // todo **Submit Transaction
    describe("Submit Transaction", () => {
      let otherAddress;
      let AMOUNT = numberToEthers(2);
      let data = "0x1234";

      beforeEach(async () => {
        otherAddress = other1.address;
        let transaction = await multiSignWallet
          .connect(owner1)
          .submitTransaction(otherAddress, AMOUNT, data);
        await transaction.wait();
      });

      it("has other1 Address", async () => {
        const transaction = await multiSignWallet.getTransaction(0);
        expect(transaction.to).to.be.equal(otherAddress);
      });

      it("has value", async () => {
        const transaction = await multiSignWallet.getTransaction(0);
        expect(transaction.value).to.be.equal(AMOUNT);
      });

      it("has data", async () => {
        const transaction = await multiSignWallet.getTransaction(0);
        expect(transaction.data).to.be.equal(data);
      });

      it("has numConfirmations 0", async () => {
        const transaction = await multiSignWallet.getTransaction(0);
        expect(transaction.numConfirmations).to.be.equal(0);
      });

      it("has execution false", async () => {
        const transaction = await multiSignWallet.getTransaction(0);
        expect(transaction.executed).to.be.equal(false);
      });

      it("Update Transaction Count 1", async () => {
        const transactionCount = await multiSignWallet.getTransactionCount();
        expect(transactionCount).to.be.equal(1);
      });

      // todo **Confirm Transaction
      describe("Confirm Transaction", () => {
        beforeEach(async () => {
          let result = await multiSignWallet
            .connect(owner1)
            .confirmTransaction(0);
          result = await multiSignWallet.connect(owner2).confirmTransaction(0);

          result = await multiSignWallet.connect(owner3).confirmTransaction(0);

          await result.wait();
        });

        it("3 owners confirm & numConfirmations 3", async () => {
          const transaction = await multiSignWallet.getTransaction(0);
          expect(transaction.numConfirmations).to.be.equal(3);
        });

        // todo **Revoke Transaction
        describe("Revoke Transaction", () => {
          beforeEach(async () => {
            let result = await multiSignWallet
              .connect(owner3)
              .revokeConfirmation(0);
            await result.wait();
          });

          it("owner3 revoking & numberOfConfirmation 2", async () => {
            const transaction = await multiSignWallet.getTransaction(0);
            expect(transaction.numConfirmations).to.be.equal(2);
          });

          // todo **Execute Transaction
          describe("Execute Transaction", () => {
            beforeEach(async () => {
              let result = await multiSignWallet
                .connect(owner1)
                .excecuteTransaction(0);
              await result.wait();
            });

            it("executed True", async () => {
              const transaction = await multiSignWallet.getTransaction(0);
              expect(transaction.executed).to.be.equal(true);
            });
          });
        });
      });
    });
  });
});
