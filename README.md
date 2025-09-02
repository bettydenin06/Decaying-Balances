# 🔥 Decaying Balances Token

A unique Clarity smart contract that implements a token with balances that decay over time! Perfect for learning dynamic balance mechanics and time-based token economics.

## 🌟 Features

- 💰 **Standard Token Functions**: Mint, transfer, burn, approve
- ⏰ **Time-Based Decay**: Balances automatically decrease over time
- 🎛️ **Configurable Decay**: Adjustable decay rate and interval
- 👑 **Owner Controls**: Contract owner can modify decay parameters
- 📊 **Real-time Balance**: Get current balance with decay calculations

## 🚀 How It Works

The token implements a decay mechanism where:
- Balances decrease by a percentage over time
- Decay is calculated based on blocks passed since last update
- Default decay rate: 0.001% per interval (144 blocks ≈ 1 day)
- Balances are updated on every interaction

## 📋 Contract Functions

### Read-Only Functions
- `get-balance(owner)` - Get current balance with decay applied
- `get-name()` - Get token name
- `get-symbol()` - Get token symbol  
- `get-decimals()` - Get token decimals
- `get-total-supply()` - Get total token supply
- `get-decay-rate()` - Get current decay rate
- `get-decay-interval()` - Get decay interval in blocks
- `get-allowance(owner, spender)` - Get spending allowance

### Public Functions
- `mint(recipient, amount)` - Mint tokens (owner only)
- `transfer(amount, sender, recipient, memo)` - Transfer tokens
- `transfer-from(amount, owner, recipient, memo)` - Transfer via allowance
- `approve(spender, amount)` - Approve spending allowance
- `burn(amount)` - Burn your tokens
- `set-decay-rate(new-rate)` - Set decay rate (owner only)
- `set-decay-interval(new-interval)` - Set decay interval (owner only)

## 🛠️ Usage Examples

### Deploy and Test

```bash
clarinet console
```

```clarity
;; Mint tokens to alice
(contract-call? .decaying-balances mint 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE u1000000)

;; Check balance immediately
(contract-call? .decaying-balances get-balance 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)

;; Transfer tokens
(contract-call? .decaying-balances transfer u100000 tx-sender 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE none)

;; Check decay rate
(contract-call? .decaying-balances get-decay-rate)
```

### Modify Decay Parameters

```clarity
;; Set higher decay rate (owner only)
(contract-call? .decaying-balances set-decay-rate u2000)

;; Set shorter decay interval (owner only) 
(contract-call? .decaying-balances set-decay-interval u72)
```

## ⚙️ Configuration

- **Default Decay Rate**: 1000 (0.001% per interval)
- **Default Decay Interval**: 144 blocks (~24 hours)
- **Token Decimals**: 6
- **Max Decay Rate**: 10000 (1% per interval)

## 🎯 Learning Objectives

This contract teaches:
- ✅ Dynamic balance calculations
- ✅ Time-based smart contract logic
- ✅ Block height usage in Clarity
- ✅ Map data structure management
- ✅ Mathematical operations with decay
- ✅ Token standard implementation

## 🔧 Development

Built with Clarinet for the Stacks blockchain. The contract demonstrates advanced Clarity concepts while maintaining simplicity and gas efficiency.

## ⚠️ Important Notes

- Balances decay automatically over time
- Each interaction updates the balance to current block
- Decay is irreversible once applied
- Owner can modify decay parameters anytime
- Zero balances cannot decay further

Perfect for experimenting with time-based tokenomics! 🚀
```

**Git Commit Message:**
```
feat: implement decaying balances token with time-based decay mechanism
```

**GitHub Pull Request Title:**
```
🔥 Add Decaying Balances Token Contract - Time-Based Token Decay
```

**GitHub Pull Request Description:**
```
## 🔥 Decaying Balances Token Implementation

This PR adds a complete Clarity smart contract implementing a token with time-based balance decay functionality.

### ✨ What's Added
- **Decaying Token Contract**: Full token implementation with automatic balance decay
- **Time-Based Mechanics**: Balances decrease over configurable time intervals
- **Owner Controls**: Adjustable decay rate and interval parameters
- **Standard Token Functions**: Mint, transfer, burn, approve functionality
- **Real-time Calculations**: Dynamic balance updates based on block height

### 🎯 Key Features
- Configurable decay rate (default: 0.001% per interval)
- Block-based time intervals (default: 144 blocks ≈ 1 day)
- Automatic balance updates on every interaction
- Owner-only parameter modification
- Gas-efficient decay calculations

### 📚 Educational Value
Perfect for learning:
- Dynamic balance mechanics
- Time-based smart contract logic
- Advanced Clarity programming patterns
- Token economics with decay

Ready for testing and deployment with Clarinet! 🚀

