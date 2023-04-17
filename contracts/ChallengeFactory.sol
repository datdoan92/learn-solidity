// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {EnumerableMapUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

contract ChallengeFactory is OwnableUpgradeable {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    struct Challenge {
        string title;
        string rules;
        bool isDisbursed;
        uint16 numTakers;
        uint256 prizePool;
        uint256 startTime;
        uint256 endTime;
        address creator;
    }

    mapping(uint256 => EnumerableMapUpgradeable.AddressToUintMap) internal _userContributions;

    uint256 public constant MIN_PRIZE_POOL = 0.01 ether;
    uint256 public constant MIN_DURATION = 1 days;
    uint256 public constant MAX_DURATION = 15 days;
    uint256 private _challengeIdCounter = 0;

    Challenge[] public challenges;

    event ChallengeCreated(uint indexed id, string title, string rules, uint256 prizePool);

    modifier onlyChallengeNotEnded(uint256 _id) {
        Challenge memory challenge = challenges[_getChallengeIndex(_id)];
        require(challenge.endTime > block.timestamp, "Challenge has ended");
        _;
    }

    modifier onlyChallengeNotDisbursed(uint256 _id) {
        Challenge memory challenge = challenges[_getChallengeIndex(_id)];
        require(!challenge.isDisbursed, "Challenge has already been disbursed");
        _;
    }

    function _getChallengeIndex(uint256 _challengeId) internal view returns (uint256) {
        require(_challengeId > 0 && _challengeId <= challenges.length, "Invalid challenge id");
        return _challengeId - 1;
    }

    function add(string memory _title, string memory _rules, uint256 duration) external payable {
        require(msg.value >= MIN_PRIZE_POOL, "You must send some ETH to the prize pool");
        require(duration > MIN_DURATION, "Challenge must be at least 1 day long");
        require(duration < MAX_DURATION, "Challenge must be less than 15 days long");

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        challenges.push(Challenge(_title, _rules, false, 0, 0, startTime, endTime, msg.sender));

        uint256 challengeId = _challengeIdCounter++;
        contribute(challengeId);
        delete _userContributions[challengeId];
        emit ChallengeCreated(challengeId, _title, _rules, msg.value);
    }

    function contribute(uint256 _challengeId) public payable onlyChallengeNotEnded(_challengeId) {
        require(msg.value > 0, "Your contribution must be greater than 0");
        // Add contribution to user's balance for the challenge
        _userContributions[_challengeId].set(msg.sender, _userContributions[_challengeId].get(msg.sender) + msg.value);
        // add the contribution amount to the prize pool
        challenges[_getChallengeIndex(_challengeId)].prizePool += msg.value;
    }
}
