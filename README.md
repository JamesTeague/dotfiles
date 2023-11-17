# dotfiles

Personal and Work setup for MacOS and Linux Development and Creation Environments

## Topical

Everything is organized by topic or area. If you decide to add a new tool or area to your configuration (i.e. Node),
just add a `node` directory and drop your files in there. If the file has a `.zsh` extension it will automatically get
picked up and included in your shell. Any file *or* directory that ends with `.symlink` will get symlinked, dropping the
extenstion, into `$HOME` during the `script/bootstrap` execution.

## Components

There's a few special files in the hierarchy.

- **bin/**: Anything in `bin/` will get added to your `$PATH` and be made
  available everywhere.
- **topic/\*.zsh**: Any files ending in `.zsh` get loaded into your
  environment.
- **topic/path.zsh**: Any file named `path.zsh` is loaded first and is
  expected to setup `$PATH` or similar.
- **topic/completion.zsh**: Any file named `completion.zsh` is loaded
  last and is expected to setup autocomplete.
- **topic/install.sh**: Any file named `install.sh` is executed when you run `script/install`. To avoid being loaded 
  automatically, its extension is `.sh`, not `.zsh`.
- **topic/\*.symlink**: Any file ending in `*.symlink` gets symlinked into
  your `$HOME`. This is so you can keep all of those versioned in your dotfiles
  but still keep those autoloaded files in your home directory. These get
  symlinked in when you run `script/bootstrap`.

## Instructions
Run this:

```sh
script/bootstrap
```

This will symlink the appropriate files in `dotfiles` to your home directory.
Everything is configured and tweaked within the `dotfiles` repo.

The main file you'll want to change right off the bat is `zsh/zshrc.symlink`,
which sets up a few paths that'll be different on your particular machine.
You may want to check the `script/bootstrap` file too. I do have some work setup things scattered around.

`dot` is a simple script that installs some dependencies, sets sane macOS
defaults, and so on. Tweak this script, and occasionally run `dot` from
time to time to keep your environment fresh and up-to-date. You can find
this script in `bin/`.


## Credits and Inspirations
[saweber/dotfiles](https://github.com/saweber/dotfiles)
[ThePrimeagen/.dotfiles](https://github.com/ThePrimeagen/.dotfiles)
[holman/dotfiles](https://github.com/holman/dotfiles)
https://www.josean.com/posts/tmux-setup
https://vonheikemen.github.io/devlog/tools/using-netrw-vim-builtin-file-explorer/
