import pkg from 'hardhat';
const { ethers } = pkg;

async function main() {
  const botAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
  const usdcAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Replace with your ACTUAL USDC address

  // 1. Define the minimal ABI so we don't need "Artifacts"
  const abi = [
    "function transfer(address to, uint256 amount) public returns (bool)",
    "function balanceOf(address account) public view returns (uint256)",
    "function mint(address to, uint256 amount) public" 
  ];

  // 2. Get the first Hardhat signer (the one who likely deployed the token)
  const [owner] = await ethers.getSigners();
  
  // 3. Attach to the contract using the ABI string
  const usdc = new ethers.Contract(usdcAddress, abi, owner);

  console.log("Attempting to fund bot...");

  try {
    // Try minting first
    await usdc.mint(botAddress, ethers.parseUnits("10000", 6));
  } catch (e) {
    console.log("Mint failed or not supported, trying direct transfer from owner...");
    // If minting isn't a thing, just transfer from the owner (who has the supply)
    await usdc.transfer(botAddress, ethers.parseUnits("5000", 6));
  }

  const bal = await usdc.balanceOf(botAddress);
  console.log(`Success! Bot Balance: ${ethers.formatUnits(bal, 6)} USDC`);
}

main().catch((error) => {
  console.error("Total failure:", error.message);
  process.exit(1);
});
