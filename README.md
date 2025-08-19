# ERC20 Token Locker Smart Contract 🔒

This Solidity smart contract provides a secure and owner-controlled mechanism for locking ERC-20 tokens for a fixed period of 6 months. It's designed to be a single-file contract, embedding necessary OpenZeppelin functionalities for `Ownable` access control and `SafeERC20` token interactions.

## 📄 Contract Overview

The `ERC20Locker` contract allows its owner to manage the vesting of various ERC-20 tokens. Once a vesting period is initiated for a specific token, all existing and newly direct-transferred balances of that token within the contract become locked for 6 months. After this period, the owner can withdraw the tokens. The contract also includes a safeguard to recover accidentally sent native currency (ETH).

## ✨ Features

* **Owner-Controlled:** Only the contract's deployer (the `owner`) can initiate token locks and withdraw funds.

* **Flexible Token Inflow:**

  * **Push Mechanism (`vest` function):** The owner can explicitly `vest` tokens by approving the contract and then calling the `vest` function. This initiates a new 6-month lock for the specified token.

  * **Direct Transfers:** Any ERC-20 tokens sent directly to the contract's address will be held. When the `vest` function is subsequently called for that token type, these directly transferred tokens are included in the total balance subject to the new 6-month lock.

* **Unified 6-Month Lock:** When `vest` is called for an ERC-20 token, it sets a 6-month lock-up period for *all* tokens of that type currently held by the contract. This means if a token was previously vested and new tokens are added (either by `vest` or direct transfer), calling `vest` again for that token will restart the 6-month timer for the entire balance.

* **Time-Based Release:** Tokens can only be withdrawn by the owner after their respective 6-month lock-up period (from the last `vest` call) has expired.

* **ETH Recovery:** A dedicated `withdrawStuckETH` function allows the owner to recover any native currency (ETH) that might be accidentally sent to the contract address.

* **Gas Efficiency:** Uses `uint252` for timestamps where possible to optimize storage and gas costs.

* **Embedded OpenZeppelin Libraries:**

  * `IERC20`: Standard interface for ERC-20 tokens.

  * `SafeERC20`: Provides safe wrappers for ERC-20 token operations, mitigating common pitfalls and reentrancy risks.

  * `SafeMathUpgradeable`: Prevents integer overflow/underflow (though Solidity 0.8.0+ has built-in checks, it's included for robustness).

  * `Context`: Base contract providing `_msgSender()` and `_msgData()`.

  * `Ownable`: Implements a simple access control mechanism, granting a single address (the `owner`) privileged functions.

## 🛠️ How to Use

### Deployment

Deploy the `ERC20Locker` contract to Base Chain (or any EVM-compatible network) using tools like Remix, Hardhat, or Truffle. The address that deploys the contract will automatically become its `owner`.

### Vesting Tokens

To vest ERC-20 tokens:

1. **Approve the Locker Contract:** The owner must first call the `approve` function on the specific ERC-20 token contract, granting the `ERC20Locker` contract permission to transfer a certain amount of tokens on their behalf.

   * **Token Contract:** `IERC20_TOKEN_ADDRESS.approve(ERC20_LOCKER_CONTRACT_ADDRESS, AMOUNT_TO_APPROVE)`

2. **Call `vest`:** The owner then calls the `vest` function on the `ERC20Locker` contract.

   * **Locker Contract:** `ERC20_LOCKER_CONTRACT_ADDRESS.vest(IERC20_TOKEN_ADDRESS, AMOUNT_TO_VEST)`

   * **Note:** `AMOUNT_TO_VEST` should be less than or equal to the `AMOUNT_TO_APPROVE`.

   * This will transfer `AMOUNT_TO_VEST` from the owner's balance to the locker contract and set a 6-month lock on the *entire* balance of that token currently held by the locker.

### Releasing Vested Tokens

To withdraw vested tokens after the lock-up period:

1. **Check Release Date:** The owner can query `getReleaseDate(IERC20_TOKEN_ADDRESS)` to see when a specific token becomes available.

2. **Call `release`:** Once `block.timestamp` is greater than or equal to the `releaseDate` for a token, the owner can call the `release` function.

   * **Locker Contract:** `ERC20_LOCKER_CONTRACT_ADDRESS.release(IERC20_TOKEN_ADDRESS)`

   * This will transfer all tokens of that type from the contract to the `owner`'s address and reset the `releaseDate` for that token to 0.

### Withdrawing Stuck ETH

If native currency (ETH) is accidentally sent to the contract:

* **Call `withdrawStuckETH`:** The owner can call this function to retrieve all ETH held by the contract.

  * **Locker Contract:** `ERC20_LOCKER_CONTRACT_ADDRESS.withdrawStuckETH()`

### Querying Contract State

* `tokenBalance(IERC20_TOKEN_ADDRESS)`: Returns the current balance of a specific ERC-20 token held by the contract.

* `getReleaseDate(IERC20_TOKEN_ADDRESS)`: Returns the Unix timestamp when a specific ERC-20 token becomes releasable. Returns 0 if no vesting period is currently set.

* `owner()`: Returns the address of the current contract owner.

* `LOCK_DURATION`: A public constant showing the lock duration in seconds.

## ⚠️ Security Considerations

* **Owner Centralization:** This contract relies heavily on the `owner`'s address. If the owner's private key is compromised, the funds in the contract are at risk. Consider using a **multi-signature wallet** (e.g., Gnosis Safe) as the owner for enhanced security in a production environment.

* **Single-Point-of-Failure for Vesting:** The design where calling `vest` for a token restarts the 6-month timer for *all* of that token's balance (including previously direct-transferred amounts) means that a new `vest` call effectively delays the release of all existing tokens of that type. This is an intentional design choice for simplicity but should be understood.

* **Gas Costs:** While optimized, complex interactions on the blockchain always incur gas costs. Users should be aware of transaction fees on Base Chain.

* **No Reentrancy:** The `release` function follows the **Checks-Effects-Interactions** pattern and internally utilizes OpenZeppelin's `SafeERC20` library to prevent common reentrancy vulnerabilities.

* **Auditing:** For any production deployment, a **professional security audit** of this contract is highly recommended to identify and mitigate potential vulnerabilities.

## 📜 Base Chain Contract 4 Airdrops

### 7 Days

### 1 Month

### 6 Months
- [0x5f24CA85A2d00F51d32a2a4CA3e8587740dA76bc](https://basescan.org/address/0x5f24ca85a2d00f51d32a2a4ca3e8587740da76bc#code)
- [0x4AeA93dB1697746723fFEa63d4a2175A6d4c2448](https://basescan.org/address/0x4aea93db1697746723ffea63d4a2175a6d4c2448#code)
- [0x01Ea23e1640F7759Cd95CF4F7E6CA81a04B42dB6](https://basescan.org/address/0x01ea23e1640f7759cd95cf4f7e6ca81a04b42db6#code)
- [0xE70D1D67A36d2eb51AA75CF8A37A495EFed96585](https://basescan.org/address/0xe70d1d67a36d2eb51aa75cf8a37a495efed96585#code)
- [0x9200991Ab56ddc082b6b662fBb3794D119e66A02](https://basescan.org/address/0x9200991ab56ddc082b6b662fbb3794d119e66a02#code)

### 1 Year

### 4 Years
