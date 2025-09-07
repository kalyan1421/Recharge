# Updated LAPU Configuration for All Operators

## Current LAPU Status (Latest Update)

### AIRTEL (Operator Code: AT)
| LAPU Number | Group ID | Status | Balance | RH Limit | RR Limit | Block Limit | Txn Count | Update Time | Margin | Dealer | Remark |
|-------------|----------|---------|---------|----------|----------|-------------|-----------|-------------|---------|---------|---------|
| 8807999388 | 0 | **Active** | ₹2,509.17 | 100000 | 1000000 | 0 | 0 | 28 Mar, 2025 05:56 | 0 | | Nk |
| 9600807006 | 0 | **Inactive** | ₹8,793.99 | 92272 | 100000 | 0 | 0 | 09 Jun, 2025 10:58 | 3 | | nk |
| 8220060321 | 0 | **Inactive** | ₹5,748.11 | 100000 | 100000 | 0 | 0 | 13 Jun, 2025 08:12 | 3 | | SAMY |

**Summary**: 1 Active, 2 Inactive | **Available Balance**: ₹2,509.17 (Active only)

---

### JIO LITE (Operator Code: JL)
| LAPU Number | Group ID | Status | Balance | RH Limit | RR Limit | Block Limit | Txn Count | RecTxnTimeGap | Update Time | Margin | Dealer | Remark |
|-------------|----------|---------|---------|----------|----------|-------------|-----------|---------------|-------------|---------|---------|---------|
| 8489377810 | 0 | **Active** | ₹5.62 | 100000 | 100000 | 200 | 0 | 60 | 17 Aug, 2025 01:17 | 3 | | Nk |
| 9786468280 | 0 | **Active** | ₹10.32 | 99682 | 100000 | 0 | 0 | 60 | 02 Sep, 2025 12:54 | 3.3 | | NK |
| 9994400390 | 0 | **Active** | ₹8.20 | 100000 | 100000 | 0 | 0 | 60 | 30 Aug, 2025 08:24 | 3 | | nk |
| 9600888932 | 0 | **Inactive** | ₹0.70 | 100000 | 100000 | 0 | 0 | 60 | 25 Jul, 2025 01:45 | 3 | | NK |

**Summary**: 3 Active, 1 Inactive | **Available Balance**: ₹24.14 (Active numbers only)

---

### VODAFONEIDEA (Operator Code: VI)
| LAPU Number | Group ID | Status | Balance | RH Limit | RR Limit | Block Limit | Txn Count | Update Time | Margin | Dealer | Remark |
|-------------|----------|---------|---------|----------|----------|-------------|-----------|-------------|---------|---------|---------|
| 8489770790 | 0 | **Active** | ₹5,861.48 | 96469 | 100000 | 0 | 0 | 03 Sep, 2025 07:16 | 3 | | NK |

**Summary**: 1 Active | **Available Balance**: ₹5,861.48

---

### BSNL (Operator Code: BS)
| LAPU Number | Group ID | Status | Balance | RH Limit | RR Limit | Block Limit | Txn Count | Update Time | Margin | Dealer | Remark |
|-------------|----------|---------|---------|----------|----------|-------------|-----------|-------------|---------|---------|---------|
| 7598163554 | 0 | **Active** | ₹20.73 | 99853 | 100000 | 0 | 0 | 03 Sep, 2025 12:33 | 3 | | HUJ |
| 7598163734 | 0 | **Active** | ₹92.60 | 1000000 | 1000000 | 0 | 0 | 03 Sep, 2025 12:33 | 3 | | nk |

**Summary**: 2 Active | **Available Balance**: ₹113.33

---

### DTH OPERATORS

#### AIRTEL DTH (Uses AIRTEL DTH LAPU)
| LAPU Number | Group ID | Status | Balance | RH Limit | RR Limit | Block Limit | Txn Count | Update Time | Margin | Dealer | Remark |
|-------------|----------|---------|---------|----------|----------|-------------|-----------|-------------|---------|---------|---------|
| 9600806024 | 0 | **Active** | ₹126.90 | 100000 | 100000 | 500 | 0 | 20 Jun, 2025 11:24 | 3 | | NK |

#### SUN TV (Operator Code: SD)
| LAPU Number | Group ID | Status | Balance | RH Limit | RR Limit | Block Limit | Txn Count | Update Time | Margin | Dealer | Remark |
|-------------|----------|---------|---------|----------|----------|-------------|-----------|-------------|---------|---------|---------|
| 9786468280 | 0 | **Active** | ₹19.50 | 1000000 | 1000000 | 0 | 0 | 18 Aug, 2025 04:44 | 3 | | SUGAN |

#### TATASKY (Operator Code: TS)
| LAPU Number | Group ID | Status | Balance | RH Limit | RR Limit | Block Limit | Txn Count | Update Time | Margin | Dealer | Remark |
|-------------|----------|---------|---------|----------|----------|-------------|-----------|-------------|---------|---------|---------|
| 8220060321 | 0 | **Active** | ₹12.00 | 10000 | 10000 | 0 | 0 | 29 Aug, 2025 06:51 | 3 | | nk |
| 9600806024 | 0 | **Active** | ₹1,265.00 | 100000 | 100000 | 0 | 0 | 17 Aug, 2025 03:48 | 3 | | Nk |

---

### INACTIVE OPERATORS

#### JIO (Regular - Operator Code: JO) - INACTIVE
| LAPU Number | Group ID | Status | Balance | RH Limit | RR Limit | Block Limit | Txn Count | Update Time | Margin | Dealer | Remark |
|-------------|----------|---------|---------|----------|----------|-------------|-----------|-------------|---------|---------|---------|
| 0681274064 | 0 | **Inactive** | ₹1,733.90 | 100000 | 100000 | 500 | 0 | 05 Jun, 2025 07:42 | 3 | | nk |

---

## System Configuration Updates

### Operator Balance Tracking:
```dart
// AIRTEL
final totalAirtelBalance = 2509.17; // Only active LAPU: 8807999388

// JIO LITE  
final totalJioLiteBalance = 5.62 + 10.32 + 8.2 + 0.7; // = ₹24.84

// VODAFONEIDEA
final totalViBalance = 5861.48; // Active LAPU: 8489770790

// BSNL
final totalBsnlBalance = 20.73 + 92.6; // = ₹113.33
```

### Enhanced Error Handling:
- **Error Code 6**: "LAPU Login Required" 
- **Automatic Detection**: System identifies which operator needs LAPU reactivation
- **Detailed Logging**: Shows specific LAPU numbers and their status
- **Support Guidance**: Provides exact information for support team

### Critical Actions Required:

#### IMMEDIATE PRIORITY:
1. **AIRTEL**: Reactivate 9600807006 and 8220060321 (₹14,542.10 total balance locked)
2. **JIO LITE**: Reactivate 9600888932 for better load distribution

#### MEDIUM PRIORITY:
1. **JIO LITE**: Very low balances - need top-up on active LAPUs
2. **BSNL**: Low balances - consider top-up

#### RECOMMENDATIONS:
1. **Primary Operators**: 
   - VODAFONEIDEA (₹5,861.48) - Best balance
   - AIRTEL (₹2,509.17) - Good balance but needs inactive LAPUs reactivated
   
2. **Backup Operators**:
   - BSNL (₹113.33) - Limited capacity
   - JIO LITE (₹24.84) - Very limited capacity

3. **Contact Support For**:
   - AIRTEL LAPU reactivation: 9600807006, 8220060321
   - JIO LITE LAPU reactivation: 9600888932
   - Balance top-up for JIO LITE active LAPUs

### Usage Guidance:
- **AIRTEL Numbers**: Use LAPU 8807999388 (₹2,509.17 available)
- **JIO Numbers**: Use JIO LITE LAPUs 8489377810, 9786468280, 9994400390
- **VI Numbers**: Use LAPU 8489770790 (₹5,861.48 available)
- **BSNL Numbers**: Use LAPUs 7598163554, 7598163734 (₹113.33 total)

This configuration ensures optimal routing of recharges based on current LAPU status and available balances.

