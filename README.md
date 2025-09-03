# Bitcoin Sovereign Identity Protocol (BSIP)

[![Stacks](https://img.shields.io/badge/Stacks-Clarity-purple.svg)](https://www.stacks.co/)
[![Bitcoin](https://img.shields.io/badge/Bitcoin-Anchored-orange.svg)](https://bitcoin.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Vitest-green.svg)](https://vitest.dev/)

A Bitcoin-native identity layer leveraging Stacks' smart contract capabilities to create tamper-proof, self-sovereign digital identities with cryptographic proof systems and decentralized reputation mechanics.

## 🎯 Vision

BSIP transforms digital identity by anchoring trust to Bitcoin's immutable foundation. This protocol enables individuals and organizations to establish verifiable credentials without relying on centralized authorities, combining Bitcoin's security with smart contract flexibility.

## ✨ Core Features

- **🔐 Self-Sovereign Identity**: Bitcoin-backed immutable identity registration
- **🕵️ Zero-Knowledge Proofs**: Privacy-preserving authentication system
- **🎫 Verifiable Credentials**: Decentralized credential issuance with cryptographic integrity
- **⭐ Reputation System**: Autonomous scoring based on network participation
- **🛡️ Quantum-Resistant Recovery**: Advanced recovery mechanisms for long-term security
- **🌐 Cross-Chain Interoperability**: Broader Bitcoin ecosystem integration

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Bitcoin Layer 1                         │
│                 (Immutable Anchor)                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                  Stacks Layer 2                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Identity    │  │ Credential  │  │ Zero-Knowledge      │ │
│  │ Registry    │  │ System      │  │ Proof Engine        │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Reputation  │  │ Recovery    │  │ Cross-Chain         │ │
│  │ Engine      │  │ System      │  │ Interoperability    │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Data Structures

- **Sovereign Identities**: Principal-mapped identity records with cryptographic hashes
- **Verifiable Credentials**: Issuer-credential mappings with expiration and revocation
- **ZK Proof Registry**: Hash-indexed proof verification system
- **Reputation Scores**: Dynamic scoring system (0-1000 range)

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) >= 2.0
- [Node.js](https://nodejs.org/) >= 18
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/davidokusanya/bitcoin-sovereign-identity.git
   cd bitcoin-sovereign-identity
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Verify installation**

   ```bash
   clarinet check
   ```

### Quick Start

1. **Start Clarinet console**

   ```bash
   clarinet console
   ```

2. **Register a sovereign identity**

   ```clarity
   (contract-call? .bitcoin-sovereign-identity register-sovereign-identity 
     0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef 
     (some 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG))
   ```

3. **Issue a verifiable credential**

   ```clarity
   (contract-call? .bitcoin-sovereign-identity issue-verifiable-credential
     'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
     0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
     u1000
     u"Professional Developer Certification")
   ```

## 🧪 Testing

### Run Test Suite

```bash
# Run all tests
npm test

# Run tests with coverage and cost analysis
npm run test:report

# Watch mode for development
npm run test:watch
```

### Test Structure

```
tests/
├── bitcoin-sovereign-identity.test.ts    # Main contract tests
├── integration/                          # Integration test suite
├── unit/                                 # Unit tests
└── fixtures/                            # Test data and mocks
```

## 📖 API Reference

### Core Functions

#### Identity Management

##### `register-sovereign-identity`

Register a new self-sovereign identity on the Bitcoin-anchored network.

```clarity
(register-sovereign-identity 
  (identity-hash (buff 32))           ;; Cryptographic identity hash
  (recovery-guardian (optional principal))) ;; Optional recovery address

;; Returns: (response bool uint)
```

**Parameters:**

- `identity-hash`: 32-byte cryptographic hash representing the identity
- `recovery-guardian`: Optional principal for identity recovery

**Example:**

```clarity
(contract-call? .bitcoin-sovereign-identity register-sovereign-identity
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  (some 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG))
```

##### `update-identity-activity`

Update the last activity timestamp for an identity.

```clarity
(update-identity-activity (identity principal))
```

#### Zero-Knowledge Proof System

##### `submit-zk-proof`

Submit a zero-knowledge proof for verification.

```clarity
(submit-zk-proof 
  (proof-hash (buff 32))              ;; Unique proof identifier
  (proof-payload (buff 1024)))        ;; Proof data (min 64 bytes)
```

##### `verify-zk-proof`

Verify a submitted zero-knowledge proof (admin only).

```clarity
(verify-zk-proof (proof-hash (buff 32)))
```

#### Credential System

##### `issue-verifiable-credential`

Issue a verifiable credential to a holder.

```clarity
(issue-verifiable-credential
  (holder principal)                   ;; Credential recipient
  (claim-hash (buff 32))              ;; Hash of the claim
  (expires-at uint)                   ;; Expiration block height
  (metadata (string-utf8 256)))       ;; Human-readable metadata
```

##### `revoke-credential`

Revoke a previously issued credential.

```clarity
(revoke-credential (credential-id uint))
```

##### `validate-credential`

Check if a credential is valid (not revoked and not expired).

```clarity
(validate-credential 
  (issuer principal) 
  (credential-id uint))
```

#### Reputation System

##### `adjust-reputation`

Adjust the reputation score of an identity (admin only).

```clarity
(adjust-reputation 
  (identity principal)                 ;; Target identity
  (adjustment int))                   ;; Score adjustment (+/-)
```

#### Recovery System

##### `execute-identity-recovery`

Execute identity recovery using the designated guardian.

```clarity
(execute-identity-recovery
  (identity principal)                 ;; Identity to recover
  (new-identity-hash (buff 32)))      ;; New identity hash
```

### Read-Only Functions

#### `get-sovereign-identity`

Retrieve complete identity information.

```clarity
(get-sovereign-identity (identity principal))
;; Returns: (optional {identity-hash: (buff 32), credentials: (list 10 principal), 
;;                     reputation-score: uint, recovery-guardian: (optional principal),
;;                     last-activity: uint, identity-status: (string-ascii 16)})
```

#### `get-verifiable-credential`

Get credential details by issuer and ID.

```clarity
(get-verifiable-credential (issuer principal) (credential-id uint))
```

#### `get-zk-proof`

Retrieve zero-knowledge proof information.

```clarity
(get-zk-proof (proof-hash (buff 32)))
```

#### `get-reputation-score`

Get the reputation score for an identity.

```clarity
(get-reputation-score (identity principal))
;; Returns: (optional uint)
```

## 🔧 Configuration

### Protocol Constants

```clarity
REPUTATION-FLOOR: u0              ;; Minimum reputation score
REPUTATION-CEILING: u1000         ;; Maximum reputation score  
MIN-EXPIRY-BLOCKS: u144           ;; ~1 day minimum credential validity
MAX-METADATA-SIZE: u256           ;; Maximum metadata length
MIN-PROOF-LENGTH: u64             ;; Minimum ZK proof payload size
DEFAULT-REPUTATION: u500          ;; Starting reputation for new identities
```

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 1000 | ERR-UNAUTHORIZED | Insufficient permissions |
| 1001 | ERR-IDENTITY-EXISTS | Identity already registered |
| 1002 | ERR-IDENTITY-NOT-FOUND | Identity not found |
| 1003 | ERR-INVALID-PROOF | Invalid zero-knowledge proof |
| 1004 | ERR-CREDENTIAL-INVALID | Invalid credential |
| 1005 | ERR-CREDENTIAL-EXPIRED | Credential has expired |
| 1006 | ERR-CREDENTIAL-REVOKED | Credential has been revoked |
| 1007 | ERR-REPUTATION-BOUNDS | Reputation score out of bounds |
| 1008 | ERR-INVALID-INPUT | Invalid input parameters |
| 1009 | ERR-INVALID-EXPIRATION | Invalid expiration time |
| 1010 | ERR-INVALID-RECOVERY | Invalid recovery configuration |
| 1011 | ERR-PROOF-DATA-INVALID | Invalid proof data |

## 🌟 Use Cases

### Lightning Network Integration

Enable Lightning Network applications with robust identity verification:

```clarity
;; Verify node operator credentials before channel opening
(contract-call? .bitcoin-sovereign-identity validate-credential
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; Node operator
  u42)                                           ;; KYC credential ID
```

### Decentralized Exchange (DEX)

Implement reputation-based trading limits:

```clarity
;; Check trader reputation before allowing high-value trades
(let ((reputation (unwrap-panic 
        (contract-call? .bitcoin-sovereign-identity get-reputation-score trader))))
  (asserts! (>= reputation u750) ERR-INSUFFICIENT-REPUTATION)
  ;; Execute trade logic
)
```

### Privacy-First Services

Use zero-knowledge proofs for anonymous verification:

```clarity
;; Verify age without revealing exact birthdate
(contract-call? .bitcoin-sovereign-identity verify-zk-proof
  0xage-proof-hash...)  ;; ZK proof of age > 18
```

## 🛠️ Development

### Contract Development

1. **Make changes to contracts**

   ```bash
   # Edit contracts/bitcoin-sovereign-identity.clar
   vim contracts/bitcoin-sovereign-identity.clar
   ```

2. **Check syntax and types**

   ```bash
   clarinet check
   ```

3. **Run tests**

   ```bash
   npm test
   ```

4. **Format code**

   ```bash
   clarinet fmt --in-place
   ```

### Adding Features

1. Create feature branch
2. Implement functionality
3. Add comprehensive tests
4. Update documentation
5. Submit pull request

### Network Deployment

#### Testnet Deployment

```bash
# Deploy to Stacks testnet
clarinet deployments apply --network testnet
```

#### Mainnet Deployment

```bash
# Deploy to Stacks mainnet
clarinet deployments apply --network mainnet
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Process

1. **Fork the repository**
2. **Create a feature branch**

   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make changes and add tests**
4. **Ensure all tests pass**

   ```bash
   npm test
   clarinet check
   ```

5. **Commit changes**

   ```bash
   git commit -m "Add amazing feature"
   ```

6. **Push to branch**

   ```bash
   git push origin feature/amazing-feature
   ```

7. **Open a Pull Request**

### Code Standards

- Follow Clarity best practices
- Maintain 100% test coverage for new features
- Use descriptive function and variable names
- Include comprehensive documentation
- Ensure security-first design principles

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Documentation**: [Stacks Documentation](https://docs.stacks.co/)
- **Clarity Language**: [Clarity Reference](https://docs.stacks.co/clarity/)
- **Stacks Network**: [Stacks.co](https://www.stacks.co/)
- **Bitcoin**: [Bitcoin.org](https://bitcoin.org/)

## 🙏 Acknowledgments

- [Stacks Foundation](https://stacks.org/) for the Layer 2 infrastructure
- [Bitcoin Core](https://bitcoincore.org/) for the foundational security layer
- [Clarity Language](https://clarity-lang.org/) for smart contract capabilities
- The open-source community for continuous innovation
