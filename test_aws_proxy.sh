#!/bin/bash

# Test AWS EC2 Proxy Server
EC2_HOST="56.228.11.165"
PORT="3000"
BASE_URL="http://$EC2_HOST:$PORT"

echo "🧪 Testing AWS EC2 Proxy Server at $BASE_URL"
echo ""

# Test 1: Health check
echo "1️⃣ Testing health endpoint..."
curl -s "$BASE_URL/health" | jq '.' 2>/dev/null || curl -s "$BASE_URL/health"
echo ""

# Test 2: Operator detection
echo "2️⃣ Testing operator detection..."
curl -s -X POST "$BASE_URL/api/detect-operator" \
  -H "Content-Type: application/json" \
  -d '{"mobile": "9876543210"}' | jq '.' 2>/dev/null || curl -s -X POST "$BASE_URL/api/detect-operator" -H "Content-Type: application/json" -d '{"mobile": "9876543210"}'
echo ""

# Test 3: Get mobile plans
echo "3️⃣ Testing mobile plans..."
curl -s -X POST "$BASE_URL/api/mobile-plans" \
  -H "Content-Type: application/json" \
  -d '{"operatorId": "11", "circleId": "51"}' | jq '.' 2>/dev/null || curl -s -X POST "$BASE_URL/api/mobile-plans" -H "Content-Type: application/json" -d '{"operatorId": "11", "circleId": "51"}'
echo ""

# Test 4: Wallet balance
echo "4️⃣ Testing wallet balance..."
curl -s "$BASE_URL/api/wallet-balance" | jq '.' 2>/dev/null || curl -s "$BASE_URL/api/wallet-balance"
echo ""

echo "✅ Tests completed!"
