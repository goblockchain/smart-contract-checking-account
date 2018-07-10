const CheckingAccount = artifacts.require("./CheckingAccount.sol");

module.exports = function(deployer) {
  deployer.deploy(CheckingAccount);
};
