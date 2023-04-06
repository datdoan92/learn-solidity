// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ChallengeFactory is OwnableUpgradeable {

    event ChallengeCreated(uint id, string title, string rules, uint256 prizePool);

    uint minPrizePool = 0.01 ether;
    uint minDuration = 1 days;

    struct Challenge {
      string title;
      string rules;
      uint16 numTakers;
      uint256 prizePool;
      uint256 startTime;
      uint256 endTime;
    }

    Challenge[] public challenges;

    mapping(address => uint256) public takerToChallenge;
    mapping(address => uint256) public creatorToChallenge;
    mapping(address => mapping(uint256 => uint256)) public userContributions;
    mapping(uint => Challenge) public challengeMap;

    modifier onlyChallengeNotEnded(uint _id) {
      require(challengeMap[_id].endTime > block.timestamp, "Challenge has ended");
      _;
    }

    function add(string memory _title, string memory _rules, uint256 duration) public payable {
      require(msg.value >= minPrizePool, "You must send some ETH to the prize pool");
      require(duration > minDuration, "Challenge must be at least 1 day long");

      uint256 startTime = block.timestamp;
      uint256 endTime = startTime + duration;
      Challenge memory newChallenge = Challenge(_title, _rules, 0, msg.value, startTime, endTime);
      challenges.push(newChallenge);
      uint challengeId = challenges.length - 1;

      creatorToChallenge[msg.sender] = challengeId;
      challengeMap[challengeId] = newChallenge;
      emit ChallengeCreated(challengeId, _title, _rules, msg.value);
    }

    function get(uint _id) public view returns (Challenge memory) {
      return challengeMap[_id];
    }

    function contribute(uint _id) public payable onlyChallengeNotEnded(_id) {
      require(msg.value >= 0, "Your contribution must be greater than 0");
      // Add contribution to user's balance for the challenge
      userContributions[msg.sender][_id] += msg.value;
      // add the contribution amount to the prize pool
      challengeMap[_id].prizePool += msg.value;
    }
}
