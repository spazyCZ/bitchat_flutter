#!/bin/bash

echo "bitchat Flutter - Ubuntu Installation Script"
echo "============================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if running on Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    print_error "This script is designed for Ubuntu/Debian systems with apt-get"
    exit 1
fi

print_info "Checking system requirements..."

# Update package list
print_info "Updating package lists..."
sudo apt-get update

print_info "Installing required system dependencies..."

# Install required packages for Flutter and Bluetooth
sudo apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    libbluetooth-dev \
    bluez \
    bluez-tools \
    rfkill

if [ $? -eq 0 ]; then
    print_status "System dependencies installed successfully"
else
    print_error "Failed to install system dependencies"
    exit 1
fi

# Check if Flutter is already installed
if command -v flutter &> /dev/null; then
    print_status "Flutter is already installed: $(flutter --version | head -n1)"
else
    print_info "Installing Flutter..."
    
    # Install Flutter using snap if available
    if command -v snap &> /dev/null; then
        print_info "Installing Flutter via snap..."
        sudo snap install flutter --classic
        
        if [ $? -eq 0 ]; then
            print_status "Flutter installed via snap"
        else
            print_warning "Snap installation failed, trying manual installation..."
            
            # Manual Flutter installation fallback
            FLUTTER_VERSION="3.24.4"
            FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
            
            cd /tmp
            curl -L "$FLUTTER_URL" -o flutter.tar.xz
            
            if [ $? -eq 0 ]; then
                sudo tar xf flutter.tar.xz -C /opt/
                
                # Add Flutter to PATH
                echo 'export PATH="/opt/flutter/bin:$PATH"' >> ~/.bashrc
                export PATH="/opt/flutter/bin:$PATH"
                
                print_status "Flutter installed manually to /opt/flutter"
            else
                print_error "Failed to download Flutter. Please install manually."
                print_info "Visit: https://docs.flutter.dev/get-started/install/linux"
                exit 1
            fi
        fi
    else
        print_error "Neither snap nor curl available for Flutter installation"
        exit 1
    fi
fi

# Enable Linux desktop support
print_info "Enabling Linux desktop support..."
flutter config --enable-linux-desktop

if [ $? -eq 0 ]; then
    print_status "Linux desktop support enabled"
else
    print_error "Failed to enable Linux desktop support"
    exit 1
fi

# Setup Bluetooth permissions and services
print_info "Setting up Bluetooth..."

# Ensure Bluetooth service is enabled and running
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Add user to bluetooth group
sudo usermod -a -G bluetooth $USER

# Check if Bluetooth is blocked by rfkill
if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    print_info "Unblocking Bluetooth..."
    sudo rfkill unblock bluetooth
fi

print_status "Bluetooth service configured"

# Flutter doctor check
print_info "Running Flutter doctor to check setup..."
flutter doctor

# Check if project directory exists and set it up
if [ -d "bitchat_flutter_app" ]; then
    print_info "Setting up bitchat_flutter_app..."
    cd bitchat_flutter_app
    
    # Get Flutter dependencies
    flutter pub get
    
    if [ $? -eq 0 ]; then
        print_status "Flutter dependencies installed"
    else
        print_error "Failed to install Flutter dependencies"
        exit 1
    fi
    
    cd ..
fi

echo ""
print_status "Installation completed successfully!"
echo ""
print_info "Next steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. Reboot your system to apply Bluetooth group membership"
echo "  3. After reboot, verify setup with: flutter doctor"
echo "  4. Test Bluetooth with: bluetoothctl scan on"
echo "  5. Run the app with: cd bitchat_flutter_app && flutter run -d linux"
echo ""
print_warning "Important: You MUST reboot your system for Bluetooth group membership to take effect!"
echo ""
print_info "For troubleshooting:"
echo "  - Check Bluetooth status: systemctl status bluetooth"
echo "  - Check if Bluetooth is blocked: rfkill list bluetooth"
echo "  - Test Bluetooth scanning: bluetoothctl scan on"
echo "  - Check available devices: flutter devices"