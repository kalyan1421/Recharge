# Enhanced Recharge Application Documentation

## Table of Contents
1. [AWS Proxy Server Implementation](#aws-proxy-server-implementation)
2. [Flutter API Service Updates](#flutter-api-service-updates)
3. [Enhanced Firebase Cloud Functions](#enhanced-firebase-cloud-functions)
4. [Error Handling and Monitoring](#error-handling-and-monitoring)
5. [AWS Infrastructure Management](#aws-infrastructure-management)
6. [Testing Strategy](#testing-strategy)
7. [Deployment Checklist](#deployment-checklist)
8. [Additional Recommendations](#additional-recommendations)

## AWS Proxy Server Implementation

### EC2 Proxy Server Setup

The proxy server is implemented using Node.js and Express, handling requests between the Flutter app and PlanAPI.in. Here's the complete implementation:

```javascript
// proxy-server.js (Node.js Express Server on EC2)
const express = require('express');
const axios = require('axios');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// CORS configuration for Flutter app
app.use(cors({
  origin: ['http://localhost:*', 'https://your-app-domain.com'],
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

// Rate limiting to prevent API abuse
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});
app.use(limiter);

// Plan API Base Configuration
const PLAN_API_CONFIG = {
  baseURL: 'https://planapi.in/api/Mobile/',
  timeout: 30000,
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded'
  }
};

// Proxy endpoints implementation...
```

### EC2 Security Group Configuration
```bash
# Allow HTTP/HTTPS traffic
Inbound Rules:
- HTTP (80): 0.0.0.0/0
- HTTPS (443): 0.0.0.0/0  
- Custom TCP (3000): 0.0.0.0/0  # Your app port
- SSH (22): Your-IP/32  # Restrict SSH access

Outbound Rules:
- All traffic: 0.0.0.0/0  # Required for API calls
```

### Process Management with PM2
```bash
# Install PM2 globally
npm install -g pm2

# Start the proxy server
pm2 start proxy-server.js --name "plan-api-proxy"

# Save PM2 configuration
pm2 save

# Setup auto-restart on reboot
pm2 startup

# Monitor the application
pm2 monit
```

## Flutter API Service Updates

The Flutter app's API service has been enhanced to support both direct API calls and proxy server communication:

```dart
// services/api_service.dart
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  late Dio _proxyDio;

  // API Configuration
  static const String _roboticBaseUrl = 'https://api.roboticexchange.in/Robotics/webservice/';
  static const String _memberId = '3425';
  static const String _apiPassword = 'Apipassword';
  static const String _proxyBaseUrl = 'http://56.228.11.165:3000/api/';
  
  // Service implementation...
}
```

## Enhanced Firebase Cloud Functions

### Automatic Transaction Status Checker
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

exports.checkTransactionStatus = functions.pubsub
  .schedule('every 2 minutes')
  .onRun(async (context) => {
    // Implementation details...
  });
```

### Plan Data Caching Function
```javascript
exports.cachePlanData = functions.https.onCall(async (data, context) => {
  // Implementation details...
});
```

## Error Handling and Monitoring

### Comprehensive Error Codes
```dart
class RechargeErrorCodes {
  static const Map<String, String> codes = {
    '0': 'Success',
    '1': 'Authentication Failed!',
    // ... more error codes
  };

  static String getMessage(String code) {
    return codes[code] ?? 'Unknown error occurred';
  }
}
```

### Transaction Status Management
```dart
class TransactionStatus {
  static const int success = 1;
  static const int processing = 2;
  static const int failed = 3;
  static const int pending = 4;
  static const int refunded = 5;

  // Status helper methods...
}
```

## AWS Infrastructure Management

### EC2 Instance Monitoring
```bash
#!/bin/bash
# monitor-proxy.sh
PROXY_URL="http://56.228.11.165:3000/health"
SLACK_WEBHOOK="YOUR_SLACK_WEBHOOK_URL"

check_proxy_health() {
    # Implementation details...
}
```

### Automated Backup Strategy
```bash
#!/bin/bash
# backup-proxy.sh
BACKUP_DIR="/home/ubuntu/backups/$(date +%Y%m%d_%H%M%S)"
# Implementation details...
```

## Testing Strategy

### API Integration Tests
```dart
// test/api_integration_test.dart
void main() {
  group('API Integration Tests', () {
    // Test implementations...
  });
}
```

## Deployment Checklist

### AWS EC2 Setup
- [ ] EC2 instance running and accessible
- [ ] Security groups configured correctly
- [ ] Node.js and PM2 installed
- [ ] Proxy server deployed and running
- [ ] Health monitoring in place
- [ ] Backup strategy implemented

### Firebase Configuration
- [ ] All Firebase services enabled
- [ ] Security rules deployed
- [ ] Cloud Functions deployed
- [ ] Environment variables configured
- [ ] Firebase hosting setup (if needed)

### Flutter App
- [ ] API endpoints updated with proxy URLs
- [ ] Error handling implemented
- [ ] Firebase configuration files added
- [ ] Testing completed
- [ ] App store deployment ready

## Additional Recommendations

1. **Load Balancing**: Consider implementing AWS Application Load Balancer for high availability.

2. **SSL/TLS**: Secure your proxy server with HTTPS using Let's Encrypt or AWS Certificate Manager.

3. **Monitoring**: Set up CloudWatch metrics and alerts for comprehensive monitoring.

4. **Caching**: Implement Redis caching for frequently accessed data.

5. **Rate Limiting**: Implement rate limiting at both proxy and app levels.

6. **Backup Strategy**: Regular automated backups of EC2 instance and configurations.

7. **Security Best Practices**:
   - Regular security audits
   - Implement WAF rules
   - Keep dependencies updated
   - Monitor for suspicious activities

8. **Performance Optimization**:
   - Enable GZIP compression
   - Implement request batching
   - Use connection pooling
   - Optimize database queries

9. **Disaster Recovery**:
   - Regular backup testing
   - Automated recovery procedures
   - Multi-region failover strategy

10. **Compliance**:
    - Implement proper logging
    - Data retention policies
    - Privacy compliance measures 