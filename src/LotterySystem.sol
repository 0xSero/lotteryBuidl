pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./IAAVE.sol";

contract LotterySystem {
    address public oracleAddress;
    address public aaveInstance;

    address public usdcTokenAddress;

    uint public accruedInterest;
    uint public totalDeposits;
    
    mapping(address user => uint256 amount) public deposits;
    address[] public tickets; //array of ticket holders. 

    uint public drawingTime;
    bool public drawingCompleted;

    address public winner;
    bool public hasClaimedPrize = false;

    constructor(address _oracleAddress, address _aaveInstance, address _usdcTokenAddress) {
        oracleAddress = _oracleAddress;
        aaveInstance = _aaveInstance;
        usdcTokenAddress = _usdcTokenAddress;
        drawingTime = block.timestamp + 7 days;
        drawingCompleted = false;
    }

    function deposit() public {
        require(block.timestamp < drawingTime, "Drawing time has passed");
        uint amount = 100;
        // update deposits for the user
        ERC20 usdcToken = ERC20(usdcTokenAddress); 
        usdcToken.transferFrom(msg.sender, address(this), amount);

        // add ticket to the array
        tickets.push(msg.sender);

        totalDeposits += amount;
        deposits[msg.sender] += amount;
        //send to aave for that yummy yummy yield

        depositInAave(amount);
    }

    function withdraw(uint256 amount) public {
        // TODO: Implement withdraw logic
    }

    function claimPrize(uint256 ticketId) public {
        // get a random number 
        // use random number to determine the winner 
        require(!drawingCompleted, "Drawing is already completed. No more claims.");
        winner = tickets[getRandomNumber()];
        drawingCompleted = true;
    }

    function harvestInterest() internal returns (uint256) {
        //harvest interest from aave
        //return interest
        return 100;
    }

    function sendPrize() external{
        require(drawingCompleted, "Drawing is not completed. No prize can be sent.");
        require(msg.sender == winner, "You are not the winner. No prize can be sent.");
        require(hasClaimedPrize == false, "You have already claimed the prize. No more claims.");
        
        //harvest interest
        uint interestGenerated = harvestInterest();
        ERC20 usdcToken = ERC20(usdcTokenAddress); 
        usdcToken.transfer(winner, interestGenerated);
        hasClaimedPrize = true;
    }
    
    function depositInAave(uint256 amount) internal {
        IAAVE aavePool = IAAVE(aaveInstanceAddress);
        aavePool.deposit(usdcTokenAddress, amount, address(this), 0);
    }

    function withdrawFromAave(uint256 amount) internal {
        IAAVE aavePool = IAAVE(aaveInstanceAddress);
        aavePool.withdraw(usdcTokenAddress, amount, address(this));
    }

    function getRandomNumber() internal pure returns (uint256) {
        return 6;
    }

    function emergencyWithdraw(uint256 amount) external {
        //only owner can call this function
        // TODO: Implement emergency withdraw logic
    }

}