#!/bin/bash
# DigitalOcean Deployment Script for Content Generation
# Run this on your DigitalOcean droplet to set up automated content generation

set -e

echo "🚀 Setting up automated content generation on DigitalOcean..."

# Install Python and dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv git

# Create directory for content generation
mkdir -p ~/lingafriq-content-generation
cd ~/lingafriq-content-generation

# Clone or update repository
if [ -d "lingafriq-mobile-app" ]; then
    cd lingafriq-mobile-app
    git pull
else
    git clone https://github.com/LingAfrika/lingafriq-mobile-app.git
    cd lingafriq-mobile-app
fi

# Set up Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
cd tools/content_generation
pip install -r requirements.txt || pip install requests python-dotenv

# Create .env file (user needs to add API keys)
if [ ! -f .env ]; then
    cat > .env << EOF
# Groq API Key (get from https://console.groq.com)
GROQ_API_KEY=your_groq_api_key_here

# Backend API
BACKEND_API_URL=https://api.lingafriq.com
BACKEND_API_KEY=your_backend_api_key_here
EOF
    echo "⚠️  Please edit .env file and add your API keys:"
    echo "   nano ~/lingafriq-content-generation/lingafriq-mobile-app/tools/content_generation/.env"
fi

# Create systemd service for automated generation
sudo tee /etc/systemd/system/lingafriq-content-generation.service > /dev/null << EOF
[Unit]
Description=LingAfriq Automated Content Generation
After=network.target

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$HOME/lingafriq-content-generation/lingafriq-mobile-app/tools/content_generation
Environment="PATH=$HOME/lingafriq-content-generation/venv/bin"
ExecStart=$HOME/lingafriq-content-generation/venv/bin/python automated_pipeline.py
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create timer for daily execution
sudo tee /etc/systemd/system/lingafriq-content-generation.timer > /dev/null << EOF
[Unit]
Description=Run LingAfriq Content Generation Daily
Requires=lingafriq-content-generation.service

[Timer]
OnCalendar=daily
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start timer
sudo systemctl daemon-reload
sudo systemctl enable lingafriq-content-generation.timer
sudo systemctl start lingafriq-content-generation.timer

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Edit .env file with your API keys"
echo "   2. Test manually: python automated_pipeline.py"
echo "   3. Check timer status: sudo systemctl status lingafriq-content-generation.timer"
echo "   4. View logs: journalctl -u lingafriq-content-generation.service -f"
echo ""
echo "🔄 To run manually:"
echo "   cd ~/lingafriq-content-generation/lingafriq-mobile-app/tools/content_generation"
echo "   source ~/lingafriq-content-generation/venv/bin/activate"
echo "   python automated_pipeline.py"

