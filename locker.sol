// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // Context is implicitly used by Ownable

/**
 * @title ERC20Locker
 * @dev A smart contract that locks ERC-20 tokens for a fixed period (6 months).
 * Only the contract owner can initiate the vesting period for a token and
 * withdraw tokens after their lock-up has expired.
 * Direct transfers to the contract are also included in the vested balance
 * once the 'vest' function is called for that token.
 */
contract ERC20Locker is Ownable {
    using SafeERC20 for IERC20;

    // Mapping to store the timestamp when a specific ERC-20 token becomes releasable.
    // Key: ERC-20 token address
    // Value: Unix timestamp (seconds since epoch) when the token is unlocked.
    mapping(address => uint256) private releaseDates;

    // Constant representing the fixed lock-up duration (approximately 6 months in seconds).
    // Using 182 days as a common approximation for 6 months to maintain consistency.
    uint256 public constant LOCK_DURATION = 182 days; // 182 days * 24 hours/day * 60 minutes/hour * 60 seconds/minute

    // Event emitted when tokens are successfully vested (lock-up period initiated).
    event TokensVested(
        address indexed token,   // Address of the ERC-20 token
        address indexed sender,  // Address of the sender (contract owner)
        uint256 amount,          // Amount of tokens vested
        uint256 releaseTime      // Timestamp when tokens become releasable
    );

    // Event emitted when tokens are successfully released (withdrawn by owner).
    event TokensReleased(
        address indexed token,   // Address of the ERC-20 token
        address indexed recipient, // Address of the recipient (contract owner)
        uint256 amount           // Amount of tokens released
    );

    /**
     * @dev Constructor that sets the initial owner of the contract.
     * Inherits from OpenZeppelin's Ownable contract.
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Vests ERC-20 tokens, initiating a 6-month lock-up period for them.
     * The contract owner must first approve this contract to spend the tokens.
     * Any existing balance of the specified token in this contract (including
     * direct transfers) will become subject to this new 6-month lock.
     * @param _token The address of the ERC-20 token to vest.
     * @param _amount The amount of tokens to transfer from the owner and vest.
     */
    function vest(IERC20 _token, uint256 _amount) public onlyOwner {
        // Ensure the amount to vest is greater than zero.
        require(_amount > 0, "ERC20Locker: Amount must be greater than zero");
        // Ensure the token address is not the zero address.
        require(address(_token) != address(0), "ERC20Locker: Invalid token address");

        // Use SafeERC20 to securely transfer tokens from the owner to this contract.
        // The owner must have previously called approve() on the ERC-20 token contract.
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        // Calculate the new release time based on the current block timestamp and LOCK_DURATION.
        uint256 newReleaseTime = block.timestamp + LOCK_DURATION;

        // Update the release date for this specific token. This effectively resets
        // the lock-up period for ALL current tokens of this type in the contract.
        releaseDates[address(_token)] = newReleaseTime;

        // Emit an event to log the vesting action.
        emit TokensVested(address(_token), msg.sender, _amount, newReleaseTime);
    }

    /**
     * @dev Releases (withdraws) vested ERC-20 tokens to the contract owner.
     * This function can only be called by the contract owner.
     * Tokens can only be released if their 6-month lock-up period has expired.
     * After successful release, the vesting period for this token is reset (release date set to 0).
     * @param _token The address of the ERC-20 token to release.
     */
    function release(IERC20 _token) public onlyOwner {
        // Ensure the token address is not the zero address.
        require(address(_token) != address(0), "ERC20Locker: Invalid token address");

        // Retrieve the stored release time for this token.
        uint256 _releaseTime = releaseDates[address(_token)];

        // Ensure a vesting period has been set for this token.
        require(_releaseTime > 0, "ERC20Locker: Vesting not set for this token");
        // Ensure the current time is past or equal to the release time.
        require(block.timestamp >= _releaseTime, "ERC20Locker: Tokens still locked");

        // Get the total balance of the specified token held by this contract.
        // This includes tokens transferred via 'vest' and any direct transfers.
        uint256 contractBalance = _token.balanceOf(address(this));

        // Ensure there are tokens to release.
        require(contractBalance > 0, "ERC20Locker: No tokens to release");

        // IMPORTANT: Reset the release date BEFORE transferring tokens (Checks-Effects-Interactions pattern).
        // This prevents reentrancy issues and ensures the state is updated correctly before external calls.
        releaseDates[address(_token)] = 0;

        // Use SafeERC20 to securely transfer all available tokens to the contract owner.
        _token.safeTransfer(owner(), contractBalance);

        // Emit an event to log the release action.
        emit TokensReleased(address(_token), owner(), contractBalance);
    }

    /**
     * @dev Returns the current balance of a specific ERC-20 token held by this contract.
     * @param _token The address of the ERC-20 token.
     * @return The balance of the token.
     */
    function tokenBalance(IERC20 _token) public view returns (uint256) {
        // Ensure the token address is not the zero address.
        require(address(_token) != address(0), "ERC20Locker: Invalid token address");
        return _token.balanceOf(address(this));
    }

    /**
     * @dev Returns the release timestamp for a specific ERC-20 token.
     * A return value of 0 means no vesting period is currently set for this token.
     * @param _token The address of the ERC-20 token.
     * @return The Unix timestamp when the token becomes releasable, or 0 if not set.
     */
    function getReleaseDate(IERC20 _token) public view returns (uint256) {
        // Ensure the token address is not the zero address.
        require(address(_token) != address(0), "ERC20Locker: Invalid token address");
        return releaseDates[address(_token)];
    }

    /**
     * @dev Sends any native currency (ETH) accidentally sent to the contract back to the owner.
     * This function can only be called by the contract owner.
     * Uses a low-level call to ensure gas forwarding is handled correctly.
     */
    function withdrawStuckETH() public onlyOwner {
        uint256 ethBalance = address(this).balance;
        // Ensure there is ETH to withdraw.
        require(ethBalance > 0, "ERC20Locker: No ETH to withdraw");

        // Perform a low-level call to send ETH to the owner.
        // This method is preferred over `transfer` or `send` as it forwards all available gas.
        (bool success, ) = payable(owner()).call{value: ethBalance}("");
        // Ensure the transfer was successful.
        require(success, "ERC20Locker: ETH withdrawal failed");

        // Emit an event to log the ETH withdrawal.
        emit EtherWithdrawn(owner(), ethBalance);
    }
}
