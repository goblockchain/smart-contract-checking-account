var CheckingAccount = artifacts.require("./CheckingAccount.sol");

contract('CheckingAccount', (accounts) => {
  var creatorAddress = accounts[0];
  var firstOwnerAddress = accounts[1];
  var secondOwnerAddress = accounts[2];
  var externalAddress = accounts[3];

  //Tests to validate the feature Send Tokens
  it('should revert the transaction of addAuthorizer when an invalid address calls it', () => {
    return CheckingAccount.deployed()
      .then(instance => {
        return instance.addAuthorizer(firstOwnerAddress, 1, {from:externalAddress});
      })
      .then(result => {
        assert.fail();
      })
      .catch(error => {
        assert.notEqual(error.message, "assert.fail()", "Transaction was not reverted with an invalid address");
      });
  });

  it('should revert the transaction of removeAuthorizer when an invalid address calls it', () => {
    return CheckingAccount.deployed()
      .then(instance => {
        return instance.removeAuthorizer(firstOwnerAddress, {from:externalAddress});
      })
      .then(result => {
        assert.fail();
      })
      .catch(error => {
        assert.notEqual(error.message, "assert.fail()", "Transaction was not reverted with an invalid address");
      });
  });

  it('should not revert the transaction of owner modification by the creator address', () => {
    var CheckingAccountInstance;
    return CheckingAccount.deployed()
      .then(instance => {
        CheckingAccountInstance = instance;
        return CheckingAccountInstance.addAuthorizer(creatorAddress, 1);
      })
      .then(removedResult => {
        return CheckingAccountInstance.removeAuthorizer(creatorAddress);
      })
      .catch(error => {
        assert.fail("Transaction was reverted by a creator call");
      });
  });

  it('should revert the transaction if adding Authorizer more than limit 10', () => {
    var CheckingAccountInstance;
    return CheckingAccount.deployed()
      .then(instance => {
        CheckingAccountInstance = instance;
        return CheckingAccountInstance.addAuthorizer(accounts[1], 1);
      })
      .then(addingBatchResult => {
        return CheckingAccountInstance.addAuthorizer(accounts[2], 1);
      }).then(addingBatchResult => {
        return CheckingAccountInstance.addAuthorizer(accounts[3], 1);
      }).then(addingBatchResult => {
        return CheckingAccountInstance.addAuthorizer(accounts[4], 1);
      }).then(addingBatchResult => {
        return CheckingAccountInstance.addAuthorizer(accounts[5], 1);
      }).then(addingBatchResult => {
        return CheckingAccountInstance.addAuthorizer(accounts[6], 1);
      }).then(addingBatchResult => {
        return CheckingAccountInstance.addAuthorizer(accounts[7], 1);
      }).then(addingBatchResult => {
        return CheckingAccountInstance.addAuthorizer(accounts[8], 1);
      }).then(addingBatchResult => {
        return CheckingAccountInstance.addAuthorizer(accounts[9], 1);
      }).then(addingBatchResult => {
        return CheckingAccountInstance.addAuthorizer(creatorAddress, 1);
      })
      .then(addingResult => {
        assert.fail();
      })
      .catch(error => {
        assert.notEqual(error.message, "assert.fail()", "Transaction was not reverted with an invalid number of addresses");
      });
  });

  it('should revert the transaction of deleteTransactionSendToken on an invalid transaction ID', () => {
    return CheckingAccount.deployed()
      .then(instance => {
        return instance.deleteTransactionSendToken(1);
      })
      .then(result => {
        assert.fail();
      })
      .catch(error => {
        assert.notEqual(error.message, "assert.fail()", "Transaction was not reverted with an invalid transaction ID passed");
      })
  });

  it('should revert the transaction if the creator of a pending transaction tries to sign the transaction', () => {
    var CheckingAccountInstance;
    return CheckingAccount.deployed()
       .then(instance => {
           CheckingAccountInstance = instance;
           return CheckingAccountInstance.sendTransaction({from: creatorAddress, value: 1000})
         })
        .then(sendResult => {
          return CheckingAccountInstance.withdraw(10);
        })
        .then(withdrawResult => {
          return CheckingAccountInstance.signTransactionSendToken(0);
        })
        .then(signResult => {
          assert.fail();
        })
        .catch(error => {
          assert.notEqual(error.message, "assert.fail()", "Transaction was not reverted after creator signed a transaction");
        });
  });

  it('should revert the transaction if the signer of a pending transaction tries to sign the transaction again', () => {
    var CheckingAccountInstance;
    return CheckingAccount.deployed()
       .then(instance => {
           CheckingAccountInstance = instance;
           return CheckingAccountInstance.sendTransaction({from: creatorAddress, value: 30000});
         })
         .then(transferResult => {
           return CheckingAccountInstance.addAuthorizer(firstOwnerAddress, 1);
         })
        .then(addAuthorizerResult => {
          return CheckingAccountInstance.withdraw(10, {from: firstOwnerAddress});
        })
        .then(firstWithdrawResult => {
          return CheckingAccountInstance.signTransactionSendToken(1);
        })
        .then(secondWithdrawResult => {
          return CheckingAccountInstance.signTransactionSendToken(1);
        })
        .then(signResult => {
          assert.fail();
        })
        .catch(error => {
          assert.notEqual(error.message, "assert.fail()", "Transaction was not reverted after creator signed a transaction");
        });
  });


  //Tests to validate the feature Change Contract's Ownership

  it('should revert the transaction of deleteTransactionChangeContractOwnership on an invalid transaction ID', () => {
    return CheckingAccount.deployed()
      .then(instance => {
        return instance.deleteTransactionChangeContractOwnership(1);
      })
      .then(result => {
        assert.fail();
      })
      .catch(error => {
        assert.notEqual(error.message, "assert.fail()", "Transaction was not reverted with an invalid transaction ID passed");
      })
  });

  it('should revert the transaction to change ownewrship if the creator of a pending transaction tries to sign the transaction', () => {
    var CheckingAccountInstance;
    return CheckingAccount.deployed()
       .then(instance => {
           CheckingAccountInstance = instance;
           return CheckingAccountInstance.sendTransaction({from: creatorAddress, value: 1000})
         })
        .then(sendResult => {
          return CheckingAccountInstance.transferContractOwnershipTo(firstOwnerAddress);
        })
        .then(withdrawResult => {
          return CheckingAccountInstance.signTransactionToChangeContractOwnership(0);
        })
        .then(signResult => {
          assert.fail();
        })
        .catch(error => {
          assert.notEqual(error.message, "assert.fail()", "Transaction was not reverted after creator signed a transaction");
        });
  });

  it('should revert the transaction to change ownewrship if the receiver of a pending transaction tries to sign the transaction', () => {
    var CheckingAccountInstance;
    return CheckingAccount.deployed()
       .then(instance => {
           CheckingAccountInstance = instance;
           return CheckingAccountInstance.sendTransaction({from: creatorAddress, value: 30000});
         })
         .then(transferResult => {
           CheckingAccountInstance.removeAuthorizer(firstOwnerAddress);
           return CheckingAccountInstance.addAuthorizer(firstOwnerAddress, 1);
         })
        .then(addAuthorizerResult => {
          return CheckingAccountInstance.transferContractOwnershipTo(firstOwnerAddress);
        })
        .then(firstWithdrawResult => {
          return CheckingAccountInstance.signTransactionToChangeContractOwnership(1, {from: firstOwnerAddress});
        })
        .then(signResult => {
          assert.fail();
        })
        .catch(error => {
          assert.notEqual(error.message, "assert.fail()", "Transaction was not reverted after creator signed a transaction");
        });
  });

});
