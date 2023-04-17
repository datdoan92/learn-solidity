// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {EnumerableMapUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import {ChallengeFactory} from "./ChallengeFactory.sol";

contract ChallengeHelper is ChallengeFactory {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    uint256 public takeFee = 0.01 ether;
    mapping(address => uint256) internal _takerToChallenge;
    mapping(uint256 => mapping(address => mapping(address => bool))) internal _votedTakers;
    mapping(uint256 => EnumerableMapUpgradeable.AddressToUintMap) internal _takerToVoteCount;

    function setFee(uint256 _fee) external onlyOwner {
        takeFee = _fee;
    }

    function take(uint256 _challengeId) external payable onlyChallengeNotEnded(_challengeId)  {
        require(msg.value == takeFee, "You must pay the take fee");

        Challenge storage challenge = challenges[_challengeId - 1];

        require(msg.sender != challenge.creator, "You cannot take your own challenge");
        require(_takerToChallenge[msg.sender] != _challengeId, "You can only take a challenge once");

        _takerToChallenge[msg.sender] = _challengeId;
        challenge.numTakers += 1;
    }

    function vote(uint256 _challengeId, address _taker, bool _vote) external onlyChallengeNotEnded(_challengeId) {
        require(_takerToChallenge[_taker] == _challengeId, "You can only vote for takers of this challenge");

        require(_userContributions[_challengeId].get(msg.sender) > 0,"You must contribute to the challenge before voting");

        require(!_votedTakers[_challengeId][msg.sender][_taker], "You can only vote once for each taker");

        _votedTakers[_challengeId][msg.sender][_taker] = _vote;

        uint256 voteCount = _takerToVoteCount[_challengeId].get(_taker);
        _takerToVoteCount[_challengeId].set(_taker, _vote ? voteCount + 1 : voteCount);
    }

    function getWinners(uint256 _challengeId) public view returns (address[] memory) {
        uint256 maxVotes = 0;
        address[] memory winners = new address[](0);

        EnumerableMapUpgradeable.AddressToUintMap storage votes = _takerToVoteCount[_challengeId];
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

    function distributePrizeOrRefund(uint _challengeId) external {
        Challenge storage challenge = challenges[_challengeId];
        // check if challengeId exists
        require(challenge.creator != address(0), "Challenge does not exist");

        require(challenge.endTime < block.timestamp, "Challenge has not ended yet");

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
    }

    function _refund(uint256 _challengeId) private {
        EnumerableMapUpgradeable.AddressToUintMap storage contributions = _userContributions[_challengeId];
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

        // Ensure that the prize pool is evenly divisible among all recipients
        require(_prizePool % numRecipients == 0, "Prize pool cannot be evenly distributed among recipients");

        for (uint256 i = 0; i < numRecipients; i++) {
            // Ensure that the recipient is not the zero address
            require(_recipients[i] != address(0), "Recipient address cannot be zero");

            // Transfer funds to the recipient
            _recipients[i].transfer(amountPerRecipient);
        }
    }
}
