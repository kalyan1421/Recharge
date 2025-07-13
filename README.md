# Mobile Recharge Application

A Flutter application for mobile recharges using Plan API integration through AWS EC2 proxy.

## Features

- Mobile number validation
- Automatic operator and circle detection
- Secure API calls through AWS EC2 proxy
- Beautiful and responsive UI
- Error handling and retry mechanisms

## Prerequisites

- Flutter SDK (>=3.0.0)
- Node.js (>=16.x)
- AWS EC2 instance
- Plan API credentials

## Setup Instructions

### 1. Flutter Application Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd recharger
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate JSON serialization code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Update the proxy server URL in `lib/data/services/operator_detection_service.dart` with your EC2 instance IP.

### 2. AWS EC2 Proxy Setup

1. SSH into your EC2 instance:
```bash
ssh -i <key-file.pem> ec2-user@56.228.11.165
```

2. Copy the setup script:
```bash
scp -i <key-file.pem> setup_proxy_server.sh ec2-user@56.228.11.165:~
```

3. Make the script executable and run it:
```bash
chmod +x setup_proxy_server.sh
./setup_proxy_server.sh
```

4. Verify the proxy server is running:
```bash
curl http://localhost:8080/health
```

## Project Structure

```
lib/
├── main.dart
├── config/
│   ├── api_config.dart
│   └── proxy_config.dart
├── data/
│   ├── models/
│   │   └── operator_info.dart
│   └── services/
│       └── operator_detection_service.dart
├── presentation/
│   ├── screens/
│   │   └── recharge_screen.dart
│   └── widgets/
│       ├── mobile_input_widget.dart
│       └── operator_display_card.dart
└── utils/
    └── validators.dart
```

## Security Considerations

- API credentials are stored securely on the proxy server
- All API calls are routed through the EC2 proxy
- Rate limiting is implemented to prevent abuse
- CORS is configured for security
- SSL/TLS encryption for API calls

## Deployment

1. Build the Flutter application:
```bash
flutter build apk --release
```

2. Deploy the proxy server:
```bash
cd ~/recharge-proxy
pm2 restart all
```

## Monitoring

- Use PM2 to monitor the proxy server:
```bash
pm2 monit
```

- Check proxy server logs:
```bash
pm2 logs recharge-proxy
```

## Troubleshooting

1. If the operator detection fails:
   - Check the mobile number format
   - Verify proxy server is running
   - Check Plan API credentials

2. If the proxy server is down:
   - SSH into EC2 instance
   - Check PM2 status: `pm2 status`
   - Restart if needed: `pm2 restart all`

## License

This project is licensed under the MIT License - see the LICENSE file for details.
