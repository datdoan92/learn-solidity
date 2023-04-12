// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FundDistributor is OwnableUpgradeable {
    function distributeFunds(uint256 _prizePool, address payable[] memory _recipients) public onlyOwner {
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
