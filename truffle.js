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
    //  from: "0x15c0C903A2f7c59b31d75adcd8B08FAd4053Afe5"
    }
  }
};