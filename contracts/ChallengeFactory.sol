// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ChallengeFactory is OwnableUpgradeable {
    event ChallengeCreated(
        uint id,
        string title,
        string rules,
        uint256 prizePool
    );

    uint256 private _minPrizePool = 0.01 ether;
    uint256 private _minDuration = 1 days;

    struct Challenge {
        string title;
        string rules;
        uint16 numTakers;
        uint256 prizePool;
        uint256 startTime;
        uint256 endTime;
        address creator;
    }

    Challenge[] public challenges;

    mapping(address => mapping(uint256 => uint256)) internal userContributions;

    modifier onlyChallengeNotEnded(uint256 _id) {
        require(
            challenges[_id].endTime > block.timestamp,
            "Challenge has ended"
        );
        _;
    }

    function add(
        string memory _title,
        string memory _rules,
        uint256 duration
    ) public payable {
        require(
            msg.value >= _minPrizePool,
            "You must send some ETH to the prize pool"
        );
        require(
            duration > _minDuration,
            "Challenge must be at least 1 day long"
        );

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        Challenge memory newChallenge = Challenge(
            _title,
            _rules,
            0,
            msg.value,
            startTime,
            endTime,
            msg.sender
        );
        challenges.push(newChallenge);
        uint challengeId = challenges.length - 1;

        contribute(challengeId);
        emit ChallengeCreated(challengeId, _title, _rules, msg.value);
    }

    function get(uint256 _challengeId) public view returns (Challenge memory) {
        return challenges[_challengeId];
    }

    function contribute(
        uint256 _challengeId
    ) public payable onlyChallengeNotEnded(_challengeId) {
        require(msg.value >= 0, "Your contribution must be greater than 0");
        // Add contribution to user's balance for the challenge
        userContributions[msg.sender][_challengeId] += msg.value;
        // add the contribution amount to the prize pool
        challenges[_challengeId].prizePool += msg.value;
    }
}
