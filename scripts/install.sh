#!/bin/sh
# Pointbreak Debug CLI Installation Script
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/withpointbreak/pointbreak-debug/main/scripts/install.sh | sh
#
# Prefer the stable entry point: https://withpointbreak.com/install.sh
# Raw URLs under the old repository slug are unsupported after slug reuse.
#
# Options:
#   --version=VERSION   Install specific version (e.g., --version=0.4.1 or --version=v0.4.1)
#   --prefix=PATH       Install to custom directory (default: ~/.local/bin)
#   --no-verify         Skip checksum verification (not recommended)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Downloads from: https://download.withpointbreak.com/cli/

# Configuration
REPOSITORY_URL="https://github.com/withpointbreak/pointbreak-debug"
DOWNLOAD_BASE_URL="https://download.withpointbreak.com"
INSTALL_DIR="${HOME}/.local/bin"
VERSION="latest"
VERIFY_CHECKSUM=true

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --version=*)
            VERSION="${arg#*=}"
            shift
            ;;
        --prefix=*)
            INSTALL_DIR="${arg#*=}"
            shift
            ;;
        --no-verify)
            VERIFY_CHECKSUM=false
            shift
            ;;
        *)
            echo "${RED}Unknown option: $arg${NC}" >&2
            echo "Usage: install.sh [--version=VERSION] [--prefix=PATH] [--no-verify]" >&2
            exit 1
            ;;
    esac
done

echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}  Pointbreak Debug Installer${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detect download tool
DOWNLOADER=""
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
else
    echo "${RED}Error: Neither curl nor wget found. Please install one of them.${NC}" >&2
    exit 1
fi

# Detect platform
detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Darwin)
            OS_NAME="darwin"
            ;;
        Linux)
            # Detect if Alpine (musl) or regular Linux (glibc)
            # Check for musl library files first (most reliable)
            if [ -f /lib/libc.musl-x86_64.so.1 ] || [ -f /lib/libc.musl-aarch64.so.1 ]; then
                OS_NAME="alpine"
            # Fallback to checking ldd output
            elif ldd /bin/ls 2>&1 | grep -q musl; then
                OS_NAME="alpine"
            # Fallback to os-release file
            elif [ -f /etc/os-release ]; then
                OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
                if [ "$OS_ID" = "alpine" ]; then
                    OS_NAME="alpine"
                else
                    OS_NAME="linux"
                fi
            else
                OS_NAME="linux"
            fi
            ;;
        *)
            echo "${RED}Error: Unsupported operating system: $OS${NC}" >&2
            echo "This script only supports macOS and Linux." >&2
            echo "For Windows, use: irm https://withpointbreak.com/install.ps1 | iex" >&2
            exit 1
            ;;
    esac

    case "$ARCH" in
        x86_64|amd64)
            ARCH_NAME="x64"
            ;;
        aarch64|arm64)
            ARCH_NAME="arm64"
            ;;
        *)
            echo "${RED}Error: Unsupported architecture: $ARCH${NC}" >&2
            echo "Supported architectures: x86_64, aarch64" >&2
            exit 1
            ;;
    esac

    PLATFORM="${OS_NAME}-${ARCH_NAME}"
    echo "${GREEN}✓${NC} Detected platform: ${BLUE}$PLATFORM${NC}"
}

# Get download URL
get_download_url() {
    if [ "$VERSION" = "latest" ]; then
        echo "  Fetching latest Debug CLI version..."

        if [ "$DOWNLOADER" = "curl" ]; then
            LISTING=$(curl -fsSL "${DOWNLOAD_BASE_URL}/cli/latest/" 2>/dev/null || echo "")
        else
            LISTING=$(wget -qO- "${DOWNLOAD_BASE_URL}/cli/latest/" 2>/dev/null || echo "")
        fi

        VERSION_CLEAN=$(echo "$LISTING" | grep -o 'pointbreak-v[0-9][0-9.]*' | head -1 | sed 's/pointbreak-v//')

        if [ -n "$VERSION_CLEAN" ]; then
            echo "  Using latest version: v${VERSION_CLEAN}"
            VERSION_PATH="latest"
            ARCHIVE_NAME="pointbreak-v${VERSION_CLEAN}-${PLATFORM}.tar.gz"
        else
            echo "${YELLOW}Warning: Could not detect latest version${NC}"
            echo "Falling back to the version-less filename..."
            VERSION_PATH="latest"
            ARCHIVE_NAME="pointbreak-${PLATFORM}.tar.gz"
        fi
    else
        echo "  Using version: $VERSION"
        VERSION_CLEAN="${VERSION#v}"
        VERSION_PATH="v${VERSION_CLEAN}"
        ARCHIVE_NAME="pointbreak-v${VERSION_CLEAN}-${PLATFORM}.tar.gz"
    fi

    ARCHIVE_URL="${DOWNLOAD_BASE_URL}/cli/${VERSION_PATH}/${ARCHIVE_NAME}"
    CHECKSUMS_URL="${DOWNLOAD_BASE_URL}/cli/${VERSION_PATH}/checksums.txt"
    echo "${GREEN}✓${NC} Download URL: ${BLUE}${ARCHIVE_URL}${NC}"
}

# Download file
download_file() {
    URL=$1
    OUTPUT=$2

    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL -o "$OUTPUT" "$URL"
    else
        wget -qO "$OUTPUT" "$URL"
    fi
}

# Download and verify binary
download_binary() {
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    echo ""
    echo "Downloading archive..."

    ARCHIVE_PATH="${TMP_DIR}/${ARCHIVE_NAME}"
    download_file "$ARCHIVE_URL" "$ARCHIVE_PATH"

    if [ ! -f "$ARCHIVE_PATH" ]; then
        echo "${RED}Error: Download failed${NC}" >&2
        exit 1
    fi

    echo "${GREEN}✓${NC} Downloaded: $(du -h "$ARCHIVE_PATH" | cut -f1)"

    # Verify checksum
    if [ "$VERIFY_CHECKSUM" = true ]; then
        echo ""
        echo "Verifying checksum..."

        CHECKSUMS_PATH="${TMP_DIR}/checksums.txt"
        download_file "$CHECKSUMS_URL" "$CHECKSUMS_PATH"

        if [ ! -f "$CHECKSUMS_PATH" ]; then
            echo "${YELLOW}Warning: Could not download checksums file${NC}"
            echo "Skipping checksum verification"
        else
            # Extract checksum for our archive
            EXPECTED_CHECKSUM=$(grep "$ARCHIVE_NAME" "$CHECKSUMS_PATH" | awk '{print $1}')

            if [ -z "$EXPECTED_CHECKSUM" ]; then
                echo "${YELLOW}Warning: Checksum not found in checksums.txt${NC}" >&2
                echo "Skipping checksum verification" >&2
            elif ! echo "$EXPECTED_CHECKSUM" | grep -Eq '^[a-f0-9]{64}$'; then
                echo "${YELLOW}Warning: Invalid checksum format (expected 64 hex characters)${NC}" >&2
                echo "Skipping checksum verification" >&2
            else
                # Calculate actual checksum
                if command -v sha256sum >/dev/null 2>&1; then
                    ACTUAL_CHECKSUM=$(sha256sum "$ARCHIVE_PATH" | awk '{print $1}')
                elif command -v shasum >/dev/null 2>&1; then
                    ACTUAL_CHECKSUM=$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')
                else
                    echo "${YELLOW}Warning: sha256sum/shasum not found${NC}" >&2
                    echo "Skipping checksum verification" >&2
                    ACTUAL_CHECKSUM=""
                fi

                if [ -n "$ACTUAL_CHECKSUM" ]; then
                    if [ "$ACTUAL_CHECKSUM" = "$EXPECTED_CHECKSUM" ]; then
                        echo "${GREEN}✓${NC} Checksum verified"
                    else
                        echo "${RED}Error: Checksum mismatch!${NC}" >&2
                        echo "Expected: $EXPECTED_CHECKSUM" >&2
                        echo "Got:      $ACTUAL_CHECKSUM" >&2
                        exit 1
                    fi
                fi
            fi
        fi
    fi

    echo ""
    echo "Extracting archive..."

    if ! tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"; then
        echo "${RED}Error: Failed to extract archive${NC}" >&2
        exit 1
    fi

    BINARY_PATH="${TMP_DIR}/pointbreak"
    if [ ! -f "$BINARY_PATH" ]; then
        echo "${RED}Error: Binary not found in archive${NC}" >&2
        exit 1
    fi

    echo "${GREEN}✓${NC} Extracted successfully"

    # Install binary
    echo ""
    echo "Installing to: ${BLUE}$INSTALL_DIR${NC}"

    mkdir -p "$INSTALL_DIR"

    TARGET_PATH="${INSTALL_DIR}/pointbreak"
    cp "$BINARY_PATH" "$TARGET_PATH"
    chmod +x "$TARGET_PATH"

    echo "${GREEN}✓${NC} Installed successfully"

    # Verify installation
    echo ""
    echo "Verifying installation..."
    if "$TARGET_PATH" --version >/dev/null 2>&1; then
        INSTALLED_VERSION=$("$TARGET_PATH" --version 2>/dev/null | head -1 || echo "unknown")
        echo "${GREEN}✓${NC} Verification successful: ${BLUE}${INSTALLED_VERSION}${NC}"
    else
        echo "${YELLOW}⚠${NC}  Warning: Could not verify installation" >&2
        echo "Binary installed but --version check failed" >&2
    fi
}

# Check if directory is in PATH
check_path() {
    echo ""

    case ":$PATH:" in
        *":$INSTALL_DIR:"*)
            echo "${GREEN}✓${NC} Install directory is in PATH"
            ;;
        *)
            echo "${YELLOW}⚠${NC}  Install directory is not in PATH"
            echo ""
            echo "To add it to your PATH, add this line to your shell config:"
            echo ""

            if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
                echo "  ${BLUE}echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> ~/.zshrc${NC}"
                echo "  ${BLUE}source ~/.zshrc${NC}"
            elif [ -n "$BASH_VERSION" ] || [ -f "$HOME/.bashrc" ]; then
                echo "  ${BLUE}echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> ~/.bashrc${NC}"
                echo "  ${BLUE}source ~/.bashrc${NC}"
            else
                echo "  ${BLUE}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
            fi
            ;;
    esac
}

# Print next steps
print_next_steps() {
    echo ""
    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${GREEN}  Installation Complete!${NC}"
    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Verify installation:"
    echo "  ${BLUE}pointbreak --version${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Install the final Pointbreak Debug VS Code extension (v0.2.5)"
    echo "  2. Configure your AI assistant to use the Pointbreak Debug MCP server"
    echo "  3. Support: ${BLUE}${REPOSITORY_URL}/issues${NC}"
    echo ""
}

# Main installation flow
main() {
    detect_platform
    get_download_url
    download_binary
    check_path
    print_next_steps
}

main
