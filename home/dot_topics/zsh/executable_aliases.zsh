alias prune-branches="git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d"
alias vim="nvim"
alias b="buku --suggest"
alias reload='. ~/.zshrc'
alias lg='lazygit'
alias ls="eza"
alias cz="chezmoi"

bindkey -s ^f "tmux-sessionizer\n"
