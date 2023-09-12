# tap repositories and their packages

tap "homebrew/core"
brew "bash"
brew "bash-completion"
brew "curl"
brew "wget"
brew "jq"
brew "git"
brew "grep"
brew "lua"
brew "neovim"
brew "ripgrep"
brew "zsh" # macOS ships with an old version
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-fast-syntax-highlighting"
brew "zsh-vi-mode"

brew "npm" # required by lsp tsserver
brew "make" # required by powerlevel10k on linux
brew "gcc" # required by powerlevel10k, zsh on linux

# CLI tools
brew "bat" # reading files (better cat)
brew "gpg" # for signing git commits
brew "tmux"
brew "thefuck" # auto-correct mistyped commands
brew "zoxide" # easy navigation (better cd)
brew "tldr" # community-maintained docs (better man)
brew "scc" # count lines of code
brew "eza" # listing files (better ls)
brew "diff-so-fancy" # file comparisons (better diff)
brew "fdupes" # duplicate file finder
brew "fzf" # fuzzy file finder (better find)
brew "hyperfine" # command benchmarking
brew "rm-improved" # deletion tool (better rm)
brew "buku" # bookmark manager
brew "ddgr" # search web from terminal
brew "khal" # calendar client
brew "mutt" # email client
brew "newsboat" # RSS/Atom news reader

tap "homebrew/cask-fonts"
cask "font-alfa-slab-one"
cask "font-awesome-terminal-fonts"
cask "font-hack-nerd-font"
cask "font-lato"
cask "font-monocraft"
cask "font-roboto"

tap "homebrew/cask-versions"
cask "firefox-developer-edition"

tap "homebrew/cask"
cask "bitwarden"
cask "discord"
cask "docker"
cask "google-chrome"
cask 'ytmdesktop-youtube-music'

tap "romkatv/powerlevel10k"
brew "powerlevel10k"

if OS.mac?
  # Taps
  tap "homebrew/bundle"
  
  brew "mas"

  # set arguments for all 'brew install --cask' commands
  cask_args appdir: "/Applications", require_sha: false

  # Mac Utilities
  cask "alfred"
  cask "rectangle"
  cask "via"

  # Dependencies
  brew "blueutil" # for alfred airpod plugin

  # Dev Applications
  cask "iterm2"
  brew "slides"

  cask "obsidian"

elsif OS.linux?
  brew "xclip"
end
