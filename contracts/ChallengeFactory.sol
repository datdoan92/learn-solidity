// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {EnumerableMapUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract ChallengeFactory is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    struct Challenge {
        string title;
        string rules;
        uint16 numTakers;
        uint256 prizePool;
        uint256 startTime;
        uint256 endTime;
        address creator;
    }

    mapping(uint256 => EnumerableMapUpgradeable.AddressToUintMap) internal _userContributions;

    uint256 public constant MIN_PRIZE_POOL = 0.01 ether;
    uint256 public constant MIN_DURATION = 1 days;
    Challenge[] public challenges;

    event ChallengeCreated(uint id, string title, string rules, uint256 prizePool);

    modifier onlyChallengeNotEnded(uint256 _id) {
        require(challenges[_id].endTime > block.timestamp, "Challenge has ended");
        _;
    }

    function clearUserContributions(uint256 _challengeId) external onlyOwner {
        require(challenges[_challengeId].endTime <= block.timestamp, "Challenge has not ended yet");
        delete _userContributions[_challengeId];
    }

    function add(string memory _title, string memory _rules, uint256 duration) external payable {
        require(msg.value >= MIN_PRIZE_POOL, "You must send some ETH to the prize pool");
        require(duration > MIN_DURATION, "Challenge must be at least 1 day long");

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        challenges.push(Challenge(_title, _rules, 0, msg.value, startTime, endTime, msg.sender));
        uint challengeId = challenges.length - 1;

        contribute(challengeId);
        emit ChallengeCreated(challengeId, _title, _rules, msg.value);
    }

    function contribute(uint256 _challengeId) public payable onlyChallengeNotEnded(_challengeId) {
        require(msg.value > 0, "Your contribution must be greater than 0");
        // Add contribution to user's balance for the challenge
        uint256 totalContribution = _userContributions[_challengeId].get(msg.sender).add(msg.value);
        _userContributions[_challengeId].set(msg.sender, totalContribution);
        // add the contribution amount to the prize pool
        challenges[_challengeId].prizePool += msg.value;
    }
}
