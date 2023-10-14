# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# powerlevel10k theme
source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

for d in "/share/zsh-completions" "/share/zsh/zsh-site-functions";do
  brew_completion=$(brew --prefix 2>/dev/null)$d
  if [ $? -eq 0 ] && [ -d "$brew_completion" ];then
    fpath=($brew_completion $fpath)
  fi
done

# If you come from bash you might have to change your $PATH.
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# Path to your oh-my-zsh installation.
export ZSH="$(echo $HOME)/.oh-my-zsh"

# ZSH History
export HISTFILE=~/.zsh_history
export HISTSIZE=1000
export HISTFILESIZE=10000

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  deno
  docker
  git
  kubectl
  npm
  sudo
  wd
)

source $ZSH/oh-my-zsh.sh

alias prune-branches="git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d"
alias vim="nvim"
alias b="buku --suggest"

export VISUAL=nvim
export EDITOR="$VISUAL"

autoload -U compinit add-zsh-hook
compinit -u add-zsh-hook chpwd
compaudit | xargs chmod g-w,o-w

# Export Secret Keys
[[ ! -f ~/.secret-keys.zsh ]] || source ~/.secret-keys.zsh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

source $(brew --prefix)/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/jteague/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

eval "$(zoxide init zsh)"
