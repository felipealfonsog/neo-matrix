#!/bin/bash

# Welcome Message
echo "+------------------------+------------------------------+"
echo "| Welcome to the Neo-Matrix Installer!                   |"
echo "| This script will install the Neo-Matrix application    |"
echo "| and the Hanazono font on your system. It will handle   |"
echo "| dependencies, build, and installation steps for various|"
echo "| operating systems.                                    |"
echo "+------------------------+------------------------------+"

# Function to install Hanazono font
install_hanazono_font() {
    echo "Installing Hanazono font..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS-specific installation for Hanazono font
        font_zip="hanazono-20170904.zip"
        wget https://glyphwiki.org/hanazono/$font_zip
        unzip $font_zip -d hanazono-font

        # Create the fonts directory if it does not exist
        if [ ! -d "/Library/Fonts" ]; then
            sudo mkdir -p /Library/Fonts
        fi

        # Move the font files to /Library/Fonts
        sudo mv hanazono-font/* /Library/Fonts/
        rm -rf $font_zip hanazono-font
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        fonts_dir="/usr/share/fonts/truetype"
        if [[ -f /etc/arch-release ]]; then
            # Arch Linux-specific installation for Hanazono font
            sudo pacman -S --noconfirm ttf-hanazono
        elif [[ -f /etc/debian_version ]]; then
            # Debian-based Linux-specific installation for Hanazono font
            sudo apt-get update
            sudo apt-get install -y fonts-hanazono
        elif [[ -f /etc/fedora-release ]]; then
            # Fedora/Red Hat-specific installation for Hanazono font
            fonts_dir="/usr/share/fonts"
            curl -L -o "${fonts_dir}/Hanazono.zip" https://glyphwiki.org/hanazono/hanazono-20170904.zip
            cd "${fonts_dir}"
            sudo unzip Hanazono.zip
            sudo fc-cache -f -v
        fi
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        # FreeBSD-specific installation for Hanazono font
        fonts_dir="/usr/local/share/fonts"
        sudo pkg install -y font-fallback-hanazono
        sudo fc-cache -f -v
    fi
}

# Function to install dependencies and Neo-Matrix on Arch Linux
install_arch_dependencies() {
    echo "Installing dependencies for Arch Linux..."
    sudo pacman -S --noconfirm ncurses autoconf automake libtool
}

# Function to install dependencies and Neo-Matrix on Debian-based Linux
install_debian_dependencies() {
    echo "Installing dependencies for Debian-based Linux..."
    sudo apt-get update
    sudo apt-get install -y ncurses-dev autoconf automake libtool
}

# Function to install dependencies and Neo-Matrix on Fedora/Red Hat
install_fedora_dependencies() {
    echo "Installing dependencies for Fedora/Red Hat..."
    sudo dnf install -y ncurses-devel autoconf automake libtool
}

# Detect the operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS-specific commands
    echo "Detected macOS."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install dependencies
    echo "Installing dependencies..."
    brew install ncurses

    # Install Hanazono font
    install_hanazono_font

    # Clone the repository
    echo "Cloning Neo-Matrix repository..."
    git clone https://github.com/st3w/neo.git
    cd neo

    # Build the project
    echo "Building the project..."
    ./autogen.sh
    CFLAGS="-I$(brew --prefix ncurses)/include" LDFLAGS="-L$(brew --prefix ncurses)/lib" ./configure
    make

    # Install the binary and man page
    echo "Installing the binary and man page..."
    sudo cp src/neo /usr/local/bin/neo-matrix
    sudo cp doc/neo.6 /usr/local/share/man/man6/neo-matrix.6

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux."

    if [[ -f /etc/arch-release ]]; then
        # Arch Linux-specific commands
        echo "Detected Arch Linux."
        install_arch_dependencies
    elif [[ -f /etc/debian_version ]]; then
        # Debian-based Linux-specific commands
        echo "Detected Debian-based Linux."
        install_debian_dependencies
    elif [[ -f /etc/fedora-release ]]; then
        # Fedora/Red Hat-specific commands
        echo "Detected Fedora/Red Hat Linux."
        install_fedora_dependencies
    fi

    # Install Hanazono font
    install_hanazono_font

    # Clone the repository
    echo "Cloning Neo-Matrix repository..."
    git clone https://github.com/st3w/neo.git
    cd neo

    # Build the project
    echo "Building the project..."
    ./autogen.sh
    ./configure
    make

    # Install the binary and man page
    echo "Installing the binary and man page..."
    sudo install -Dm755 src/neo /usr/bin/neo-matrix
    sudo install -Dm644 doc/neo.6 /usr/share/man/man6/neo-matrix.6

elif [[ "$OSTYPE" == "freebsd"* ]]; then
    # FreeBSD-specific commands
    echo "Detected FreeBSD."

    # Install dependencies
    sudo pkg install -y ncurses

    # Install Hanazono font
    install_hanazono_font

    # Clone the repository
    echo "Cloning Neo-Matrix repository..."
    git clone https://github.com/st3w/neo.git
    cd neo

    # Build the project
    echo "Building the project..."
    ./autogen.sh
    ./configure
    make

    # Install the binary and man page
    echo "Installing the binary and man page..."
    sudo install -Dm755 src/neo /usr/local/bin/neo-matrix
    sudo install -Dm644 doc/neo.6 /usr/local/share/man/man6/neo-matrix.6

else
    echo "Unsupported OS. Please manually install dependencies and Neo-Matrix."
    exit 1
fi

echo "+------------------------+------------------------------+"
echo "| Installation complete!                                 |"
echo "| You can now run the Neo-Matrix application using       |"
echo "| 'neo-matrix'. Thank you for using the installer!       |"
echo "+------------------------+------------------------------+"

