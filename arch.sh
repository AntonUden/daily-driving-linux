#!/bin/bash

# ==============================================================================
# Helper functions for pretty console output
# ==============================================================================
print_section() {
    echo -e "\n\033[1;35m=========================================================\033[0m"
    echo -e "\033[1;32m$1\033[0m"
    echo -e "\033[1;35m=========================================================\033[0m"
}

print_step() {
    echo -e "\033[1;36m==>\033[0m \033[1;37m$1\033[0m"
}

# Ask for Git credentials early so the user can leave the PC unattended later
print_section "INITIAL SETUP & CREDENTIALS"
read -p "Enter your Git full name: " git_name
read -p "Enter your Git email address: " git_email

# Ask about Steam
read -p "Do you want to install Steam? (y/n): " install_steam

# ==============================================================================
# 1. System Configuration & Pacman Tweaks
# ==============================================================================
print_section "CONFIGURING PACMAN & SYSTEM TWEAKS"

print_step "Enabling Pac-Man easter egg (ILoveCandy)..."
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
if ! grep -q "^ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
fi

print_step "Checking multilib repository status..."
if grep -q "^\[multilib\]" /etc/pacman.conf; then
    print_step "Multilib is already enabled."
else
    print_step "Enabling multilib repository..."
    sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
    sudo pacman -Sy
fi

print_step "Enabling sudo insults..."
echo "Defaults insults" | sudo tee /etc/sudoers.d/01_insults > /dev/null

# ==============================================================================
# 2. Core Packages Installation
# ==============================================================================
print_section "INSTALLING CORE PACKAGES"

print_step "Installing official repository packages..."
sudo pacman -S --needed --noconfirm \
    base-devel git curl wget bash-completion \
    kwrite firefox dolphin spectacle krita kcalc \
    btop htop screen net-tools \
    ffmpeg vlc ffmpegthumbs kdegraphics-thumbnailers \
    noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation \
    go nvm jdk25-openjdk zsh rustup \
    fprintd libreoffice-fresh yt-dlp linux-headers \
    unzip unrar flatpak \
    wine winetricks protontricks \
    docker docker-compose \
    kicad kicad-library kicad-library-3d \
    kdenlive kleopatra ghidra obs-studio obs-studio-plugin-browser \
    gwenview qbittorrent konsole v4l2loopback-dkms ark peazip

print_step "Enabling Docker service..."
sudo systemctl enable --now docker.service

if [[ "$install_steam" =~ ^[Yy]$ ]]; then
    print_step "Installing Steam..."
    sudo pacman -S --noconfirm steam
else
    print_step "Skipping Steam installation."
fi

# ==============================================================================
# 3. AUR Helper (yay) & AUR Packages
# ==============================================================================
print_section "INSTALLING AUR PACKAGES (YAY)"

if ! command -v yay &> /dev/null; then
    print_step "Installing yay..."
    cd "$HOME/Downloads"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    print_step "yay is already installed."
fi

print_step "Installing packages via yay..."
yay -S --noconfirm \
    visual-studio-code-bin \
    mullvad-vpn-bin \
    protonup-qt \
    ventoy-bin \
    displaylink \
    evdi-dkms \
    bruno-bin \
    kdotool

print_step "Enabling DisplayLink service..."
sudo systemctl enable --now displaylink.service

# ==============================================================================
# 4. Flatpak Packages
# ==============================================================================
print_section "INSTALLING FLATPAK PACKAGES"
print_step "Installing Discord, Bitwarden, Telegram, and PrismLauncher..."
sudo flatpak install -y flathub \
    dev.vencord.Vesktop \
    com.bitwarden.desktop \
    org.telegram.desktop \
    org.prismlauncher.PrismLauncher \
    com.heroicgameslauncher.hgl

# ==============================================================================
# 5. Developer Tools & Keys (Git, SSH, Node, Rust)
# ==============================================================================
print_section "CONFIGURING DEVELOPER TOOLS"

print_step "Configuring Git..."
git config --global user.name "$git_name"
git config --global user.email "$git_email"
git config --global core.editor "nano"
git config --global credential.helper store

print_step "Checking SSH keys..."
if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
    print_step "SSH key already exists. Skipping generation."
else
    print_step "Generating new Ed25519 SSH key..."
    ssh-keygen -t ed25519 -C "$USER@$HOSTNAME" -f "$HOME/.ssh/id_ed25519" -N ""
fi

print_step "Setting up NVM (Node Version Manager)..."
if ! grep -q "source /usr/share/nvm/init-nvm.sh" ~/.bashrc; then
    echo 'source /usr/share/nvm/init-nvm.sh' >> ~/.bashrc
fi
source /usr/share/nvm/init-nvm.sh
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

print_step "Installing global NPM packages..."
npm install --global typescript @angular/cli

print_step "Setting up Rustup..."
rustup default stable

# ==============================================================================
# 6. Desktop Environment & Visuals (KDE, Wallpapers)
# ==============================================================================
print_section "APPLYING THEMING & KDE CONFIGS"

print_step "Applying Breeze Dark theme..."
plasma-apply-colorscheme BreezeDark

print_step "Downloading & Applying Wallpapers..."
WALLPAPER_DIR="$HOME/Pictures/wallpaper"
mkdir -p "$WALLPAPER_DIR"

URLS=(
    "https://files.ekered.se/wallpapers/proto_wallpaper.mp4"
    "https://files.ekered.se/wallpapers/stackroomproot.png"
)

for URL in "${URLS[@]}"; do
    FILE_NAME=$(basename "$URL")
    DEST_PATH="$WALLPAPER_DIR/$FILE_NAME"

    if [ ! -f "$DEST_PATH" ]; then
        curl -fsSL "$URL" -o "$DEST_PATH"
    fi
done

WALLPAPER_FILE="$WALLPAPER_DIR/stackroomproot.png"
plasma-apply-wallpaperimage "$WALLPAPER_FILE"

print_step "Applying KDE system tweaks (Screenlocker, Locale, etc.)..."
kwriteconfig6 --file ksmserverrc --group General --key loginMode "emptySession"
kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock --type bool false
kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume --type bool false
kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 0
qdbus6 org.freedesktop.ScreenSaver /ScreenSaver configure 2>/dev/null || true

kwriteconfig6 --file plasma-localerc --group Formats --key LC_NUMERIC "en_SE.UTF-8"
kwriteconfig6 --file plasma-localerc --group Formats --key LC_TIME "en_SE.UTF-8"
kwriteconfig6 --file plasma-localerc --group Formats --key LC_MONETARY "en_SE.UTF-8"
kwriteconfig6 --file plasma-localerc --group Formats --key LC_MEASUREMENT "en_SE.UTF-8"

# ==============================================================================
# 7. Applications Configuration (Firefox)
# ==============================================================================
print_section "CONFIGURING APPLICATIONS"

print_step "Setting up Firefox enterprise policies (Extensions & Adblock)..."
sudo mkdir -p /usr/lib/firefox/distribution
sudo cat <<EOF | sudo tee /usr/lib/firefox/distribution/policies.json > /dev/null
{
  "policies": {
    "Preferences": {
      "browser.newtabpage.activity-stream.showSponsored": false,
      "browser.newtabpage.activity-stream.showSponsoredTopSites": false,
      "browser.newtabpage.activity-stream.system.showSponsored": false
    },
    "ExtensionSettings": {
      "uBlock0@raymondhill.net": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
      },
      "sponsorBlocker@ajay.app": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi"
      },
      "{446900e4-71c2-419f-a6a7-df9c091e268b}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi"
      }
    }
  }
}
EOF

# ==============================================================================
# 8. Bootloader (GRUB)
# ==============================================================================
print_section "CONFIGURING GRUB BOOTLOADER"

print_step "Installing CyberGRUB-2077 Theme..."
sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\bquiet\b//g; s/  / /g' /etc/default/grub

cd "$HOME/Downloads"
git clone https://github.com/adnksharp/CyberGRUB-2077.git
cd CyberGRUB-2077

if [ -f "install.sh" ]; then
    chmod +x install.sh
    sudo ./install.sh
else
    sudo mkdir -p /usr/share/grub/themes/CyberGRUB-2077
    sudo cp -r * /usr/share/grub/themes/CyberGRUB-2077/
    sudo sed -i '/^GRUB_THEME=/d' /etc/default/grub
    echo 'GRUB_THEME="/usr/share/grub/themes/CyberGRUB-2077/theme.txt"' | sudo tee -a /etc/default/grub
fi

print_step "Rebuilding GRUB config..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

cd "$HOME/Downloads"
rm -rf CyberGRUB-2077

# ==============================================================================
# 9. Shell Environment Setup (ZSH)
# ==============================================================================
print_section "SETTING UP ZSH"

print_step "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

print_step "Copying v2.zshrc to ~/.zshrc..."
if [ -f "v2.zshrc" ]; then
    cp v2.zshrc ~/.zshrc
else
    print_step "Warning: v2.zshrc not found in the current directory."
fi

print_step "Changing default shell to zsh..."
chsh -s "$(which zsh)"

# ==============================================================================
print_section "INSTALLATION COMPLETE!"
echo -e "\033[1;32mYour Arch Linux setup is finished. Please reboot your system to apply all changes.\033[0m\n"
