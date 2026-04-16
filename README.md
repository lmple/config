# config

## Pyenv

```sh
curl -fsSL https://pyenv.run | bash
```

## SDK man

```sh
curl -s "https://get.sdkman.io" | bash
```

## Install Oh My Zsh

```sh
# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

## Starship

```sh
curl -sS https://starship.rs/install.sh | sh
```

## Doom emacs

```sh
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
```

## pipx

```sh
pipx install ruff mypy pylint
```

## NVM

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
```

## Install config

```sh
./install.sh
```


