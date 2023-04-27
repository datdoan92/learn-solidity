# Overview

This project allow user to create a Challenge to on-chain. Anyone can take the challenge and submit the result. The result will be voted by other users who have contributed to the challenge. If the result is accepted, the user will be rewarded with the bounty.

We have 4 characters in this project:

- Creator: The one who create the challenge.
- Taker: The one who take the challenge and submit the result.
- Voter: The one who contribute to the challenge.
- Charity: The one who receive a part of the bounty (10%).

# How to play

1. Creator create a challenge with some bounty.

- User call `add` to create a challenge.
- When create new challenge, user need to deposit some amount of token to the contract. This amount will be the bounty for the challenge.

```json
{
  "_title": "string",
  "_rules": "string",
  "_duration": "uint256"
}
```

2. Contributor contribute to the challenge.
- User who want to contribute to the challenge call `contribute` to contribute to the challenge.

```json
{
  "_challengeId": "uint256"
}
```

3. Taker take the challenge.
- User call `take` to take the challenge.
- Creator can't take the challenge.
- When take the challenge, user need to pay some amount as fee to the contract.

```json
{
  "_challengeId": "uint256"
}
```

4. Taker submit the result.
- After take the challenge, user call `submit` to submit the result.

5. Voter vote for the result.
- After submit the result, contributor can vote for the taker's result.
- Contributor can vote for the result only one time.

```json
{
  "_challengeId": "uint256",
  "_taker": "address",
  "_vote": "bool"
}
```

6. Owner of the contract call `distribute` to distribute the bounty to the taker and contributors.
- If the challenge has no taker, the bounty will be returned to the contributors.
- If the challenge has taker, the bounty will be distributed to the taker and charity.

```json
{
  "_challengeId": "uint256"
}
```

# Contributing
The purpose of this repository is to learn how to create a smart contract with Solidity. If you want to contribute to this project, please create a pull request.
