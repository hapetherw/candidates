import hre from "hardhat";
import { load, save } from "./utils"
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
    const tokenContractAddress = (await load('TokenContract')).address
    await hre.run("verify:verify", {
        address: tokenContractAddress,
        constructorArguments: [
            'LOOP',
            'LOOP',
            process.env.FEE_PERCENTAGE, 
            process.env.BURN_PERCENTAGE,
            process.env.FUND_ADDRESS
        ],
    });

    const stakingRewardsContractAddress = (await load('StakingRewardsContract')).address
    await hre.run("verify:verify", {
        address: stakingRewardsContractAddress,
        constructorArguments: [
            process.env.REWARDS_DISTRIBUTION_ADDRESS,
            process.env.REWARDS_TOKEN,
            process.env.STAKING_TOKEN
        ],
    });


    // const rewardsFactoryContractAddress = (await load('StakingRewardsFactoryContract')).address
    // await hre.run("verify:verify", {
    //     address: rewardsFactoryContractAddress,
    //     constructorArguments: [
    //         process.env.REWARDS_TOKEN,
    //         0
    //     ],
    // });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});