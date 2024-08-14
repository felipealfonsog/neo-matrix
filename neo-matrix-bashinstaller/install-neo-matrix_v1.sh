#!/bin/bash

# Define variables
pkgname="neo-matrix"
pkgver="r24.5c4100a"
pkgdesc="Simulates the digital rain from 'The Matrix' (cmatrix clone with 32-bit color and Unicode support)"
url="https://github.com/st3w/neo"
srcdir="/tmp/neo-matrix-build"
install_dir="/usr/local"
bin_dir="${install_dir}/bin"
man_dir="${install_dir}/share/man/man6"
fonts_dir="/usr/local/share/fonts"

# Create necessary directories
mkdir -p "${srcdir}"
mkdir -p "${bin_dir}"
mkdir -p "${man_dir}"
mkdir -p "${fonts_dir}"

# Function to print a decorative header
print_header() {
    echo "+------------------------+------------------------------+"
    echo "| Welcome to the Neo-Matrix Installer!                    |"
    echo "|                                                      |"
    echo "| This script will install the Neo-Matrix application  |"
    echo "| along with all necessary dependencies and the Hanazono|"
    echo "| font on your system. Please wait while the process   |"
    echo "| completes.                                           |"
    echo "+------------------------+------------------------------+"
}

# Function to install dependencies and Hanazono font on macOS
install_macos_dependencies() {
    echo "Installing dependencies for macOS..."
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo "Detected Apple Silicon (arm64)."
    else
        echo "Detected Intel x86_64."
    fi
    brew install ncurses autoconf automake libtool

    echo "Installing Hanazono font..."
    curl -L -o "${fonts_dir}/Hanazono.zip" https://sourceforge.net/projects/hanazono-fonts/files/latest/download
    cd "${fonts_dir}"
    unzip Hanazono.zip
    fc-cache -f -v
}

# Function to install dependencies and Hanazono font on Arch Linux
install_arch_dependencies() {
    echo "Installing dependencies for Arch Linux..."
    sudo pacman -S --noconfirm ncurses autoconf automake libtool

    echo "Installing Hanazono font..."
    sudo pacman -S --noconfirm ttf-hanazono
}

# Function to install dependencies and Hanazono font on Debian-based Linux
install_debian_dependencies() {
    echo "Installing dependencies for Debian-based Linux..."
    sudo apt-get update
    sudo apt-get install -y ncurses-dev autoconf automake libtool

    echo "Installing Hanazono font..."
    sudo apt-get install -y fonts-hanazono
}

# Function to install dependencies and Hanazono font on Fedora/Red Hat
install_fedora_dependencies() {
    echo "Installing dependencies for Fedora/Red Hat..."
    sudo dnf install -y ncurses-devel autoconf automake libtool

    echo "Installing Hanazono font..."
    curl -L -o "${fonts_dir}/Hanazono.zip" https://sourceforge.net/projects/hanazono-fonts/files/latest/download
    cd "${fonts_dir}"
    unzip Hanazono.zip
    fc-cache -f -v
}

# Function to install dependencies and Hanazono font on FreeBSD
install_freebsd_dependencies() {
    echo "Installing dependencies for FreeBSD..."
    sudo pkg install -y ncurses autoconf automake libtool

    echo "Installing Hanazono font..."
    mkdir -p /usr/local/share/fonts
    curl -L -o /usr/local/share/fonts/Hanazono.zip https://sourceforge.net/projects/hanazono-fonts/files/latest/download
    cd /usr/local/share/fonts
    unzip Hanazono.zip
    fc-cache -f -v
}

# Detect operating system and install dependencies accordingly
print_header

if [[ "$(uname)" == "Darwin" ]]; then
    install_macos_dependencies
elif [[ -f /etc/arch-release ]]; then
    install_arch_dependencies
elif [[ -f /etc/debian_version ]]; then
    install_debian_dependencies
elif [[ -f /etc/fedora-release ]]; then
    install_fedora_dependencies
elif [[ -f /etc/freebsd-version ]]; then
    install_freebsd_dependencies
else
    echo "+------------------------+------------------------------+"
    echo "| Unsupported operating system.                           |"
    echo "| This script supports macOS (x86_64 and arm64), Arch    |"
    echo "| Linux, Debian-based Linux distributions, Fedora/Red Hat,|"
    echo "| and FreeBSD. Please consult the documentation for your  |"
    echo "| operating system for alternative installation methods.  |"
    echo "+------------------------+------------------------------+"
    exit 1
fi

# Clone the repository
echo "Cloning the repository..."
git clone "${url}" "${srcdir}/neo"

# Prepare, build, and install
echo "Preparing, building, and installing..."
cd "${srcdir}/neo"
./autogen.sh
./configure
make

# Install the binary and man page
echo "Installing the binary and man page..."
install -Dm755 "${srcdir}/neo/src/neo" "${bin_dir}/neo-matrix"
install -Dm644 "${srcdir}/neo/doc/neo.6" "${man_dir}/neo-matrix.6"

# Clean up
echo "Cleaning up..."
rm -rf "${srcdir}"

echo "+------------------------+------------------------------+"
echo "| Installation complete!                                 |"
echo "| You can now run the Neo-Matrix application using       |"
echo "| 'neo-matrix'. Thank you for using the installer!       |"
echo "+------------------------+------------------------------+"

