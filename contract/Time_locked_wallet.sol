// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Time Locked Wallet
 * @dev A smart contract that allows users to deposit funds with time-based withdrawal restrictions
 * @author Your Name
 */
contract TimeLockedWallet {
    
    // Events
    event FundsDeposited(address indexed depositor, uint256 amount, uint256 unlockTime);
    event FundsWithdrawn(address indexed withdrawer, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    
    // State variables
    address public owner;
    
    struct TimeLock {
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }
    
    mapping(address => TimeLock[]) public userTimeLocks;
    mapping(address => uint256) public totalLockedBalance;
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validAmount() {
        require(msg.value > 0, "Amount must be greater than 0");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Deposit funds with a time lock
     * @param _lockDuration Duration in seconds to lock the funds
     */
    function depositWithTimeLock(uint256 _lockDuration) 
        external 
        payable 
        validAmount 
    {
        require(_lockDuration > 0, "Lock duration must be greater than 0");
        require(_lockDuration <= 365 days, "Lock duration cannot exceed 1 year");
        
        uint256 unlockTime = block.timestamp + _lockDuration;
        
        // Create new time lock entry
        userTimeLocks[msg.sender].push(TimeLock({
            amount: msg.value,
            unlockTime: unlockTime,
            withdrawn: false
        }));
        
        // Update total locked balance
        totalLockedBalance[msg.sender] += msg.value;
        
        emit FundsDeposited(msg.sender, msg.value, unlockTime);
    }
    
    /**
     * @dev Core Function 2: Withdraw unlocked funds
     * @param _index Index of the time lock to withdraw from
     */
    function withdrawUnlockedFunds(uint256 _index) external {
        require(_index < userTimeLocks[msg.sender].length, "Invalid time lock index");
        
        TimeLock storage timeLock = userTimeLocks[msg.sender][_index];
        
        require(!timeLock.withdrawn, "Funds already withdrawn");
        require(block.timestamp >= timeLock.unlockTime, "Funds are still locked");
        require(timeLock.amount > 0, "No funds to withdraw");
        
        uint256 amount = timeLock.amount;
        timeLock.withdrawn = true;
        totalLockedBalance[msg.sender] -= amount;
        
        // Transfer funds to the user
        payable(msg.sender).transfer(amount);
        
        emit FundsWithdrawn(msg.sender, amount);
    }
    
    
    function getUserTimeLocks(address _user) 
        external 
        view 
        returns (
            uint256[] memory amounts,
            uint256[] memory unlockTimes,
            bool[] memory withdrawn
        ) 
    {
        uint256 length = userTimeLocks[_user].length;
        amounts = new uint256[](length);
        unlockTimes = new uint256[](length);
        withdrawn = new bool[](length);
        
        for (uint256 i = 0; i < length; i++) {
            amounts[i] = userTimeLocks[_user][i].amount;
            unlockTimes[i] = userTimeLocks[_user][i].unlockTime;
            withdrawn[i] = userTimeLocks[_user][i].withdrawn;
        }
        
        return (amounts, unlockTimes, withdrawn);
    }
    
    // Additional utility functions
    
    /**
     * @dev Get the number of time locks for a user
     * @param _user Address of the user
     * @return Number of time locks
     */
    function getUserTimeLockCount(address _user) external view returns (uint256) {
        return userTimeLocks[_user].length;
    }
    
    /**
     * @dev Get available (unlocked) balance for a user
     * @param _user Address of the user
     * @return Available balance that can be withdrawn
     */
    function getAvailableBalance(address _user) external view returns (uint256) {
        uint256 available = 0;
        TimeLock[] memory locks = userTimeLocks[_user];
        
        for (uint256 i = 0; i < locks.length; i++) {
            if (!locks[i].withdrawn && block.timestamp >= locks[i].unlockTime) {
                available += locks[i].amount;
            }
        }
        
        return available;
    }
    
    /**
     * @dev Emergency withdrawal function (only owner)
     * @dev This should only be used in extreme circumstances
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        payable(owner).transfer(balance);
        
        emit EmergencyWithdrawal(owner, balance);
    }
    
    /**
     * @dev Get contract balance
     * @return Current balance of the contract
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        owner = _newOwner;
    }
}
