#!/bin/bash

echo "🔧 Setting up recharger proxy server..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 globally
sudo npm install -g pm2

# Install nginx
sudo apt install -y nginx

# Create application directory
sudo mkdir -p /var/www/recharger-proxy
sudo chown -R $USER:$USER /var/www/recharger-proxy

# Create logs directory
mkdir -p /var/www/recharger-proxy/logs

# Copy application files
cp server.js /var/www/recharger-proxy/
cp package.json /var/www/recharger-proxy/
cp .env /var/www/recharger-proxy/
cp ecosystem.config.js /var/www/recharger-proxy/

# Navigate to app directory
cd /var/www/recharger-proxy

# Install dependencies
npm install

# Configure nginx
sudo cp nginx.conf /etc/nginx/sites-available/recharger-proxy
sudo ln -sf /etc/nginx/sites-available/recharger-proxy /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t

# Start services
sudo systemctl restart nginx
sudo systemctl enable nginx

# Start application with PM2
pm2 start ecosystem.config.js
pm2 startup
pm2 save

echo "✅ Server setup complete!"
echo "🌐 Application running at: http://56.228.11.165:3000"
echo "📊 PM2 status: pm2 status"
echo "📋 Nginx status: sudo systemctl status nginx"

