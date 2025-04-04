#!/usr/bin/env bash

set -e
set -u
set -o pipefail

INSTALL_DIR="$HOME/neoconf"
REPO_URL="https://github.com/Xitonight/neoconf"
PACKAGES=(
  matugen-bin
  nvm
  python-pywal
  python-watchdog
  stow
  swww
)

install_aur_helper() {
  aur_helper=""
  if command -v yay &>/dev/null; then
    aur_helper="yay"
    echo $aur_helper
  elif command -v paru &>/dev/null; then
    aur_helper="paru"
    echo $aur_helper
  else
    echo "Installing yay-bin..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    cd "$tmpdir/yay-bin"
    makepkg -si --noconfirm
    cd - >/dev/null
    rm -rf "$tmpdir"
    aur_helper="yay"
  fi
}

install_requirements() {
  echo "Installing required packages..."
  $aur_helper -Syy --needed --noconfirm "${PACKAGES[@]}" || true

  echo "Updating outdated required packages..."
  outdated=$($aur_helper -Qu | awk '{print $1}')
  to_update=()
  for pkg in "${PACKAGES[@]}"; do
    if echo "$outdated" | grep -q "^$pkg\$"; then
      to_update+=("$pkg")
    fi
  done

  if [ ${#to_update[@]} -gt 0 ]; then
    $aur_helper -S --noconfirm "${to_update[@]}" || true
  else
    echo "All required packages are up-to-date."
  fi
}

clone_repo() {
  if [ -d "$INSTALL_DIR" ]; then
    echo "Updating neoconf..."
    git -C "$INSTALL_DIR" pull
  else
    echo "Cloning neoconf..."
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi
}

clone_nvchad() {
  if [ -d ~/.config/nvim/ ]; then
    rm -rf ~/.config/nvim/
  fi
  if [ -d ~/.local/share/nvim/ ]; then
    rm -rf ~/.local/share/nvim/
  fi
  if [ -d ~/.local/state/nvim/ ]; then
    rm -rf ~/.local/state/nvim/
  fi
  git clone https://github.com/NvChad/starter ~/.config/nvim
}

stow_dots() {
  if [ -d ~/.config/nvim/ ]; then
    rm -rf ~/.config/nvim/
  fi
  if [ ! -d ~/.config/matugen/templates/ ]; then
    mkdir -p ~/.config/matugen/templates/
  fi

  stow --target=$HOME/.config/matugen/templates --dir=$INSTALL_DIR matugen
  stow --target=$HOME --dir=$INSTALL_DIR dots
}

echo "Cloning NvChad, neovim will open shortly, do not touch anything..."
clone_nvchad
nvim
echo "Stowing new dotfiles..."
stow_dots
nvim
