module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
   networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      gas: 6712388,
      gasPrice: 65000000000,
      // from: "0xf17f52151EbEF6C7334FAD080c5704D77216b732"
    }
  }
};
