require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-web3");


module.exports = {
  solidity: "0.8.0",

  networks: {
		hardhat: {
			// Uncomment these lines to use mainnet fork
			// forking: {
			// 	url: `${process.env.ALCHEMY_KEY}`,
			// 	blockNumber: 12626492,
			// },
		},
	},
};


