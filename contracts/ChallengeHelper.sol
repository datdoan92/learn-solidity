// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {EnumerableMapUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import {ChallengeFactory} from "./ChallengeFactory.sol";
import {FundDistributor} from "./FundDistributor.sol";

contract ChallengeHelper is ChallengeFactory {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    FundDistributor private _distributor;
    mapping(address => uint256) internal _takerToChallenge;
    mapping(uint256 => mapping(address => mapping(address => bool))) internal _votedTakers;
    mapping(uint256 => EnumerableMapUpgradeable.AddressToUintMap) internal _countedVotes;

    function initialize() public initializer {
        __Ownable_init();
        _distributor = new FundDistributor();
    }

    function take(uint _challengeId) external onlyChallengeNotEnded(_challengeId) {
        Challenge storage challenge = challenges[_challengeId];

        require(msg.sender != challenge.creator, "You cannot take your own challenge");

        _takerToChallenge[msg.sender] = _challengeId;
        challenge.numTakers += 1;
    }

    function vote(uint _challengeId, address _taker, bool _vote) external onlyChallengeNotEnded(_challengeId) {
        require(_takerToChallenge[_taker] == _challengeId, "You can only vote for takers of this challenge");

        require(
            _userContributions[_challengeId].get(msg.sender) > 0,
            "You must contribute to the challenge before voting"
        );

        require(
            _votedTakers[_challengeId][msg.sender][address(0)] == false,
            "You have already voted for this challenge"
        );

        _votedTakers[_challengeId][msg.sender][_taker] = _vote;

        uint256 voteCount = _countedVotes[_challengeId].get(_taker);
        _countedVotes[_challengeId].set(_taker, _vote ? voteCount + 1 : voteCount);
    }

    function distributePrizeOrRefund(uint _challengeId) external {
        Challenge storage challenge = challenges[_challengeId];
        // check if challengeId exists
        require(challenge.creator != address(0), "Challenge does not exist");

        require(challenge.endTime < block.timestamp, "Challenge has not ended yet");

        // if no one took the challenge, refund all contributors
        if (challenge.numTakers == 0) {
            EnumerableMapUpgradeable.AddressToUintMap storage contributions = _userContributions[_challengeId];

            for (uint i = 0; i < contributions.length(); i++) {
                (address contributor, uint256 contribution) = contributions.at(i);
                payable(contributor).transfer(contribution);
            }

            return;
        }

        EnumerableMapUpgradeable.AddressToUintMap storage votes = _countedVotes[_challengeId];
        // find the taker with the most votes
        // address[] memory winners;
        // uint256 maxVotes = 0;
        // for (uint i = 0; i < votes.length(); i++) {
        //     (address taker, uint256 voteCount) = votes.at(i);

        // }
        // _distributor.distributeFunds(challenge.prizePool, challenge.numTakers);
    }
}
