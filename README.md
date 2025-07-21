# Smart Contract Tax Collection System

A comprehensive blockchain-based tax collection system built with Clarity smart contracts for the Stacks blockchain. This system manages the entire lifecycle of property tax collection from assessment to revenue distribution.

## System Overview

The Tax Collection System consists of five interconnected smart contracts that handle different aspects of property tax management:

### 1. Assessment Calculation Contract (`assessment-calculator.clar`)
- Computes property taxes based on assessed property values
- Manages tax rates and assessment periods
- Handles property value updates and calculations
- Supports different property types and tax categories

### 2. Payment Processing Contract (`payment-processor.clar`)
- Processes tax payments from property owners
- Manages installment payment plans
- Tracks payment history and balances
- Handles payment confirmations and receipts

### 3. Delinquency Management Contract (`delinquency-manager.clar`)
- Manages overdue tax accounts
- Calculates penalties and interest on late payments
- Tracks delinquent properties and collection status
- Handles collection procedures and notifications

### 4. Appeal Processing Contract (`appeal-processor.clar`)
- Manages property tax assessment appeals
- Processes appeal submissions and reviews
- Handles assessment adjustments based on appeal outcomes
- Tracks appeal status and resolution history

### 5. Revenue Distribution Contract (`revenue-distributor.clar`)
- Allocates collected tax revenue to appropriate government funds
- Manages distribution percentages and fund allocations
- Tracks revenue distribution history
- Handles fund transfers and accounting

## Key Features

- **Transparent Assessment**: All property assessments and calculations are recorded on-chain
- **Flexible Payment Options**: Support for full payments and installment plans
- **Automated Delinquency Tracking**: Automatic calculation of penalties and interest
- **Fair Appeal Process**: Structured appeal system with proper review mechanisms
- **Accurate Revenue Distribution**: Precise allocation of funds to designated accounts

## Data Structures

### Property Information
- Property ID (unique identifier)
- Assessed value
- Property type
- Owner principal
- Assessment date
- Tax rate category

### Payment Records
- Payment ID
- Property ID
- Amount paid
- Payment date
- Payment method
- Installment plan details

### Appeal Records
- Appeal ID
- Property ID
- Appeal reason
- Submitted date
- Review status
- Resolution details

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Caller not authorized for operation
- `ERR-PROPERTY-NOT-FOUND (u101)`: Property does not exist
- `ERR-INVALID-AMOUNT (u102)`: Invalid payment or assessment amount
- `ERR-PAYMENT-NOT-FOUND (u103)`: Payment record not found
- `ERR-APPEAL-NOT-FOUND (u104)`: Appeal record not found
- `ERR-ALREADY-PAID (u105)`: Tax already paid for period
- `ERR-INSUFFICIENT-FUNDS (u106)`: Insufficient funds for operation
- `ERR-INVALID-DATE (u107)`: Invalid date provided
- `ERR-APPEAL-ALREADY-EXISTS (u108)`: Appeal already submitted
- `ERR-INVALID-STATUS (u109)`: Invalid status for operation

## Usage

### For Property Owners
1. Check property assessment using `get-property-assessment`
2. Make payments using `make-payment` or set up installment plans
3. Submit appeals using `submit-appeal` if disputing assessment
4. Check payment history and balance status

### For Tax Administrators
1. Update property assessments using `update-assessment`
2. Process appeals using `process-appeal`
3. Manage delinquent accounts using delinquency management functions
4. Monitor revenue distribution and fund allocations

### For Government Entities
1. Configure revenue distribution percentages
2. Monitor fund allocations and transfers
3. Access comprehensive reporting and audit trails

## Security Features

- Role-based access control for administrative functions
- Input validation for all parameters
- Overflow protection for calculations
- Audit trails for all transactions
- Immutable record keeping

## Testing

The system includes comprehensive tests covering:
- Assessment calculations and updates
- Payment processing and installment plans
- Delinquency tracking and penalty calculations
- Appeal submission and processing
- Revenue distribution and fund allocation

Run tests using:
\`\`\`bash
npm test
\`\`\`

## Deployment

1. Configure Clarinet.toml with appropriate settings
2. Deploy contracts in the following order:
    - assessment-calculator
    - payment-processor
    - delinquency-manager
    - appeal-processor
    - revenue-distributor
3. Initialize system parameters and administrative roles
4. Configure revenue distribution percentages

## Contributing

Please review PR-DETAILS.md for contribution guidelines and development standards.
