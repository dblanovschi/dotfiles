#!/usr/bin/env zsh

# inputs to set up git
name='Dinu Blanovschi'
email='dinu.blanovschi@criptext.com'

dir="$(pwd)" # root of repository
home="$HOME" # home directory
dotconfig="${XDG_CONFIG_HOME:-$home/.config}" # .config folder

# ================
# | UTILS        |
# ================

function yes_no_prompt() {
  # $1 = prompt
  # $2 = default
  read -rs -k 1 "ans?$1"
  echo

  case "$ans" in
  y|Y)
    return 0
  ;;

  $'\n')
    return $2
  ;;

  *)
    return 1
  esac
}

function setup_with_prompt() {
  # $1 = name
  # $2 = should set up by default (0 = true, 1 = false)
  # $3 = function to call to configure
  prompt="$(print -P "Configure: %F{green}%B$1%f%b?")"
  if [ "$2" -eq 0 ]; then
    prompt="$prompt [Y/n] "
  else
    prompt="$prompt [y/N] "
  fi

  if yes_no_prompt "$prompt" "$2"; then
    print -P "Configuring %F{green}%B$1%f%b"
    $3
    print -P "Configured %F{green}%B$1%f%b"
  fi
}

function arch_is_installed() {
  # $1 = package name
  if pacman -Qs "$1" > /dev/null; then
    return 0
  else
    return 1
  fi
}

function arch_is_group_installed() {
  # $1 = group name
  for package_name in "$(pacman -Sg $1)"; do
    if ! arch_is_installed "$package_name"; then
      return 1
    fi
  done
  return 0
}

function pkg_name() {
  # get package name from 'package@pacman' or 'package@yay'
  
  print "$1" | cut -d '@' -f1
}

function arch_install() {
  # $1 = package name
  sudo pacman -Sy "$1" || return
}

function arch_install_prompt() {
  # $1 = name
  # $2 = should set up by default (0 = true, 1 = false)
  # $3 = function to call to configure, or package@pacman or
  # package@yay to directly install from pacman, respectively yay
  # $4 = maybe 'cfg', meaning we want to configure this package, but didn't find it
  
  cfg_text=''

  if [ $# -ge 4 ] && [ $4 = 'cfg' ]; then
    cfg_text="$(print -P "(tried to configure this without installing it)")"
  fi

  prompt="$(print -P "Install %F{green}%B$1%f%b$cfg_text?")"
  if [ "$2" -eq 0 ]; then
    prompt="$prompt [Y/n] "
  else
    prompt="$prompt [y/N] "
  fi

  if [[ "$3" =~ '[a-zA-Z_\-]+@pacman' ]]; then
    package_name=$(pkg_name "$3")
    if arch_is_installed "$package_name"; then
      return 0
    fi

    if yes_no_prompt "$prompt" "$2"; then
      print -P "Installing %F{green}%B$1%f%b from %F{blue}%b$package_name(pacman)%f%b"
      sudo pacman -Sy "$package_name" || return
    fi
  else
    if [[ "$3" =~ '[a-zA-Z_\-]@yay' ]]; then
      package_name=$(pkg_name "$3")
      if ! arch_is_installed 'yay'; then
        print -P "%F{red}%Byay%b not installed%f. Cannot install %B$package_name%b"

        setup_with_prompt 'install yay' 0 yay

        if ! arch_is_installed 'yay'; then
          print -P "%F{yellow}%BWon't install $package_name%f%b"
        fi
      fi
      if arch_is_installed "$package_name"; then
        return 0
      fi

      if yes_no_prompt "$prompt" "$2"; then
        print -P "Installing %F{green}%B$1%f%b from %F{blue}%b$package_name(yay)%f%b"
        yay -Sy "$package_name" || return
      fi
    else
      if yes_no_prompt "$prompt" "$2"; then
        print -P "Installing %F{green}%B$1%f%b"
        $3 || return
      fi
    fi
  fi
}

function arch_install_prompt_if_not_installed() {
  # All arguments are passed to arch_install_prompt, but intercepts the name of the package
  # and checks if it is not already installed first.
  package="$(pkg_name "$3")"

  if ! arch_is_installed "$package"; then
    arch_install_prompt $@
  fi
}

function arch_install_group_prompt_if_not_installed() {
  # All arguments are passed to arch_install_prompt, but intercepts the name of the group
  # and checks if it is not already installed first.
  group="$(pkg_name "$3")"

  if ! arch_is_group_installed "$group"; then
    arch_install_prompt $@
  fi
}

function arch_install_if_not_installed() {
  # $1 = target (pkg@pacman or pkg@yay)
  if [[ "$1" =~ '[a-zA-Z_\-]+@pacman' ]]; then
    package_name=$(pkg_name "$1")
    if arch_is_installed "$package_name"; then
      return 0
    fi

    print -P "Installing %F{green}%B$1%f%b from %F{blue}%b$package_name(pacman)%f%b"
    sudo pacman -Sy "$package_name" || return
  else
    if [[ "$1" =~ '[a-zA-Z_\-]@yay' ]]; then
      package_name=$(pkg_name "$1")
      if ! arch_is_installed 'yay'; then
        print -P "%F{red}%Byay%b not installed%f. Cannot install %B$package_name%b"

        setup_with_prompt 'install yay' 0 yay

        if ! arch_is_installed 'yay'; then
          print -P "%F{yellow}%BWon't install $package_name%f%b"
        fi
      fi
      if arch_is_installed "$package_name"; then
        return 0
      fi

      print -P "Installing %F{green}%B$1%f%b from %F{blue}%b$package_name(yay)%f%b"
      yay -Sy "$package_name" || return
    fi
  fi
}

function is_arch() {
  if [ -f "$(which pacman)" ]; then
    return 0
  else
    return 1
  fi
}

function require_git() {
  # $1 = _what_ requires git
  if [ ! -f "$(which git)" ]; then
    if is_arch; then
      print -P "%F{blue}%Bgit%f%b is required for %F{green}%B$1%f%b"
      arch_install 'git' || return
    else
      print -P "%F{blue}%Bgit%f%b is %F{red}%Bmissing%f%b and is required for %F{green}%B$1%f%b, come back after you install it"
      return 1
    fi
  fi
  return 0
}

function require_arch() {
  # $1 = _what_ requires arch
  if ! is_arch; then
    print -P "Arch is %F{red}%Brequired%f%b for %F{green}%B$1%f%b"
    return 1
  fi
  return 0
}

action_var='copy'

function use_links_() {
  export action_var='link'
}

function action() {
  if [ "$action_var" = "copy" ]; then
    cp -r $1 $2
  else
      if [ "$action_var" = "link" ]; then
        ln -sf $1 $2
      fi
  fi
}

# ================
# | TERMINAL     |
# ================

function alacritty_() {
  if is_arch; then
    arch_install_prompt_if_not_installed 'alacritty' 0 'alacritty@pacman' 'cfg'
  fi
  mkdir -p "$dotconfig/alacritty"
  action "$dir/alacritty.yml" "$dotconfig/alacritty/alacrity.yml"
}

function zshrc_() {
  cp "$dir/.zshrc" "$home/.zshrc"
}

function zsh_default_shell_() {
  chsh -s $(which zsh)
}

function add_starship_to_zshrc_() {
  echo 'eval "$(starship init zsh)"' >> "$home/.zshrc"
}

function starship_() {
  curl -fsSL https://starship.rs/install.sh | bash

  setup_with_prompt 'Add starship to zshrc' 0 add_starship_to_zshrc_
}

function zprezto_() {
  action "$dir/.zprezto" "$HOME/.zprezto"
  action "$dir/.zpreztorc" "$HOME/.zprezto/runcoms/zpreztorc"

  echo 'source "$HOME/.zprezto/init.zsh"' >> "$home/.zshrc"
}

function terminal_() {
  setup_with_prompt   'alacritty'                    0   alacritty_
  setup_with_prompt   'zsh'                          0   zshrc_
  setup_with_prompt   'zprezto'                      0   zprezto_
  setup_with_prompt   'Set zsh as default shell'     0   zsh_default_shell_
  setup_with_prompt   'Install starship'             0   starship_
}

# ==================
# | USUAL PACKAGES |
# ==================

function yay_() {
  require_git 'yay' || return
  require_arch 'yay' || return
  if ! arch_is_group_installed "base-devel"; then
    sudo pacman -Sy base-devel || return
  fi
  git clone https://aur.archlinux.org/yay.git
  pushd yay
  makepkg -si || return
  popd
  rm -rf yay
}

function usual_packages_() {
  arch_install_prompt_if_not_installed 'man-db'    0 'man-db@pacman'
  arch_install_prompt_if_not_installed 'man-pages' 0 'man-pages@pacman'
  arch_install_prompt_if_not_installed 'nvim'      0 'neovim@pacman'
  arch_install_prompt                  'yay'       0 yay_
  arch_install_prompt_if_not_installed 'scc'       0 'scc@yay'
  arch_install_prompt_if_not_installed 'alacritty' 0 'alacritty@pacman'
  arch_install_prompt_if_not_installed 'discord'   0 'discord@pacman'
  arch_install_prompt_if_not_installed 'firefox'   0 'firefox@pacman'
  arch_install_prompt_if_not_installed 'llvm'      0 'llvm@pacman'
  arch_install_prompt_if_not_installed 'marktext'  0 'marktext-bin@yay'
  arch_install_prompt_if_not_installed 'xclip'     0 'xclip@pacman'
  arch_install_prompt_if_not_installed 'moreutils' 0 'moreutils@pacman'
}

# ============
# | GNOME    |
# ============

function fonts_() {
  require_arch 'fonts' || return
  arch_install_prompt 'Monoid font'         0 'ttf-monoid@yay'
  arch_install_prompt 'JetBrains Mono font' 0 'ttf-jetbrains-mono@pacman'
}

function set_gnome_fonts_() {
  gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
  gsettings set org.gnome.desktop.interface document-font-name 'JetBrains Mono 11'
  gsettings set org.gnome.desktop.interface font-name 'JetBrains Mono 11'
}

function paperwm_() {
  require_git 'paperwm' || return
  git clone https://github.com/paperwm/PaperWM
  pushd PaperWM
  ./install.sh
  popd
}

function gnome_() {
  if is_arch; then
    setup_with_prompt 'Install fonts'   0 fonts_
  fi

  setup_with_prompt   'Set gnome fonts' 0 set_gnome_fonts_
  setup_with_prompt   'Install paperwm' 0 paperwm_
}

# ===============
# | DEVELOPMENT |
# ===============

function git_gpg_() {
  gpg_key=$(gpg --list-secret-keys --keyid-format LONG "$email" | grep 'sec' | head -n 1 | awk '{print $2}' | cut -d '/' -f2)
  if [ "$gpg_key" = "" ]; then
    print -P "Cannot find gpg key for email <%F{blue}%B$email%f%b>"
    return 1
  fi
  git config --global user.signingkey "$gpg_key"
  git config --global commit.gpgsign true
}

function git_() {
  cp "$dir/.gitconfig" "$home/.gitconfig"

  git config --global user.name "$name"
  git config --global user.email "$email"

  setup_with_prompt 'git for signing with gpg' 0 git_gpg_
}

function rustup_() {
  if is_arch; then
    if ! arch_is_installed 'rustup'; then
      arch_install 'rustup' || return
    else
      print -P 'Looks like %F{green}%Brustup%f%b is already installed.'
    fi
  else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh || return
  fi
  print 'Installing stable toolchain and components.'
  rustup toolchain install stable
  rustup component add rustfmt clippy
}

function c_cpp_() {
  arch_install_group_prompt_if_not_installed 'base-devel' 0 'base-devel@pacman'
  arch_install_prompt_if_not_installed       'gdb'        0 'gdb@pacman'
  arch_install_prompt_if_not_installed       'clang'      0 'clang@pacman'
  arch_install_prompt_if_not_installed       'lldb'       0 'lldb@pacman'
  arch_install_prompt_if_not_installed       'ltrace'     0 'ltrace@pacman'
  arch_install_prompt_if_not_installed       'strace'     0 'strace@pacman'
}

function dev_() {
  setup_with_prompt   'git'                   0                       git_
  setup_with_prompt   'install rustup'        0                       rustup_

  if is_arch; then
    setup_with_prompt 'C/C++ development'     0                       c_cpp_
  fi
}

# =================
# | CTF           |
# =================

function ctf_forensics_steganography_() {
  arch_install_prompt_if_not_installed 'wireshark-cli'  0 'wireshark-cli@pacman'
  arch_install_prompt_if_not_installed 'wireshark-qt'   0 'wireshark-qt@pacman'
  arch_install_prompt_if_not_installed 'unarchiver'     0 'unarchiver@pacman'
  arch_install_prompt_if_not_installed 'steghide'       0 'steghide@yay'
}

function ctf_reverse_pwn_() {
  arch_install_prompt_if_not_installed 'radare2'        0 'radare2@pacman'
  arch_install_prompt_if_not_installed 'radare2-cutter' 0 'radare2-cutter@pacman'
  arch_install_prompt_if_not_installed 'ghidra'         0 'ghidra@pacman'
  arch_install_prompt_if_not_installed 'snowman'        0 'snowman@yay'

  if arch_is_installed 'python'; then
    arch_install_prompt_if_not_installed 'pwntools'     0 'python-pwntools@pacman'
  fi
}

function ctf_() {
  arch_install_prompt_if_not_installed 'python'         0 'python@pacman'
  if arch_is_installed 'python'; then
    arch_install_prompt_if_not_installed 'pip'          0 'python-pip@pacman'
  fi
  setup_with_prompt 'Forensics & Steganography tools'   0 ctf_forensics_steganography_
  setup_with_prompt 'PWN & Reverse engineering tools'   0 ctf_reverse_pwn_
}


# Configure specific ones
if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    "$1"_
    shift
  done

  exit 0
fi

# Configure them as usual

#                   name/description      default(0=true, 1=false)    setup function
setup_with_prompt   'Use symbolic links'      1                       use_links_

if is_arch; then
  setup_with_prompt 'Install usual packages'  0                       usual_packages_
fi


setup_with_prompt   'Section: terminal'       0                       terminal_
setup_with_prompt   'Section: GNOME'          0                       gnome_
setup_with_prompt   'Section: development'    0                       dev_
if is_arch; then
  setup_with_prompt 'Section: CTF'            1                       ctf_
fi
