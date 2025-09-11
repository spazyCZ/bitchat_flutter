#!/bin/bash

echo "bitchat Flutter - Run Script"
echo "============================="
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first or run install_ubuntu.sh"
    exit 1
fi

# Check if Linux desktop is available
if ! flutter devices | grep -q "Linux (desktop)"; then
    echo "❌ Linux desktop not available. Enabling..."
    flutter config --enable-linux-desktop
fi

echo "Available options:"
echo "1. Run basic BLE scanner (root project)"
echo "2. Run full bitchat app (bitchat_flutter_app/)"
echo "3. Check system status"
echo ""

read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo "🚀 Running basic BLE scanner..."
        flutter pub get
        flutter run -d linux
        ;;
    2)
        echo "🚀 Running full bitchat app..."
        if [ -d "bitchat_flutter_app" ]; then
            cd bitchat_flutter_app
            flutter pub get
            flutter run -d linux
        else
            echo "❌ bitchat_flutter_app directory not found"
            exit 1
        fi
        ;;
    3)
        echo "📋 System Status Check:"
        echo ""
        echo "Flutter version:"
        flutter --version
        echo ""
        echo "Available devices:"
        flutter devices
        echo ""
        echo "Bluetooth status:"
        systemctl status bluetooth --no-pager -l | head -5
        echo ""
        echo "User groups:"
        groups $USER
        echo ""
        echo "Bluetooth scanning test (5 seconds):"
        timeout 5 bluetoothctl scan on 2>/dev/null || echo "Bluetooth scan test failed"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac