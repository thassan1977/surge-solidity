// scripts/deploy.js
import hre from "hardhat";
import fs from "fs";

async function main() {
  const [deployer, validator] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // 1. Deploy mock USDC (6 decimals)
  const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
  const usdc = await MockERC20.deploy("USDC", "USDC", 6);
  await usdc.waitForDeployment();
  console.log("USDC deployed to:", usdc.target);

  // 2. NEW: Deploy mock WETH (18 decimals)
  // Most trading pairs use WETH (18 decimals) instead of raw ETH
  const weth = await MockERC20.deploy("Wrapped Ether", "WETH", 18);
  await weth.waitForDeployment();
  console.log("WETH deployed to:", weth.target);

  // 3. Deploy IdentityRegistry
  const IdentityRegistry = await hre.ethers.getContractFactory("IdentityRegistry");
  const identity = await IdentityRegistry.deploy();
  await identity.waitForDeployment();
  console.log("IdentityRegistry deployed to:", identity.target);

  // 4. Deploy ReputationRegistry
  const ReputationRegistry = await hre.ethers.getContractFactory("ReputationRegistry");
  const reputation = await ReputationRegistry.deploy();
  await reputation.waitForDeployment();
  console.log("ReputationRegistry deployed to:", reputation.target);

  // 5. Deploy Vault
  const MockVault = await hre.ethers.getContractFactory("MockVault");
  const vault = await MockVault.deploy(usdc.target, reputation.target);
  await vault.waitForDeployment();
  console.log("Vault deployed to:", vault.target);

  // 6. Deploy ValidationRegistry
  const ValidationRegistry = await hre.ethers.getContractFactory("ValidationRegistry");
  const validation = await ValidationRegistry.deploy();
  await validation.waitForDeployment();
  console.log("ValidationRegistry deployed to:", validation.target);

  // 7. Deploy RiskRouter
  const MockRiskRouter = await hre.ethers.getContractFactory("MockRiskRouter");
  const router = await MockRiskRouter.deploy(vault.target, usdc.target, identity.target);
  await router.waitForDeployment();
  console.log("RiskRouter deployed to:", router.target);

  // 8. Add validators
  await validation.addValidator(0, deployer.address);
  await validation.addValidator(1, deployer.address);
  await reputation.addValidator(0, deployer.address);
  await reputation.addValidator(1, deployer.address);

  // 9. Save addresses to file (including WETH)
  const addresses = {
    usdc: usdc.target,
    weth: weth.target, // <--- Use this for WETH_ADDRESS in Java
    identity: identity.target,
    vault: vault.target,
    reputation: reputation.target,
    validation: validation.target,
    router: router.target,
  };
  
  fs.writeFileSync("deployed.json", JSON.stringify(addresses, null, 2));
  console.log("Addresses saved to deployed.json");
}

main().catch(console.error);