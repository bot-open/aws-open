export PATH=$PATH:$HOME/.cargo/bin
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode disabled

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

fpath+=${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

alias bat="batcat"
alias cls="clear"
command -v starship >/dev/null && eval "$(starship init zsh)"
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
