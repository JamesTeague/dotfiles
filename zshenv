# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important environment variables.
# .zshenv' should not contain commands that produce output or assume the shell is attached to a tty.

. "$HOME/.cargo/env"

export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

export VISUAL=nvim
export EDITOR="$VISUAL"

# Export Secret Keys
[[ -f ~/.secret-keys.zsh ]] && source ~/.secret-keys.zsh
export GOPRIVATE="scm.bluebeam.com,github.com"
