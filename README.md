# My dotfiles

Tried to write `setup.sh` to help sync some settings and set up a new machine faster(installing packages assumes pacman and yay,
the latter of which can be installed through `setup.sh`). It assumes `zsh` and `gnome` are already installed, and as long as you're
on arch, it will install everything else. If you're going to run it, don't forget to change `name` and `email` at the very top, and
make sure you only run it from root of the repository, so here's how to do that:

```sh
git clone --recursive https://github.com/dblanovschi/dotfiles.git
cd dotfiles
nvim setup.sh # change `name` and `email` at the top of the file
./setup.sh # will handle everything else for you
```

# Terminal
Emulator: alacritty, with config [here](alacritty.yml)
Shell: zsh
Using [zprezto](https://github.com/sorin-ionescu/prezto) to manage the zsh configuration.
Prompt: [Starship](https://github.com/starship/starship)

Terminal editor: SpaceVim running on nvim.

# DE&WM
GNOME, with [PaperWM](https://github.com/paperwm/PaperWM)
