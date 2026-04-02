// scripts/fund.js
const hre = require("hre");
const addresses = require("./deployed.json");

async function main() {
  const [deployer, agentWallet] = await hre.ethers.getSigners();
  const usdc = await hre.ethers.getContractAt("MockERC20", addresses.usdc);
  // Mint 100,000 USDC to agent
  await usdc.mint(agentWallet.address, hre.ethers.parseUnits("100000", 6));
  console.log("Funded agent");
}