import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import { save } from "./utils"

dotenv.config();

async function main() {
  const TokenFactory = await ethers.getContractFactory("Token");
  const tokenContract = await TokenFactory.deploy(
    'LOOP', 
    'LOOP', 
    process.env.FEE_PERCENTAGE, 
    process.env.BURN_PERCENTAGE,
    process.env.FUND_ADDRESS
  );
  await tokenContract.deployed();
  console.log('TokenContract address:', tokenContract.address);
  console.log('TokenContract hash:', tokenContract.deployTransaction.hash);

  await save('TokenContract', {
    address: tokenContract.address
  });

  const stakingRewardsFactory = await ethers.getContractFactory("StakingRewards");
  const stakingRewardsContract = await stakingRewardsFactory.deploy(
    process.env.REWARDS_DISTRIBUTION_ADDRESS,
    process.env.REWARDS_TOKEN,
    process.env.STAKING_TOKEN
  );
  await stakingRewardsContract.deployed();
  console.log('stakingRewardsContract address:', stakingRewardsContract.address);
  console.log('stakingRewardsContract hash:', stakingRewardsContract.deployTransaction.hash);

  await save('StakingRewardsContract', {
    address: stakingRewardsContract.address
  });

  // const stakingRewardsFactory1 = await ethers.getContractFactory("StakingRewardsFactory");
  // const stakingRewardsContract1 = await stakingRewardsFactory1.deploy(
  //   process.env.REWARDS_TOKEN,
  //   0
  // );
  // await stakingRewardsContract.deployed();
  // console.log('stakingRewardsFactoryContract address:', stakingRewardsContract1.address);
  // console.log('stakingRewardsFactoryContract hash:', stakingRewardsContract1.deployTransaction.hash);

  // await save('StakingRewardsFactoryContract', {
  //   address: stakingRewardsContract1.address
  // });
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });