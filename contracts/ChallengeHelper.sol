// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ChallengeFactory} from "./ChallengeFactory.sol";

contract ChallengeHelper is ChallengeFactory {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public takeFee = 0.01 ether;
    mapping(uint256 => EnumerableSet.AddressSet) internal _challengeTakers;
    mapping(uint256 => EnumerableSet.AddressSet) internal _votedContributors;
    mapping(uint256 => EnumerableMap.AddressToUintMap) internal _takerToVoteCount;

    event ChallengeTaken(uint256 indexed id, address indexed taker);
    event ChallengeVoted(uint256 indexed id, address indexed taker, address indexed voter, bool vote);
    event ChallengeDisbursed(uint256 indexed id, address[] winners, uint256 prize);

    function setFee(uint256 _fee) external onlyOwner {
        takeFee = _fee;
    }

    function take(uint256 _challengeId) external payable onlyChallengeNotEnded(_challengeId) {
        require(msg.value == takeFee, "You must pay the take fee");

        Challenge storage challenge = challenges[_getChallengeIndex(_challengeId)];
        require(!challenge.isDisbursed, "Challenge has already been disbursed");

        require(msg.sender != challenge.creator, "You cannot take your own challenge");

        EnumerableSet.AddressSet storage takers = _challengeTakers[_challengeId];
        require(!takers.contains(msg.sender), "You can only take a challenge once");

        takers.add(msg.sender);
        challenge.numTakers += 1;

        emit ChallengeTaken(_challengeId, msg.sender);
    }

    function vote(uint256 _challengeId, address _taker, bool _vote) external onlyChallengeNotEnded(_challengeId) {
        EnumerableSet.AddressSet storage takers = _challengeTakers[_challengeId];
        require(takers.contains(_taker), "You can only vote for a taker who has taken the challenge");

        require(
            _userContributions[_challengeId].get(msg.sender) > 0,
            "You must contribute to the challenge before voting"
        );

        require(!_votedContributors[_challengeId].contains(msg.sender), "You can only vote once");

        _votedContributors[_challengeId].add(msg.sender);
        uint256 voteCount = _takerToVoteCount[_challengeId].get(_taker);
        _takerToVoteCount[_challengeId].set(_taker, _vote ? voteCount + 1 : voteCount);

        emit ChallengeVoted(_challengeId, _taker, msg.sender, _vote);
    }

    function getWinners(uint256 _challengeId) public view returns (address[] memory) {
        uint256 maxVotes = 0;
        address[] memory winners = new address[](0);

        EnumerableMap.AddressToUintMap storage votes = _takerToVoteCount[_challengeId];
        for (uint256 i = 0; i < votes.length(); i++) {
            (address taker, uint256 voteCount) = votes.at(i);
            if (voteCount > maxVotes) {
                maxVotes = voteCount;
                winners[0] = taker;
            } else if (voteCount == maxVotes && voteCount > 0) {
                winners[winners.length - 1] = taker;
            }
        }
        return winners;
    }

    function distributePrizeOrRefund(uint _challengeId) external onlyOwner {
        Challenge storage challenge = challenges[_getChallengeIndex(_challengeId)];

        // if no one took the challenge, refund all contributors
        if (challenge.numTakers == 0) {
            _refund(_challengeId);
            return;
        }

        address[] memory winners = getWinners(_challengeId);
        // convert address[] to address payable[]
        address payable[] memory winnersPayable = new address payable[](winners.length);
        for (uint i = 0; i < winners.length; i++) {
            winnersPayable[i] = payable(winners[i]);
        }
        _distributeFunds(challenge.prizePool, winnersPayable);
        challenge.isDisbursed = true;
        challenge.prizePool = 0;

        emit ChallengeDisbursed(_challengeId, winners, challenge.prizePool);
    }

    function _refund(uint256 _challengeId) private {
        EnumerableMap.AddressToUintMap storage contributions = _userContributions[_challengeId];
        for (uint i = 0; i < contributions.length(); i++) {
            (address contributor, uint256 contribution) = contributions.at(i);
            payable(contributor).transfer(contribution);
        }
    }

    function _distributeFunds(uint256 _prizePool, address payable[] memory _recipients) private onlyOwner {
        require(_prizePool > 0, "Prize pool must be greater than 0");
        require(_recipients.length > 0, "Must have at least one recipient");

        uint256 numRecipients = _recipients.length;
        uint256 amountPerRecipient = _prizePool / numRecipients;

        for (uint256 i = 0; i < numRecipients; i++) {
            // Ensure that the recipient is not the zero address
            require(_recipients[i] != address(0), "Recipient address cannot be zero");

            // Transfer funds to the recipient
            _recipients[i].transfer(amountPerRecipient);
        }
    }
}
