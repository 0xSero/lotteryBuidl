// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./IAAVE.sol";
import "./IERC20.sol";

contract LotterySystem {
    address public owner;
    address public oracleAddress;
    address public aaveInstanceAddress;
    address public usdcTokenAddress;

    uint public accruedInterest;
    uint public totalDeposits;

    mapping(address user => uint256 amount) public deposits;
    address[] public tickets;

    uint public drawingTime;
    bool public drawingCompleted;

    address public winner;
    bool public hasClaimedPrize;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event WinnerSelected(address indexed winner);
    event PrizeClaimed(address indexed winner, uint256 amount);
    event EmergencyWithdrawn(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(
        address _oracleAddress,
        address _aaveInstance,
        address _usdcTokenAddress
    ) {
        owner = msg.sender;
        oracleAddress = _oracleAddress;
        aaveInstanceAddress = _aaveInstance;
        usdcTokenAddress = _usdcTokenAddress;
        drawingTime = block.timestamp + 7 days;
        drawingCompleted = false;
        hasClaimedPrize = false;
    }

    function deposit() public {
        require(block.timestamp < drawingTime, "Drawing time has passed");
        uint amount = 100 * 10 ** 6; // 100 USDC (6 decimals)

        IERC20 token = IERC20(usdcTokenAddress);
        require(token.balanceOf(msg.sender) >= amount, "Insufficient USDC balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        tickets.push(msg.sender);
        totalDeposits += amount;
        deposits[msg.sender] += amount;

        depositInAave(amount);
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(block.timestamp < drawingTime, "Drawing time has passed");
        require(deposits[msg.sender] >= amount, "Insufficient deposit");

        withdrawFromAave(amount);
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;

        require(IERC20(usdcTokenAddress).transfer(msg.sender, amount), "Transfer failed");

        uint256 ticketsToRemove = (amount * getTicketCount(msg.sender)) / deposits[msg.sender];
        removeTickets(msg.sender, ticketsToRemove);

        emit Withdrawn(msg.sender, amount);
    }

    function getTicketCount(address user) public view returns (uint256 count) {
        for (uint i = 0; i < tickets.length; i++) {
            if (tickets[i] == user) {
                count++;
            }
        }
    }

    function removeTickets(address user, uint256 count) internal {
        uint256 removed = 0;
        for (uint i = tickets.length; i > 0 && removed < count; i--) {
            if (tickets[i-1] == user) {
                tickets[i-1] = tickets[tickets.length - 1];
                tickets.pop();
                removed++;
            }
        }
    }

    function claimPrize() public {
        require(block.timestamp >= drawingTime, "Drawing time has not passed");
        require(!drawingCompleted, "Drawing is already completed");
        require(tickets.length > 0, "No participants in lottery");

        uint256 randomIndex = getRandomNumber() % tickets.length;
        winner = tickets[randomIndex];
        drawingCompleted = true;

        emit WinnerSelected(winner);
    }

    function harvestInterest() internal returns (uint256) {
        IAAVE aavePool = IAAVE(aaveInstanceAddress);
        uint256 currentBalance = IERC20(usdcTokenAddress).balanceOf(address(this));

        // Withdraw all funds from Aave
        uint256 aaveBalance = currentBalance;  // This should be replaced with actual Aave balance check
        if (aaveBalance > 0) {
            aavePool.withdraw(usdcTokenAddress, aaveBalance, address(this));
        }

        // Calculate interest
        uint256 newBalance = IERC20(usdcTokenAddress).balanceOf(address(this));
        uint256 interest = newBalance > totalDeposits ? newBalance - totalDeposits : 0;

        // Redeposit principal back to Aave
        if (totalDeposits > 0) {
            depositInAave(totalDeposits);
        }

        return interest;
    }

    function sendPrize() external {
        require(drawingCompleted, "Drawing is not completed");
        require(msg.sender == winner, "Only winner can claim prize");
        require(!hasClaimedPrize, "Prize already claimed");

        uint256 interestGenerated = harvestInterest();
        require(interestGenerated > 0, "No interest generated");

        IERC20 usdcToken = IERC20(usdcTokenAddress);
        require(usdcToken.transfer(msg.sender, interestGenerated), "Transfer failed");
        hasClaimedPrize = true;

        emit PrizeClaimed(winner, interestGenerated);
    }

    function depositInAave(uint256 amount) internal {
        IERC20 token = IERC20(usdcTokenAddress);
        require(token.approve(aaveInstanceAddress, amount), "Approve failed");
        IAAVE(aaveInstanceAddress).deposit(usdcTokenAddress, amount, address(this), 0);
    }

    function withdrawFromAave(uint256 amount) internal {
        IAAVE aavePool = IAAVE(aaveInstanceAddress);
        aavePool.withdraw(usdcTokenAddress, amount, address(this));
    }

    function getRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            blockhash(block.number - 1),
            tickets.length
        )));
    }

    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= totalDeposits, "Amount exceeds total deposits");
        withdrawFromAave(amount);
        bool success = IERC20(usdcTokenAddress).transfer(owner, amount);
        require(success, "Transfer failed");
        totalDeposits -= amount;
        emit EmergencyWithdrawn(amount);
    }

    function setDrawingTime(uint256 newDrawingTime) external onlyOwner {
        require(newDrawingTime > block.timestamp, "Drawing time must be in the future");
        drawingTime = newDrawingTime;
    }
}
