var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "vivid cabbage script team path coyote manual sunset chalk advance rebel foam";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 3999999
    },
    development2: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      gas: 3999999  //9999999
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};