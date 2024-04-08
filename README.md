# dotfiles

Personal and Work setup for MacOS and Linux Development and Creation Environments

## Quick Start
```bash
sh -c "$(curl -fsSL get.chezmoi.io)" -- init --apply JamesTeague
```

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

