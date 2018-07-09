var Web3 = require('web3');
var provider = new Web3.providers.HttpProvider("http://184.72.118.127:8545");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
   networks: {
    development: {
      host: "localhost",
      port: 7545,
      network_id: "*",
      gas: 4012388,
      // from: "0x63a391ac64b6e4cc773ee7146e0a58d6a2046095"
    },
    rinkeby: {
      host: "localhost",
      port: 8545,
      network_id: "4",
      gas: 4012388,
      from: "0x71c20da180D9d50BDfeaC773942636D1695b9ec0"
    }
  }
};