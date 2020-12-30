#!/usr/bin/env zsh
dir="$(pwd)"
home="$HOME"
dotconfig="$XDG_CONFIG_HOME"

if [ "$dotconfig" = "" ]; then
  dotconfig="$home/.config"
fi

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

action_var='copy'

function use_links() {
  export action_var='link'
}

function action() {
  echo "Action var: $action_var"
  if [ "$action_var" = "copy" ]; then
    cp $1 $2
  else
      if [ "$action_var" = "link" ]; then
        ln -sf $1 $2
      fi
  fi
}

function git_setup() {
  action "$dir/.gitconfig" "$home/.gitconfig"
}

function alacritty_setup() {
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

  echo 'source "$HOME/.zprezto/init.zsh"' >> "$home/.zshrc"
}


#                 name/description      default(0=true, 1=false)         setup function
setup_with_prompt 'Use symbolic links'           1                       use_links
setup_with_prompt 'git'                          0                       git_setup
setup_with_prompt 'alacritty'                    0                       alacritty_setup
setup_with_prompt 'zsh'                          0                       zshrc_setup
setup_with_prompt 'zprezto'                      0                       setup_zprezto
setup_with_prompt 'Set zsh as default shell'     0                       zsh_default_shell
setup_with_prompt 'Install starship'             0                       install_starship
setup_with_prompt 'Set gnome fonts'              0                       setup_gnome_fonts
