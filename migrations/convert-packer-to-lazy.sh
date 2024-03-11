!#/bin/bash

FILE=~/.local/share/nvim/site/pack/packer
if [[ -d "$FILE" ]]; then
    echo "Packer still installed on machine. Removing in favor of alternate package manager."
    rm -rf $FILE
fi

