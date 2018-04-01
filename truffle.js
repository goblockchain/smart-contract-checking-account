var Web3 = require('web3');
var provider = new Web3.providers.HttpProvider("http://184.72.118.127:8545");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
   networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      gas: 6712388,
     // from: "0x3c821b992462f77f4ca69bdcf94fbe3564cc932a"
    }
  }
};