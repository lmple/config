#!/usr/bin/env bash
# Install the system packages and toolchains this config expects.
# Steps run in a fixed order whatever the flag order, because later steps need
# earlier ones (npm needs Node from NVM, Doom needs the symlinks from install.sh).

# SC2016: run_sh snippets are single-quoted on purpose; they expand in the inner shell.
# shellcheck disable=SC2016

set -euo pipefail

REPO_DIR="$(dirname "$(realpath "$0")")"
readonly REPO_DIR
readonly NVM_DIR="$HOME/.nvm"
readonly ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: ./deps.sh [options]

Without options, installs the base set: distro packages, oh-my-zsh, Node (NVM),
npm/pipx tools, Lean, Quint and SDKMAN.

  --heavy       Also install TeX Live, LanguageTool, PlantUML, Jupyter (several GB)
  --firewall    Also install and configure ufw (deny inbound, allow KDE Connect)
  --llama       Also install llama.cpp with CUDA (Arch only, AUR via paru)
  --doom        Also install Doom Emacs (run ./install.sh first)
  --skip-base   Skip the base set, e.g. ./deps.sh --skip-base --doom
  --dry-run     Print the commands instead of running them
  -h, --help    Show this help

DEPS_DISTRO=arch|ubuntu overrides distro detection (useful with --dry-run).
EOF
}

log() { printf '\n==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# Run a command given as separate arguments.
run() {
  printf '+ %s\n' "$*"
  "$DRY_RUN" || "$@"
}

# Run a shell snippet; needed for pipes (curl | sh) and for sourcing nvm.sh,
# which is not safe under `set -u`, so it gets its own non-strict shell.
run_sh() {
  printf '+ %s\n' "$1"
  "$DRY_RUN" || bash -c "$1"
}

detect_distro() {
  if [[ -n "${DEPS_DISTRO:-}" ]]; then
    printf '%s\n' "$DEPS_DISTRO"
    return
  fi
  local id
  # shellcheck source=/dev/null
  id="$(. /etc/os-release && printf '%s' "$ID")"
  case "$id" in
    arch | endeavouros) printf 'arch\n' ;;
    ubuntu) printf 'ubuntu\n' ;;
    *) die "unsupported distro '$id' (set DEPS_DISTRO=arch|ubuntu to force)" ;;
  esac
}

pacman_install() { run sudo pacman -S --needed "$@"; }
apt_install() { run sudo apt install "$@"; }

# ---------------------------------------------------------------- base

pkgs_arch() {
  log "Arch packages"
  # Base tooling (base-devel builds pdf-tools, tree-sitter grammars and AUR packages)
  pacman_install git base-devel curl wget unzip
  # Shell: zshrc loads starship, pyenv and direnv; fzf/ripgrep/fd back fuzzy search in Emacs;
  # jq parses zellij's pane list for zellij/url-picker.sh
  pacman_install zsh starship pyenv direnv fzf ripgrep fd jq
  # Terminal: zshrc auto-starts zellij; alacritty and Doom use FiraCode Nerd Font
  pacman_install alacritty ttf-firacode-nerd zellij wl-clipboard xclip
  # Terminal git UI, alongside magit
  pacman_install lazygit
  # emacs-wayland is the pure-GTK build for Wayland (KDE); swap in emacs on X11.
  # Skip when any variant already provides emacs: they conflict with each other,
  # and pacman would ask to remove the installed one.
  if ! pacman -T emacs >/dev/null; then
    pacman_install emacs-wayland
  fi
  # Languages and LSP servers: Doom (sh +lsp), (cc +lsp), (javascript +lsp)
  pacman_install python-pipx rustup shellcheck shfmt bash-language-server \
    clang typescript-language-server prettier
  run rustup default stable
  run rustup component add rust-analyzer
  # Doom modules: spell (English + French dictionaries), pass, graphviz, org +pandoc/+gnuplot, pdf (poppler-glib)
  pacman_install aspell aspell-en aspell-fr pass graphviz pandoc-cli gnuplot poppler-glib
  # Doom web: tidy formats HTML (stylelint and js-beautify come from npm)
  pacman_install tidy
  # Doom org +dragndrop: doctor wants maim/scrot/gnome-screenshot, but on Wayland
  # config.el takes screenshots with spectacle; scrot only quiets the warning
  pacman_install scrot
}

pkgs_ubuntu() {
  log "Ubuntu packages"
  # Base tooling, plus the -dev libraries needed to build pdf-tools and pyenv Pythons
  apt_install git build-essential curl wget unzip pkg-config autoconf automake \
    libpoppler-glib-dev libpng-dev zlib1g-dev libssl-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libncurses-dev xz-utils tk-dev libffi-dev liblzma-dev libxml2-dev
  # Shell: Ubuntu ships fd as fdfind, link it so Emacs finds it as fd
  apt_install zsh starship pyenv direnv fzf ripgrep fd-find jq
  run mkdir -p "$HOME/.local/bin"
  run_sh 'ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"'
  # Terminal: FiraCode Nerd Font is not packaged, install it per user
  apt_install alacritty wl-clipboard xclip
  if [[ ! -d "$HOME/.local/share/fonts/FiraCodeNerd" ]]; then
    run mkdir -p "$HOME/.local/share/fonts/FiraCodeNerd"
    run_sh 'curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz | tar -xJ -C "$HOME/.local/share/fonts/FiraCodeNerd" && fc-cache -f'
  fi
  # emacs-pgtk is for Wayland, swap in emacs-gtk on X11; lazygit is a terminal git UI
  apt_install emacs-pgtk lazygit
  # Languages and LSP servers; zellij is not packaged, so build it with cargo
  apt_install pipx rustup shellcheck shfmt clang clangd
  run rustup default stable
  run rustup component add rust-analyzer
  run cargo install --locked zellij
  # Doom modules: spell (English + French dictionaries), pass, graphviz, org +pandoc/+gnuplot
  apt_install aspell aspell-en aspell-fr pass graphviz pandoc gnuplot
  # Doom web: tidy formats HTML (stylelint and js-beautify come from npm)
  apt_install tidy
  # Doom org +dragndrop: doctor wants maim/scrot/gnome-screenshot, but on Wayland
  # config.el takes screenshots with spectacle; scrot only quiets the warning
  apt_install scrot
}

oh_my_zsh() {
  log "oh-my-zsh"
  # --keep-zshrc: ~/.zshrc is this repo's zshrc (symlinked by install.sh) and
  # already sources oh-my-zsh; --unattended skips chsh, so do it below.
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    run_sh 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc'
  fi
  local plugin
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/$plugin" ]]; then
      run git clone "https://github.com/zsh-users/$plugin" "$ZSH_CUSTOM_DIR/plugins/$plugin"
    fi
  done
  if [[ "$(basename "${SHELL:-}")" != zsh ]]; then
    run_sh 'chsh -s "$(command -v zsh)"'
  fi
}

nvm_node() {
  log "NVM and Node"
  # PROFILE=/dev/null: zshrc already loads nvm, don't let the installer append to it
  if [[ ! -d "$NVM_DIR" ]]; then
    run_sh 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | PROFILE=/dev/null bash'
  fi
  with_nvm 'nvm install --lts'
}

# npm from NVM is only on PATH once nvm.sh is sourced
with_nvm() { run_sh ". \"$NVM_DIR/nvm.sh\" && $1"; }

npm_globals() {
  local distro=$1
  log "npm global packages"
  if [[ "$distro" == ubuntu ]]; then
    # Not packaged on Ubuntu
    with_nvm 'npm install -g bash-language-server typescript-language-server typescript prettier'
  fi
  # Quint and its language server
  with_nvm 'npm install -g @informalsystems/quint @informalsystems/quint-language-server'
  # Doom web: CSS linting and JS/CSS/HTML formatting, from npm on both distros
  with_nvm 'npm install -g stylelint js-beautify'
}

pipx_tools() {
  log "pipx tools"
  run pipx install ruff mypy pylint basedpyright
}

toolchains() {
  log "Lean"
  # elan adds itself to PATH via ~/.profile and ~/.zprofile, not the repo's zshrc
  if [[ ! -d "$HOME/.elan" ]]; then
    run_sh 'curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y'
  fi
}

sdkman() {
  log "SDKMAN"
  # rcupdate=false: zshrc already sources sdkman-init.sh at its end
  if [[ ! -d "$HOME/.sdkman" ]]; then
    run_sh 'curl -s "https://get.sdkman.io?rcupdate=false" | bash'
  fi
}

base() {
  local distro=$1
  "pkgs_$distro"
  oh_my_zsh
  nvm_node
  npm_globals "$distro"
  pipx_tools
  toolchains
  sdkman
}

# ---------------------------------------------------------------- extras

heavy() {
  local distro=$1
  log "Heavy extras"
  if [[ "$distro" == arch ]]; then
    # LaTeX (Doom latex): the texlive group is the full TeX Live minus languages,
    # so add French. It brings latexmk and chktex (Doom's checker) via
    # texlive-binextra. biber backs biblatex, and the perl
    # modules let texlab format with latexindent.
    pacman_install texlive texlive-langfrench biber texlab \
      perl-yaml-tiny perl-file-homedir
    # Grammar checking, PlantUML, Jupyter (ein)
    pacman_install languagetool plantuml jupyter-notebook
  else
    # texlive-full is the full TeX Live, every language included, and already
    # pulls in latexmk, chktex and biber
    apt_install texlive-full texlab
    # PlantUML, Jupyter (ein); LanguageTool is not packaged, Doom's
    # grammar module just warns without it
    apt_install plantuml jupyter-notebook
  fi
}

firewall() {
  local distro=$1
  log "Firewall (ufw)"
  if [[ "$distro" == arch ]]; then
    pacman_install ufw
    # EndeavourOS enables firewalld out of the box; two firewalls rewriting the
    # same nftables rules conflict, so turn it off first
    if systemctl list-unit-files firewalld.service >/dev/null 2>&1; then
      run sudo systemctl disable --now firewalld
    fi
    run sudo systemctl enable --now ufw # loads the rules at boot
  else
    # Ubuntu ships ufw installed but inactive
    apt_install ufw
  fi
  run sudo ufw default deny incoming
  run sudo ufw default allow outgoing
  # KDE Connect / GSConnect pair and transfer over 1714-1764
  run sudo ufw allow 1714:1764/tcp
  run sudo ufw allow 1714:1764/udp
  # Only if this machine runs an SSH server: rate-limit repeated login attempts
  # run sudo ufw limit ssh
  run sudo ufw enable
  run sudo ufw status verbose
}

llama() {
  local distro=$1
  log "llama.cpp (CUDA)"
  [[ "$distro" == arch ]] || die "--llama is Arch only (llama.cpp-cuda from the AUR)"
  # 10217 works; 8589 fails with "unknown model architecture: 'gemma4'"
  run paru -S --needed llama.cpp-cuda
  # An older hand-built copy in /usr/local/bin takes precedence over /usr/bin
  if [[ -e /usr/local/bin/llama-server ]]; then
    warn "/usr/local/bin/llama-server shadows the package; remove it if 'llama-server --version' is old"
  fi
}

doom() {
  log "Doom Emacs"
  if [[ "$(realpath "$HOME/.config/doom" 2>/dev/null)" != "$REPO_DIR/doom" ]]; then
    die "$HOME/.config/doom does not point at $REPO_DIR/doom; run ./install.sh first"
  fi
  if [[ ! -d "$HOME/.config/emacs" ]]; then
    run git clone --depth 1 https://github.com/doomemacs/core "$HOME/.config/emacs"
  fi
  run "$HOME/.config/emacs/bin/doom" install
}

# ---------------------------------------------------------------- main

main() {
  local want_base=true want_heavy=false want_firewall=false want_llama=false want_doom=false
  local arg
  for arg in "$@"; do
    case "$arg" in
      --heavy) want_heavy=true ;;
      --firewall) want_firewall=true ;;
      --llama) want_llama=true ;;
      --doom) want_doom=true ;;
      --skip-base) want_base=false ;;
      --dry-run) DRY_RUN=true ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "unknown option '$arg'"
        ;;
    esac
  done

  local distro
  distro="$(detect_distro)"
  [[ "$distro" == arch || "$distro" == ubuntu ]] || die "DEPS_DISTRO must be arch or ubuntu"
  log "Distro: $distro$("$DRY_RUN" && printf ' (dry run)')"

  # if, not `&&`: bash disables `set -e` inside a function called from a && list
  if "$want_base"; then base "$distro"; fi
  if "$want_heavy"; then heavy "$distro"; fi
  if "$want_firewall"; then firewall "$distro"; fi
  if "$want_llama"; then llama "$distro"; fi
  if "$want_doom"; then doom; fi
  log "Done"
}

main "$@"
