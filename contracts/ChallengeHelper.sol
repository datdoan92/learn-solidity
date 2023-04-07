// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ChallengeFactory} from "./ChallengeFactory.sol";

contract ChallengeHelper is ChallengeFactory {
    mapping(address => uint256) internal takerToChallenge;
    mapping(uint256 => mapping(address => mapping(address => bool)))
        internal voteTakers;

    function take(
        uint _challengeId
    ) public onlyChallengeNotEnded(_challengeId) {
        Challenge storage challenge = challenges[_challengeId];

        require(
            msg.sender != challenge.creator,
            "You cannot take your own challenge"
        );

        takerToChallenge[msg.sender] = _challengeId;
        challenge.numTakers += 1;
    }

    function vote(
        uint _challengeId,
        address _taker,
        bool _vote
    ) public onlyChallengeNotEnded(_challengeId) {
        require(
            takerToChallenge[_taker] == _challengeId,
            "You can only vote for takers of this challenge"
        );

        require(
            userContributions[msg.sender][_challengeId] > 0,
            "You must contribute to the challenge before voting"
        );

        require(
            voteTakers[_challengeId][msg.sender][address(0)] == false,
            "You have already voted for this challenge"
        );

        voteTakers[_challengeId][msg.sender][_taker] = _vote;
    }
}
