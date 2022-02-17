// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IStakingRewards.sol";
import "./RewardsDistributionRecipient.sol";

contract StakingRewards is
  IStakingRewards,
  RewardsDistributionRecipient,
  ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */
  IERC20 public rewardsToken;
  IERC20 public stakingToken;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 public _rewardsDuration = 0;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _lockingTimeStamp;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _rewardsDistribution,
    address _rewardsToken,
    address _stakingToken
  ) RewardsDistributionRecipient(_rewardsDistribution) {
    rewardsToken = IERC20(_rewardsToken);
    stakingToken = IERC20(_stakingToken);
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view override returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view override returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e24 / periodFinish);
  }

  function earned(address account) public view override returns (uint256) {
    return
      (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e24) + rewards[account];
  }

  function getRewardForDuration() external view override returns (uint256) {
    return rewardRate * _rewardsDuration;
  }

  function viewLockingTimeStamp(address account) external view override returns (uint256) {
    return _lockingTimeStamp[account];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(uint256 amount)
    external
    override
    updateReward(msg.sender)
  {
    require(_lockingTimeStamp[msg.sender] <= 0);
    _totalSupply = _totalSupply + amount;
    _balances[msg.sender] = _balances[msg.sender] + amount;
    _lockingTimeStamp[msg.sender] = 0;
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function stakeTransferWithBalance(
    uint256 amount,
    address useraddress,
    uint256 lockingPeriod
  ) external updateReward(useraddress) {
    require(_balances[useraddress] <= 0, "Already staked by user");
    _totalSupply = _totalSupply + amount;
    _balances[useraddress] = _balances[useraddress] + amount;
    _lockingTimeStamp[useraddress] = lockingPeriod; // setting user locking ts
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(useraddress, amount);
  }

  function withdraw(uint256 amount)
    public
    override
    nonReentrant
    updateReward(msg.sender)
  {
    if (_lockingTimeStamp[msg.sender] > 0) {
      _totalSupply = _totalSupply - amount;
      _balances[msg.sender] = _balances[msg.sender] - amount;
      stakingToken.safeTransfer(msg.sender, amount);
      emit Withdrawn(msg.sender, amount);
    } else if (_lockingTimeStamp[msg.sender] <= 0) {
      _totalSupply = _totalSupply - amount;
      _balances[msg.sender] = _balances[msg.sender] - amount;
      stakingToken.safeTransfer(msg.sender, amount);
      emit Withdrawn(msg.sender, amount);
    }
  }

  function getReward() public override updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardsToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function quit() external override {
    withdraw(_balances[msg.sender]);
    getReward();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function claimRewardAmount(uint256 reward, uint256 rewardsDuration)
    external
    override
    onlyRewardsDistribution
    updateReward(address(0))
  {
    require(
      block.timestamp + rewardsDuration >= periodFinish,
      "Cannot reduce existing period"
    );

    if (block.timestamp >= periodFinish) {
      rewardRate = reward / rewardsDuration;
    } else {
      uint256 remaining = periodFinish - block.timestamp;
      uint256 leftover = remaining * rewardRate;
      rewardRate = (reward + leftover) / rewardsDuration;
    }

    uint256 balance = rewardsToken.balanceOf(address(this));
    require(
      rewardRate <= balance / rewardsDuration,
      "Provided reward too high"
    );

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + rewardsDuration;
    _rewardsDuration = rewardsDuration;
    emit RewardAdded(reward, periodFinish);
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }
}

contract StakingRewardsFactory is Ownable {

  address public rewardsToken;
  uint256 public stakingRewardsGenesis;

  address[] public stakingTokens;

  struct StakingRewardsInfo {
    address stakingRewards;
    uint256 rewardAmount;
    uint256 duration;
  }

  mapping(address => StakingRewardsInfo)
    public stakingRewardsInfoByStakingToken;

  constructor(address _rewardsToken, uint256 _stakingRewardsGenesis)
  {

    rewardsToken = _rewardsToken;
    stakingRewardsGenesis = _stakingRewardsGenesis;
  }

  function deploy(
    address stakingToken,
    uint256 rewardAmount,
    uint256 rewardsDuration
  ) public  {
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[
      stakingToken
    ];
    require(
      info.stakingRewards == address(0),
      "StakingRewardsFactory::deploy: already deployed"
    );

    info.stakingRewards = address(
      new StakingRewards(address(this), rewardsToken, stakingToken)
    );
    info.rewardAmount = rewardAmount;
    info.duration = rewardsDuration;
    stakingTokens.push(stakingToken);
  }

  function update(
    address stakingToken,
    uint256 rewardAmount,
    uint256 rewardsDuration
  ) public onlyOwner {
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[
      stakingToken
    ];
    require(
      info.stakingRewards != address(0),
      "StakingRewardsFactory::update: not deployed"
    );

    info.rewardAmount = rewardAmount;
    info.duration = rewardsDuration;
  }

  function claimRewardAmounts() public {
    require(
      stakingTokens.length > 0,
      "StakingRewardsFactory::claimRewardAmounts: called before any deploys"
    );
    for (uint256 i = 0; i < stakingTokens.length; i++) {
      claimRewardAmount(stakingTokens[i]);
    }
  }

  function claimRewardAmount(address stakingToken) public {
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[
      stakingToken
    ];
    require(
      info.stakingRewards != address(0),
      "StakingRewardsFactory::claimRewardAmount: not deployed"
    );

    if (info.rewardAmount > 0 && info.duration > 0) {
      uint256 rewardAmount = info.rewardAmount;
      uint256 duration = info.duration;
      info.rewardAmount = 0;
      info.duration = 0;

      require(
        IERC20(rewardsToken).transfer(info.stakingRewards, rewardAmount),
        "StakingRewardsFactory::claimRewardAmount: transfer failed"
      );
      StakingRewards(info.stakingRewards).claimRewardAmount(
        rewardAmount,
        duration
      );
    }
  }

  function pullExtraTokens(address token, uint256 amount) external {
    IERC20(token).transfer(msg.sender, amount);
  }
}
