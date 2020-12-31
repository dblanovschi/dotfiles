#!/usr/bin/env zsh

# inputs to set up git
name='Dinu Blanovschi'
email='dinu.blanovschi@criptext.com'

dir="$(pwd)"
home="$HOME"
dotconfig="${XDG_CONFIG_HOME:-$home/.config}"

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

function arch_install_prompt() {
  # $1 = name
  # $2 = should set up by default (0 = true, 1 = false)
  # $3 = function to call to configure
  # $4 = ?force
  prompt="$(print -P "Install %F{green}%B$1%f%b?")"
  if [ "$2" -eq 0 ]; then
    prompt="$prompt [Y/n] "
  else
    prompt="$prompt [y/N] "
  fi

  force=false
  if [ $# -ge 4 ] && [ "$4" != "1" ]; then
    force=true
  fi

  installed=false

  if $force || yes_no_prompt "$prompt" "$2"; then
    if [[ "$3" =~ '[a-zA-Z_\-]+@pacman' ]]; then
      package_name=$(print "$3" | cut -d '@' -f1)
      print -P "Installing %F{green}%B$1%f%b from %F{blue}%b$package_name(pacman)%f%b"
      sudo pacman -Sy "$package_name" || return
    else
      if [[ "$3" =~ '[a-zA-Z_\-]@yay' ]]; then
        package_name=$(print "$3" | cut -d '@' -f1)
        print -P "Installing %F{green}%B$1%f%b from %F{blue}%b$package_name(yay)%f%b"
        yay -Sy "$package_name" || return
      else
        print -P "Installing %F{green}%B$1%f%b"
        $3 || return
      fi
    fi
    print -P "Installed %F{green}%B$1%f%b"
    installed=true
  fi

  eval "export ${1}_installed=$installed"
}

function is_arch() {
  if [ -f /usr/bin/pacman ] && [ -x /usr/bin/pacman ]; then
    return 0
  else
    return 1
  fi
}

action_var='copy'

function use_links() {
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

function git_setup_signing() {
  gpg_key=$(gpg --list-secret-keys --keyid-format LONG "$email" | grep 'sec' | head -n 1 | awk '{print $2}' | cut -d '/' -f2)
  if [ "$gpg_key" = "" ]; then
    print -P "Cannot find gpg key for email <%F{blue}%B$email%f%b>"
    return 1
  fi
  git config --global user.signingkey "$gpg_key"
  git config --global commit.gpgsign true
}

function git_setup() {
  cp "$dir/.gitconfig" "$home/.gitconfig"

  git config --global user.name "$name"
  git config --global user.email "$email"

  setup_with_prompt 'git for signing with gpg' 0 git_setup_signing
}

function alacritty_setup() {
  mkdir "$dotconfig/alacritty"
  action "$dir/alacritty.yml" "$dotconfig/alacritty/alacrity.yml"
}

function zshrc_setup() {
  action "$dir/.zshrc" "$home/.zshrc"
}

function zsh_default_shell() {
  chsh -s $(which zsh)
}

function add_starship_to_zshrc() {
  echo 'eval "$(starship init zsh)"' >> "$home/.zshrc"
}

function install_starship() {
  curl -fsSL https://starship.rs/install.sh | bash

  setup_with_prompt 'Add starship to zshrc' 0 add_starship_to_zshrc
}

function setup_gnome_fonts() {
  gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
  gsettings set org.gnome.desktop.interface document-font-name 'JetBrains Mono 11'
  gsettings set org.gnome.desktop.interface font-name 'JetBrains Mono 11'
}

function setup_zprezto() {
  action "$dir/.zprezto" "$HOME/.zprezto"
  action "$dir/.zpreztorc" "$HOME/.zprezto/runcoms/zpreztorc"

  echo 'source "$HOME/.zprezto/init.zsh"' >> "$home/.zshrc"
}

function configure_terminal() {
  setup_with_prompt   'alacritty'                    0   alacritty_setup
  setup_with_prompt   'zsh'                          0   zshrc_setup
  setup_with_prompt   'zprezto'                      0   setup_zprezto
  setup_with_prompt   'Set zsh as default shell'     0   zsh_default_shell
  setup_with_prompt   'Install starship'             0   install_starship
}

function install_rustup() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  rustup toolchain install stable
  rustup component add rustfmt clippy
}

function install_paperwm() {
  git clone https://github.com/paperwm/PaperWM
  pushd PaperWM
  ./install.sh
  popd
}

function arch_install_yay() {
  sudo pacman -Sy --needed git base-devel
  git clone https://aur.archlinux.org/yay.git
  pushd yay
  makepkg -si
  popd
  rm -rf yay
}

function arch_install_usual_packages() {
  arch_install_prompt 'man-db'    0 'man-db@pacman'
  arch_install_prompt 'man-pages' 0 'man-pages@pacman'
  arch_install_prompt 'nvim'      0 'neovim@pacman'
  arch_install_prompt 'yay'       0 arch_install_yay
  arch_install_prompt 'scc'       0 'scc@yay'
  arch_install_prompt 'alacritty' 0 'alacritty@pacman'
  arch_install_prompt 'discord'   0 'discord@pacman'
  arch_install_prompt 'firefox'   0 'firefox@pacman'
  arch_install_prompt 'llvm'      0 'llvm@pacman'
  arch_install_prompt 'marktext'  0 'marktext-bin@yay'
  arch_install_prompt 'xclip'     0 'xclip@pacman'
  arch_install_prompt 'moreutils' 0 'moreutils@pacman'
}

function arch_install_fonts() {
  arch_install_prompt 'Monoid font'         0 'ttf-monoid@yay'
  arch_install_prompt 'JetBrains Mono font' 0 'ttf-jetbrains-mono@pacman'
}

function configure_gnome() {
  if is_arch; then
    setup_with_prompt 'Install fonts'   0 arch_install_fonts
  fi

  setup_with_prompt   'Set gnome fonts' 0 setup_gnome_fonts
  setup_with_prompt   'Install paperwm' 0 install_paperwm
}

function arch_c_cpp_setup() {
  arch_install_prompt 'gcc'       0 'gcc@pacman'
  arch_install_prompt 'gdb'       0 'gdb@pacman'
  arch_install_prompt 'clang'     0 'clang@pacman'
  arch_install_prompt 'lldb'      0 'lldb@pacman'
  arch_install_prompt 'ltrace'    0 'ltrace@pacman'
  arch_install_prompt 'strace'    0 'strace@pacman'
}

function configure_development() {
  setup_with_prompt   'git'                   0                       git_setup
  setup_with_prompt   'install rustup'        0                       install_rustup

  if is_arch; then
    setup_with_prompt 'C/C++ development'     0                       arch_c_cpp_setup
  fi
}

#                   name/description      default(0=true, 1=false)    setup function
setup_with_prompt   'Use symbolic links'      1                       use_links

if is_arch; then
  setup_with_prompt 'Install usual packages'  0                       arch_install_usual_packages
fi


setup_with_prompt   'Section: terminal'       0                       configure_terminal
setup_with_prompt   'Section: GNOME'          0                       configure_gnome
setup_with_prompt   'Section: development'    0                       configure_development
