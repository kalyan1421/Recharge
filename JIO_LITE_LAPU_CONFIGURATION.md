# JIO LITE LAPU Configuration for Mobile Recharge

## Overview
The system is configured to use **JIO LITE** (operator code `JL`) for all JIO mobile recharges instead of the regular JIO operator due to inactive JIO LAPU numbers.

## Current LAPU Status (Based on Latest Data)

### JIO LITE LAPU Numbers:
| LAPU Number | Group ID | Operator | Circle | RH Limit | RR Limit | Status | Balance | Block Limit | Txn Count | Update Time | Margin | Dealer | Remark |
|-------------|----------|----------|---------|----------|----------|---------|---------|-------------|-----------|-------------|---------|---------|---------|
| 8489377810 | 0 | JIO LITE | TN | 100000 | 100000 | **Active** | 5.62 | 200 | 0 | 17 Aug, 2025 01:17 | 3 | | Nk |
| 9786468280 | 0 | JIO LITE | TN | 99951 | 100000 | **Active** | 6.32 | 0 | 0 | 29 Aug, 2025 12:50 | 3.3 | | NK |
| 9994400390 | 0 | JIO LITE | TN | 97845 | 100000 | **Active** | 3295.2 | 0 | 0 | 29 Aug, 2025 12:55 | 3 | | nk |
| 9600888932 | 0 | JIO LITE | TN | 100000 | 100000 | **Inactive** | 0.7 | 0 | 0 | 25 Jul, 2025 01:45 | 3 | | NK |

### Summary:
- **Total Active LAPU Numbers**: 3 out of 4
- **Total Available Balance**: ₹3,307.14 (5.62 + 6.32 + 3295.2 = ₹3,307.14 from active LAPU)
- **Primary LAPU**: 8489377810 (highest recent activity)
- **Highest Balance LAPU**: 9994400390 (₹3,295.20)

## Operator Mapping Configuration

### Code Mapping:
```dart
// In OperatorMapping class
'JIO': 'JL',        // Maps to JIO LITE
'JIO LITE': 'JL',   // Direct mapping
'RELIANCE JIO': 'JL', // Maps to JIO LITE
'RELIANCE': 'JL',   // Maps to JIO LITE
'RJI': 'JL',        // Maps to JIO LITE  
'RJIO': 'JL'        // Maps to JIO LITE
```

### Pattern Matching:
Any operator name containing:
- `JIO`
- `RELIANCE` 
- `RJI`
- `RJIO`

Will automatically map to **JIO LITE** (code: `JL`)

## Current System Configuration

### Balance Tracking:
The system now tracks the correct JIO LITE LAPU balances:
```dart
final totalJioLiteBalance = 5.62 + 6.32 + 3295.2 + 0.7; // = ₹3,307.84
```

### Active LAPU Numbers:
- **Primary**: 8489377810 (₹5.62)
- **Secondary**: 9786468280 (₹6.32) 
- **High Balance**: 9994400390 (₹3,295.20)
- **Inactive**: 9600888932 (₹0.70) - Needs reactivation

### Status Monitoring:
The system logs the following when processing JIO recharges:
```
📊 Expected to use JIO LITE LAPU numbers: 8489377810, 9786468280, 9994400390, 9600888932
💰 Available JIO LITE balances: 5.62 + 6.32 + 3295.2 + 0.7 = ₹3307.84
Status: 3 Active (8489377810, 9786468280, 9994400390), 1 Inactive (9600888932) ⚠️
```

## Recharge Process Flow

1. **User initiates JIO mobile recharge**
2. **System maps operator**: `JIO` → `JL` (JIO LITE)
3. **Balance check**: Verifies sufficient balance across active JIO LITE LAPUs
4. **LAPU selection**: Uses active LAPU numbers based on availability
5. **Transaction processing**: Processes through Robotics Exchange API with JL operator code
6. **Status tracking**: Monitors transaction status and updates balances

## Recommendations

### Immediate Actions:
1. **Reactivate 9600888932**: Contact support to reactivate the inactive LAPU number
2. **Monitor Balance**: The total balance of ₹3,307.14 should handle most recharge requests
3. **Load Balancing**: Consider load balancing across active LAPUs for better performance

### Operational Notes:
- **Primary LAPU**: Use 8489377810 for most transactions (good activity, reasonable balance)
- **High-Value Recharges**: Use 9994400390 for recharges > ₹500 (highest balance)
- **Backup**: 9786468280 can handle small to medium recharges
- **Warning Threshold**: Alert when total balance falls below ₹1,000

## Testing

The system includes comprehensive tests for JIO LITE configuration:
- Operator mapping validation
- LAPU status checking  
- Balance verification
- Recharge simulation

All tests confirm that JIO recharges will correctly use JIO LITE LAPU numbers.



