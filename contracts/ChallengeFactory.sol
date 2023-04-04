// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ChallengeFactory is OwnableUpgradeable {

    event ChallengeCreated(uint id, string title, string rules, uint256 prizePool);

    uint minPrizePool = 0.01 ether;

    struct Challenge {
      string title;
      string rules;
      uint16 numTakers;
      uint256 prizePool;
    }

    Challenge[] public challenges;

    mapping(address => uint256) public takerToChallenge;
    mapping(address => uint256) public creatorToChallenge;
    mapping(uint => Challenge) public challengeMap;
    mapping(uint => uint256) challengeToPrizePool;

    function addChallenge(string memory _title, string memory _rules) public payable {
      require(msg.value >= minPrizePool, "You must send some ETH to the prize pool");
      Challenge memory newChallenge = Challenge(_title, _rules, 0, msg.value);
      challenges.push(newChallenge);
      uint challengeId = challenges.length - 1;

      challengeToPrizePool[challengeId] = msg.value;
      creatorToChallenge[msg.sender] = challengeId;
      challengeMap[challengeId] = newChallenge;
      emit ChallengeCreated(challengeId, _title, _rules, msg.value);
    }
}
