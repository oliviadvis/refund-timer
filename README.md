# Refund Timer Smart Contract

A time-locked smart contract built on the Stacks blockchain that enables delayed refund processing. Users can deposit STX tokens with a specified time delay, after which they can claim their refund.

## Overview

The Refund Timer contract provides a secure mechanism for creating time-locked deposits that can be refunded after a predetermined delay period. This can be useful for escrow services, delayed payments, or any scenario where funds need to be held for a specific duration.

## Features

- **Time-locked Deposits**: Users can deposit STX with custom delay periods
- **Automatic Refund Processing**: Funds are automatically released after the timeout period
- **Early Cancellation**: Users can cancel and retrieve funds before the timeout (if needed)
- **Single Request per User**: Prevents duplicate requests to maintain clarity
- **Emergency Controls**: Contract owner can pause operations if necessary
- **Transparent Tracking**: Full visibility of request status and timing

## Contract Functions

### Public Functions

#### `create-refund-request (amount uint) (delay-blocks uint)`
Creates a new refund request with the specified amount and delay.

- **Parameters**:
  - `amount`: Amount of STX to deposit (in microSTX)
  - `delay-blocks`: Number of blocks to wait before refund is available
- **Requirements**:
  - User must have sufficient STX balance
  - No existing active request for the user
  - Amount must be greater than 0
- **Returns**: Block height when refund becomes available

#### `claim-refund ()`
Claims the refund after the timeout period has elapsed.

- **Requirements**: Timeout period must have passed
- **Action**: Transfers deposited STX back to the user

#### `cancel-refund-request ()`
Cancels an active refund request before the timeout period.

- **Requirements**: Must be called before timeout period
- **Action**: Immediately returns deposited STX to the user

#### `toggle-contract-active ()`
Emergency function to pause/unpause the contract (owner only).

### Read-Only Functions

#### `get-refund-request (requester principal)`
Returns details of a refund request for a specific user.

#### `is-refund-ready (requester principal)`
Checks if a refund is ready to be claimed.

#### `get-blocks-until-refund (requester principal)`
Returns the number of blocks remaining until refund is available.

#### `get-contract-status ()`
Returns contract status including active state, owner, and current block.

#### `get-contract-balance ()`
Returns the total STX balance held by the contract.

## Usage Example

### Creating a Refund Request

```clarity
;; Deposit 1000 STX with a 144-block delay (~24 hours)
(contract-call? .refund-timer create-refund-request u1000000000 u144)
```

### Checking Request Status

```clarity
;; Check if refund is ready
(contract-call? .refund-timer is-refund-ready tx-sender)

;; Get remaining blocks
(contract-call? .refund-timer get-blocks-until-refund tx-sender)
```

### Claiming Refund

```clarity
;; Claim refund after timeout period
(contract-call? .refund-timer claim-refund)
```

## Time Calculations

The contract uses Stacks block height for timing:
- **1 block ≈ 10 minutes**
- **144 blocks ≈ 24 hours**
- **1008 blocks ≈ 1 week**
- **4320 blocks ≈ 1 month**

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR_UNAUTHORIZED | Contract is paused or unauthorized access |
| 101 | ERR_ALREADY_EXISTS | User already has an active refund request |
| 102 | ERR_NOT_FOUND | No refund request found for user |
| 103 | ERR_TIMEOUT_NOT_REACHED | Timeout period has not elapsed yet |
| 104 | ERR_INSUFFICIENT_FUNDS | User doesn't have enough STX |
| 105 | ERR_INVALID_AMOUNT | Amount must be greater than 0 |

