require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  gasReporter: {
    enabled: true,
    currency: "INR", //USD
    noColors: true,
    outputFile: "gasReport.txt",
    coinmarketcap: "a349fc01-76f7-484f-8fa9-61ddd307e11b",
    token: "matic", // matrix,
    // matic is a token for polygon blockchain
    //  with this we reduce the gas 1000 times lower
  },
};
