# 🌐 Universal Blockchain Reputation Layer

> A decentralized reputation protocol that unifies trust across education, logistics, fintech, and more.

## 📋 Overview

The Universal Blockchain Reputation Layer enables users, businesses, and service providers to earn trust tokens based on verified on-chain behavior. Build reputation once, use it everywhere.

## ✨ Features

- 🎯 **Multi-Sector Reputation** - Track reputation across different industries
- ✅ **Verified Interactions** - Third-party verification of reputation events
- 📊 **Sector-Specific Scoring** - Separate reputation scores per sector
- 🔐 **Decentralized Trust** - No central authority controls your reputation
- 🏆 **User Verification** - Verified badges for high-reputation users
- 🔄 **Bidirectional Feedback** - Both positive and negative reputation changes

## 🚀 Quick Start

### Register as a User

```clarity
(contract-call? .Universal-Blockchain-Reputation-Layer register-user 
  (list "logistics" "education" "fintech"))
```

### Record an Interaction

```clarity
(contract-call? .Universal-Blockchain-Reputation-Layer record-interaction 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  "logistics"
  10)
```

### Verify an Interaction (Verifiers Only)

```clarity
(contract-call? .Universal-Blockchain-Reputation-Layer verify-interaction u0)
```

## 📖 Contract Functions

### Public Functions

#### `register-user`
Register a new user with specified sectors.
- **Parameters**: `sectors (list 10 (string-ascii 20))`
- **Returns**: `(response bool uint)`

#### `record-interaction`
Record a new reputation interaction.
- **Parameters**: `to-user principal`, `sector (string-ascii 20)`, `score-change int`
- **Returns**: `(response uint uint)`

#### `verify-interaction`
Verify a recorded interaction (verifiers only).
- **Parameters**: `interaction-id uint`
- **Returns**: `(response bool uint)`

#### `verify-user`
Mark a user as verified (contract owner only).
- **Parameters**: `user principal`
- **Returns**: `(response bool uint)`

#### `add-verifier`
Add a new verifier (contract owner only).
- **Parameters**: `verifier principal`, `sectors (list 10 (string-ascii 20))`
- **Returns**: `(response bool uint)`

#### `update-reputation-threshold`
Update the reputation threshold for verification (contract owner only).
- **Parameters**: `new-threshold uint`
- **Returns**: `(response bool uint)`

### Read-Only Functions

#### `get-user-reputation`
Get a user's complete reputation data.
- **Parameters**: `user principal`
- **Returns**: User reputation object

#### `get-sector-reputation`
Get reputation for a specific sector.
- **Parameters**: `user principal`, `sector (string-ascii 20)`
- **Returns**: Sector reputation object

#### `get-verifier-info`
Get information about a verifier.
- **Parameters**: `verifier principal`
- **Returns**: Verifier object

#### `is-user-verified`
Check if a user is verified.
- **Parameters**: `user principal`
- **Returns**: `(response bool uint)`

## 🎯 Use Cases

### 🚚 Logistics & Delivery
Track on-time deliveries, package handling quality, and customer satisfaction.

### 🎓 Education
Build reputation through course completion, teaching quality, and peer reviews.

### 💰 Fintech & DeFi
Demonstrate creditworthiness through loan repayments and transaction history.

### 🛒 E-Commerce
Rate sellers and buyers based on transaction quality and communication.

## 🏗️ Architecture

```
User Registration → Interaction Recording → Verifier Validation → Reputation Update
                                                                           ↓
                                              Sector-Specific Scores + Global Score
```

## 🔒 Security Features

- Owner-only administrative functions
- Verifier authorization checks
- Interaction verification requirements
- Reputation threshold enforcement
- Protected negative score calculations

## 🧪 Testing

Run contract checks:
```bash
clarinet check
```

Run test suite:
```bash
clarinet test
```

## 📊 Data Structures

### User Profile
- `reputation-score`: Overall reputation score
- `total-interactions`: Total number of interactions
- `positive-feedbacks`: Count of positive interactions
- `negative-feedbacks`: Count of negative interactions
- `sectors`: List of sectors the user operates in
- `registered-at`: Block height of registration
- `is-verified`: Verification status

### Sector Reputation
- `score`: Sector-specific reputation score
- `interactions`: Number of interactions in this sector
- `last-updated`: Last update block height

### Interaction
- `from-user`: User who recorded the interaction
- `to-user`: User receiving reputation change
- `sector`: Sector of the interaction
- `score-change`: Reputation change amount
- `verified`: Verification status
- `timestamp`: Block height of interaction
- `verifier`: Principal who verified (if verified)

## 💡 Example Workflow

1. **Setup Verifiers** (Owner)
   ```clarity
   (contract-call? .Universal-Blockchain-Reputation-Layer add-verifier 
     'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG 
     (list "logistics"))
   ```

2. **Users Register**
   ```clarity
   (contract-call? .Universal-Blockchain-Reputation-Layer register-user 
     (list "logistics"))
   ```

3. **Record Interactions**
   ```clarity
   (contract-call? .Universal-Blockchain-Reputation-Layer record-interaction 
     'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 
     "logistics" 
     15)
   ```

4. **Verifier Validates**
   ```clarity
   (contract-call? .Universal-Blockchain-Reputation-Layer verify-interaction u0)
   ```

5. **User Gets Verified**
   ```clarity
   (contract-call? .Universal-Blockchain-Reputation-Layer verify-user 
     'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
   ```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License

## 🌟 Built With

- [Clarity](https://clarity-lang.org/) - Smart contract language
- [Clarinet](https://github.com/hirosystems/clarinet) - Development environment
- [Stacks Blockchain](https://www.stacks.co/) - Bitcoin L2

---

Made with ❤️ for the decentralized future
