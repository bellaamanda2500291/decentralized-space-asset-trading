# 🚀 Decentralized Space Asset Trading Platform

A comprehensive blockchain-based system for managing and trading orbital space assets using Stacks smart contracts.

## 📋 Overview

This platform enables the creation of a decentralized marketplace for space-based assets, supporting the growing space economy with blockchain technology. The system consists of two main smart contracts that work together to provide a complete orbital asset management and trading solution.

## 🛰️ Core Components

### Orbital Asset Registry (`orbital-asset-registry.clar`)
Manages the registration, ownership, and lifecycle of space-based assets.

**Key Features:**
- 3D orbital coordinate validation and tracking (±1,000,000 range)
- Asset ownership and transfer functionality
- Operational status monitoring
- Orbital zone registration with regulatory compliance  
- Registration fee system with STX payments
- Asset metadata and launch date tracking

### Space Asset Trading Exchange (`space-asset-trading-exchange.clar`)
Facilitates secure peer-to-peer trading of registered orbital assets.

**Key Features:**
- Buy/sell order creation with configurable expiry dates
- Escrow system for secure transaction handling
- Trade execution with automatic settlement
- Asset valuation tracking and price history
- Trading fee collection (2.5% default rate)
- Comprehensive trade history and audit trail

## ✅ Features Implemented

- ✅ **Asset Registration**: Register orbital assets with 3D coordinates
- ✅ **Ownership Management**: Track and transfer asset ownership
- ✅ **P2P Trading**: Secure trading with escrow protection
- ✅ **Market Valuation**: Real-time asset pricing and history
- ✅ **Regulatory Compliance**: Orbital zone management
- ✅ **Revenue Tracking**: Platform fees and revenue analytics

## 🔍 Quality Assurance

- ✅ **Clarinet Validated**: Both contracts pass all checks with zero errors
- ✅ **Production Ready**: Comprehensive error handling and access controls
- ✅ **Security Focused**: Input validation and authorization checks
- ✅ **Test Coverage**: TypeScript testing infrastructure included

## 🧪 Development Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- Node.js 16+ for running tests
- Git for version control

### Installation
```bash
# Clone the repository
git clone https://github.com/your-username/decentralized-space-asset-trading.git
cd decentralized-space-asset-trading

# Install dependencies
npm install

# Run contract validation
clarinet check

# Run tests
npm test

# Run tests with coverage
npm run test:report
```

### Testing
```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Generate coverage report
npm run test:report
```

## 📚 Contract Documentation

### Asset Registration
```clarity
;; Register a new orbital asset
(register-orbital-asset 
  "SATELLITE"                    ;; asset-type
  { x: 42164, y: 0, z: 0 }      ;; orbital-coordinates (km)
  u500                          ;; mass-kg
  u1640995200                   ;; launch-date (unix timestamp)
  "operational"                 ;; operational-status
  "Communication satellite")    ;; metadata
```

### Trading Operations
```clarity
;; Create a sell order
(create-sell-order 
  0x1234...                     ;; asset-id
  u1000000000                   ;; price (1000 STX in microstacks)
  u144                          ;; expiry-duration (blocks)
  "Immediate transfer")         ;; trade-conditions

;; Execute a sell order
(execute-sell-order 0x5678...)  ;; order-id
```

## 🔒 Security Features

- **Access Control**: Proper authorization checks for all operations
- **Input Validation**: Comprehensive validation for coordinates and parameters
- **Escrow System**: Secure handling of funds during trading
- **Error Handling**: Descriptive error codes and proper error propagation
- **Audit Trail**: Complete transaction and ownership history

## 🌌 Use Cases

- **Satellite Trading**: Buy and sell communication, navigation, and Earth observation satellites
- **Space Station Components**: Trade modules, solar panels, and other space infrastructure
- **Asteroid Mining Rights**: Register and trade rights to asteroid resources
- **Orbital Real Estate**: Manage valuable orbital positions and slots
- **Space Debris Cleanup**: Trade cleanup contracts and responsibilities

## 🔧 Architecture

```
┌─────────────────────────────────────┐
│         Frontend DApp               │
├─────────────────────────────────────┤
│         Stacks Web3 API            │
├─────────────────────────────────────┤
│  Orbital Asset Registry Contract    │
│  ┌─────────────────────────────────┐│
│  │ • Asset Registration           ││
│  │ • Ownership Management         ││
│  │ • Coordinate Validation        ││
│  │ • Zone Management              ││
│  └─────────────────────────────────┘│
├─────────────────────────────────────┤
│  Space Asset Trading Exchange      │
│  ┌─────────────────────────────────┐│
│  │ • Order Management             ││
│  │ • Trade Execution              ││
│  │ • Escrow System                ││
│  │ • Valuation Tracking           ││
│  └─────────────────────────────────┘│
├─────────────────────────────────────┤
│         Stacks Blockchain           │
└─────────────────────────────────────┘
```

## 📊 Economic Model

- **Registration Fee**: 1 STX per asset registration
- **Trading Fee**: 2.5% of transaction value
- **Zone Access Fee**: Variable based on orbital zone
- **Platform Revenue**: Accumulated from trading and registration fees

## 🚀 Deployment

### Testnet Deployment
```bash
# Deploy to testnet
clarinet deployments generate --testnet

# Apply deployment
clarinet deployments apply --testnet
```

### Mainnet Deployment
```bash
# Deploy to mainnet (requires mainnet configuration)
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## 📈 Roadmap

- [ ] **Phase 1**: Core functionality (✅ Complete)
- [ ] **Phase 2**: Advanced trading features (auctions, options)
- [ ] **Phase 3**: Integration with real orbital data APIs
- [ ] **Phase 4**: Mobile app and advanced UI
- [ ] **Phase 5**: Cross-chain compatibility

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚖️ Legal Disclaimer

This platform is for demonstration and educational purposes. Real-world space asset trading involves complex legal, regulatory, and technical considerations that must be addressed according to applicable space law and regulations.

## 📞 Support

For questions, issues, or feature requests, please open an issue on GitHub or contact the development team.

---

*Built with ❤️ for the future of space commerce*