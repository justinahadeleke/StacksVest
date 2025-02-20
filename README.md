# StacksVest Contract

## Overview
This smart contract is a **StacksVest contract** built using Clarity for the Stacks blockchain. It allows an owner to create vesting schedules for participants, enabling the gradual release of tokens over a predefined period. The contract ensures security, preventing unauthorized access and improper token transfers.

## Features
- **Contract Initialization:** The owner initializes the contract with token details.
- **Vesting Schedule Management:** The owner can create vesting schedules for participants.
- **Vested Token Calculation:** Participants can check the amount of vested tokens available.
- **Token Claiming:** Participants can claim vested tokens.
- **Token Transfers:** Participants can transfer claimed tokens to others.
- **Token Balance Checking:** Users can check their balance.
- **Total Supply Management:** The contract maintains a record of the total token supply.

## Constants
- `CONTRACT_OWNER`: The contract deployer who has administrative control.
- **Error Codes:**
  - `ERR_UNAUTHORIZED (u100)`: Unauthorized access.
  - `ERR_ALREADY_INITIALIZED (u101)`: Contract already initialized.
  - `ERR_NOT_INITIALIZED (u102)`: Contract not initialized.
  - `ERR_NO_VESTING_SCHEDULE (u103)`: No vesting schedule found.
  - `ERR_INSUFFICIENT_BALANCE (u104)`: Insufficient balance.
  - `ERR_INVALID_PARAMETER (u105)`: Invalid input parameter.
  - `ERR_TRANSFER_FAILED (u106)`: Token transfer failed.
  - `ERR_ALREADY_HAS_SCHEDULE (u107)`: Vesting schedule already exists.
  - `ERR_INVALID_RECIPIENT (u108)`: Invalid recipient address.

## Data Variables
- `token-name`: Stores the name of the token.
- `token-symbol`: Stores the symbol of the token.
- `token-decimals`: Stores the decimal precision of the token.
- `total-supply`: Stores the total supply of tokens in the contract.
- `contract-initialized`: A boolean to track if the contract has been initialized.

## Data Maps
- `token-balances (principal -> uint)`: Tracks token balances of users.
- `vesting-schedules (principal -> struct)`: Stores vesting schedules of users.

## Public Functions
### 1. `initialize(name (string-ascii 32), symbol (string-ascii 32), decimals uint) -> (ok true | err u101/u102)`
Initializes the contract with token details.

### 2. `create-vesting-schedule(participant principal, total-allocation uint, start-block uint, cliff-duration uint, vesting-duration uint, vesting-interval uint) -> (ok true | err u100/u102/u103/u105/u107)`
Creates a vesting schedule for a participant.

### 3. `get-vested-amount(participant principal) -> (ok uint | err u103)`
Calculates the amount of tokens vested for a participant.

### 4. `claim-vested-tokens() -> (ok uint | err u103/u104/u105)`
Allows a participant to claim their vested tokens.

### 5. `get-balance(account principal) -> (ok uint)`
Returns the token balance of a given account.

### 6. `transfer(amount uint, recipient principal) -> (ok true | err u104/u108)`
Transfers claimed tokens from one account to another.

### 7. `get-total-supply() -> (ok uint)`
Returns the total supply of tokens.

### 8. `get-name() -> (ok string-ascii 32)`
Returns the token name.

### 9. `get-symbol() -> (ok string-ascii 32)`
Returns the token symbol.

### 10. `get-decimals() -> (ok uint)`
Returns the token decimals.

### 11. `get-vesting-schedule(participant principal) -> (ok (optional struct))`
Returns the vesting schedule of a participant.

### 12. `is-initialized() -> (ok bool)`
Checks if the contract has been initialized.

## Private Functions
### `transfer-tokens(sender principal, recipient principal, amount uint) -> (ok true | err u104/u108)`
Handles internal token transfers by updating balances.

## Usage
### 1. Deploy the Contract
Ensure the contract is deployed on the Stacks blockchain.

### 2. Initialize the Contract
The contract owner must call the `initialize` function to set token details.

### 3. Create Vesting Schedules
The owner can create a vesting schedule for participants.

### 4. Claim Tokens
Participants can claim vested tokens using `claim-vested-tokens`.

### 5. Transfer Tokens
Once claimed, participants can transfer tokens using `transfer`.

## Security Considerations
- Only the contract owner can initialize and create vesting schedules.
- Prevents unauthorized access using assertions.
- Validates parameters to prevent incorrect vesting schedules.

## License
This smart contract is open-source and licensed under MIT.

