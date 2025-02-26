# Fair Lottery DApp

A decentralized lottery system that uses Aave protocol for yield generation. Users can participate by depositing USDC, and the accrued interest serves as the prize pool for the lottery winner.

## Overview

The Fair Lottery DApp is a smart contract-based lottery system with the following key features:

- Users deposit 100 USDC to participate
- Deposits are automatically invested in Aave to generate yield
- Each deposit gives the user one lottery ticket
- After the drawing time (7 days by default), a winner is randomly selected
- The winner can claim all accrued interest as their prize
- Users can withdraw their initial deposits before the drawing time
- Emergency functions for contract owner to handle unexpected situations

## Smart Contracts

### LotterySystem.sol

The main contract that handles:
- User deposits and withdrawals
- Ticket management
- Integration with Aave protocol
- Random winner selection
- Prize distribution
- Emergency functions

### IAAVE.sol

Interface for interacting with the Aave protocol, specifically for:
- Depositing assets
- Withdrawing assets

## Contract Architecture

### Key Components

1. **Deposit System**
   - Fixed deposit amount of 100 USDC
   - Automatic investment in Aave
   - Ticket issuance for each deposit

2. **Withdrawal System**
   - Pre-drawing withdrawals allowed
   - Proportional ticket removal
   - Automatic withdrawal from Aave

3. **Prize System**
   - Interest harvesting from Aave
   - Random winner selection
   - Prize claiming mechanism

4. **Security Features**
   - Owner-only emergency functions
   - Time-based restrictions
   - Balance checks and validations

### Events

- `Deposited(address indexed user, uint256 amount)`
- `Withdrawn(address indexed user, uint256 amount)`
- `WinnerSelected(address indexed winner)`
- `PrizeClaimed(address indexed winner, uint256 amount)`
- `EmergencyWithdrawn(uint256 amount)`

## Setup and Deployment

1. Install dependencies:
   ```bash
   forge install OpenZeppelin/openzeppelin-contracts
   ```

2. Configure environment variables:
   - USDC token address
   - Aave pool address
   - Oracle address (if using external randomness)

3. Deploy the contract:
   ```bash
   forge create src/LotterySystem.sol:LotterySystem --constructor-args <ORACLE_ADDRESS> <AAVE_ADDRESS> <USDC_ADDRESS>
   ```

## Security Considerations

1. **Random Number Generation**
   - Currently uses block variables for randomness
   - Consider using Chainlink VRF for better randomness

2. **Access Control**
   - Owner-only functions for emergency operations
   - Time-based restrictions for deposits and withdrawals

3. **Fund Safety**
   - All deposits are tracked
   - Emergency withdrawal function
   - Balance checks before operations

## Testing

Run the test suite:
```bash
forge test
```

## Improvements Made

1. **Functionality Completions**
   - Implemented withdraw function
   - Added emergency withdraw logic
   - Improved random number generation
   - Added proper interest calculation

2. **Security Enhancements**
   - Added OpenZeppelin's Ownable for access control
   - Added balance and allowance checks
   - Implemented proper event emission

3. **Code Quality**
   - Added SPDX license identifier
   - Improved error messages
   - Added comprehensive events
   - Enhanced code documentation

## Future Improvements

1. **Randomness**
   - Integrate with Chainlink VRF for true randomness

2. **Yield Strategy**
   - Add support for multiple yield strategies
   - Implement yield optimization

3. **User Features**
   - Add multiple ticket purchases
   - Implement tiered prizes
   - Add referral system

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
