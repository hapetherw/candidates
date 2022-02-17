// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
  // Views
  function lastTimeRewardApplicable() external view returns (uint256);

  function rewardPerToken() external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function getRewardForDuration() external view returns (uint256);

  function viewLockingTimeStamp(address account) external view returns (uint256);

  // Mutative

  function stake(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function getReward() external;

  function quit() external;

  // Events

  event DefaultInitialization();
  event RewardAdded(uint256 reward, uint256 periodFinish);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event Recovered(
        address indexed tokenAddress,
        address indexed to,
        uint256 amount
  );
}
