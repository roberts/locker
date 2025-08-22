/**
 *
 *
    Contract features:
    6 month vesting locker for each ERC20 token
    https://github.com/roberts/locker
    https://x.com/DrewRoberts
    https://t.me/BearFund
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Embedded OpenZeppelin IERC20 interface
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// Embedded OpenZeppelin SafeERC20 library
library SafeERC20 {
    using { SafeMathUpgradeable.add, SafeMathUpgradeable.sub, SafeMathUpgradeable.mul, SafeMathUpgradeable.div, SafeMathUpgradeable.mod } for uint256; // Solc 0.8.0 introduced checked arithmetic, but for safety in older versions or specific contexts, SafeMath is included.

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity `require` that checks that the return value of a message call is true.
     * Reverts with caller's message if the optional return value is not true.
     * If there is no return value, reverts with default message.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to use low level calls here, as other ERC-20 implementations might not respect the spec.
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // The return value is the result of the call (bool in most ERC-20s)
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC-20 operation did not succeed");
        }
    }
}

// Embedded OpenZeppelin SafeMath library (for SafeERC20 internal use)
// This is added for completeness, though Solidity 0.8.0+ has built-in overflow checks.
library SafeMathUpgradeable {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// Embedded OpenZeppelin Context contract (Parent of Ownable)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextAddress() internal view virtual returns (address payable) {
        return payable(address(this));
    }
}

// Embedded OpenZeppelin Ownable contract
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @title ERC20Locker
 * @dev This smart contract locks ERC-20 tokens for a fixed period.
 * Only the contract owner can initiate the vesting period for a token &
 * withdraw tokens after their lock-up has expired.
 * Direct transfers to the contract are also included in the vested balance
 * once the 'vest' function is called for that token.
 */
contract ERC20Locker is Ownable {
    using SafeERC20 for IERC20;

    // Mapping to store the timestamp when a specific ERC-20 token becomes releasable.
    mapping(address => uint256) private releaseDates;

    // Constant representing the fixed lock-up duration (6 months).
    uint256 public constant LOCK_DURATION = 182 days;

    // Event emitted when tokens are successfully vested (lock-up period initiated).
    event TokensVested(
        address indexed token,   // Address of the ERC-20 token
        uint256 amount,          // Amount of tokens vested
        uint256 releaseTime      // Timestamp when tokens become releasable
    );

    // Event emitted when tokens are successfully released (withdrawn by owner).
    event TokensReleased(
        address indexed token,   // Address of the ERC-20 token
        uint256 amount           // Amount of tokens released
    );

    // Event emitted when Ether is withdrawn from the contract.
    event EtherWithdrawn(
        address indexed recipient, // Address of the recipient (contract owner)
        uint256 amount           // Amount of Ether withdrawn
    );

    /**
     * @dev Constructor that sets the initial owner of the contract.
     * Inherits from OpenZeppelin's Ownable contract.
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Vests ERC-20 tokens, initiating a fixed lock-up period for them.
     * Can only be called by the contract owner.
     * @param _token The address of the ERC-20 token to vest.
     * @param _amount The amount of tokens to transfer from the owner and vest.
     */
    function vest(IERC20 _token, uint256 _amount) public onlyOwner {
        require(address(_token) != address(0), "ERC20Locker: Invalid token address");
        require(_amount > 0, "ERC20Locker: Amount must be greater than zero");
        require(releaseDates[address(_token)] == 0, "ERC20Locker: Vesting already set for this token");

        uint256 newReleaseTime = block.timestamp + LOCK_DURATION;
        releaseDates[address(_token)] = newReleaseTime;

        _token.safeTransferFrom(msg.sender, address(this), _amount);

        emit TokensVested(address(_token), _amount, newReleaseTime);
    }

    /**
     * @dev Releases vested ERC-20 tokens to the contract owner.
     * Can only be called by the owner after the lock-up period has expired.
     * This function transfers the *entire* balance of the specified token held by the contract.
     * @param _token The address of the ERC-20 token to release.
     */
    function release(IERC20 _token) public onlyOwner {
        require(address(_token) != address(0), "ERC20Locker: Invalid token address");
        uint256 _releaseTime = releaseDates[address(_token)];

        require(_releaseTime > 0, "ERC20Locker: Vesting not set for this token");
        require(block.timestamp >= _releaseTime, "ERC20Locker: Tokens still locked");

        uint256 contractBalance = _token.balanceOf(address(this));
        require(contractBalance > 0, "ERC20Locker: No tokens to release");

        delete releaseDates[address(_token)];

        _token.safeTransfer(owner(), contractBalance);

        emit TokensReleased(address(_token), contractBalance);
    }

    /**
     * @dev Returns the current balance of a specific ERC-20 token held by this contract.
     * @param _token The address of the ERC-20 token.
     * @return The balance of the token.
     */
    function tokenBalance(IERC20 _token) public view returns (uint256) {
        require(address(_token) != address(0), "ERC20Locker: Invalid token address");
        return _token.balanceOf(address(this));
    }

    /**
     * @dev Returns the release timestamp for a specific ERC-20 token.
     * @param _token The address of the ERC-20 token.
     * @return The Unix timestamp when the token becomes releasable, or 0 if not set.
     */
    function getReleaseDate(IERC20 _token) public view returns (uint256) {
        require(address(_token) != address(0), "ERC20Locker: Invalid token address");
        return releaseDates[address(_token)];
    }

    /**
     * @dev Sends any native currency (ETH) accidentally sent to the contract back to the owner.
     */
    function withdrawStuckETH() public onlyOwner {
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "ERC20Locker: No ETH to withdraw");

        (bool success, ) = payable(owner()).call{value: ethBalance}("");
        require(success, "ERC20Locker: ETH withdrawal failed");

        emit EtherWithdrawn(owner(), ethBalance);
    }
}
