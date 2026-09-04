# Shared, portable interactive Zsh configuration.
# Put machine/account-specific settings in ~/.zshrc.local; it is never synced.

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R --quit-if-one-screen}"

HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt append_history share_history hist_ignore_all_dups hist_reduce_blanks
setopt auto_cd extended_glob interactive_comments
unsetopt beep
bindkey -v

fpath=("$HOME/.config/zsh/completions" $fpath)
autoload -Uz colors
colors

# Keep the useful interactive pieces from the source setup. Zinit is installed
# in user space on first use; an offline shell still starts normally.
ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
if [[ ! -r "$ZINIT_HOME/zinit.zsh" ]] && (( $+commands[git] )); then
  print -P '%F{33}Installing Zinit shell plugins…%f'
  command mkdir -p "$ZINIT_HOME:h"
  command git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" || true
fi
if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
  # Autocomplete initializes Zsh completion itself and must be loaded
  # synchronously, before plugins that add or wrap line-editor widgets.
  zinit light marlonrichert/zsh-autocomplete
  zinit light zsh-users/zsh-autosuggestions
  zinit light zdharma-continuum/fast-syntax-highlighting
  bindkey '^ ' autosuggest-accept
fi

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[mise] )) && eval "$(mise activate zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

open() {
  xdg-open "$@" >/dev/null 2>&1 &
}

mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias vim='nvim'
alias g='git'
alias d='docker'
alias p='python'
alias update='q-update'
alias ff='fzf --preview '\''bat --style=numbers --color=always {}'\'''

if (( $+commands[eza] )); then
  alias ls='eza -lh --no-permissions --no-user --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto --git'
  alias la='eza -lha --no-permissions --no-user --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --long --icons --git --no-permissions --no-user'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah'
  alias la='ls -la'
fi
(( $+commands[bat] )) && alias cat='bat --paging=never'
(( $+commands[lazygit] )) && alias lg='lazygit'
(( $+commands[lazydocker] )) && alias ld='lazydocker'
(( $+commands[yazi] )) && alias y='yazi'
(( $+commands[kitty] )) && alias ssh='kitten ssh'

if [[ -d "$HOME/.bun" ]]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  [[ -r "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
fi
if [[ -d "$HOME/.local/share/pnpm" ]]; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
  path=("$PNPM_HOME" $path)
fi

(( $+commands[fastfetch] )) && fastfetch

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
