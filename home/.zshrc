export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R --quit-if-one-screen}"

HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt append_history share_history hist_ignore_dups hist_reduce_blanks
setopt auto_cd interactive_comments

autoload -Uz compinit && compinit
autoload -Uz colors && colors

alias ls='eza --group-directories-first'
alias ll='eza -lah --group-directories-first --git'
alias la='eza -a --group-directories-first'
alias cat='bat --paging=never'
alias vim='nvim'
alias update='sudo pacman -Syu'

command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v mise >/dev/null && eval "$(mise activate zsh)"
command -v starship >/dev/null && eval "$(starship init zsh)"

fastfetch

