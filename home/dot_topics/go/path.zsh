if (( $+commands[go] ))
then
  export GOPATH="$HOME/go"
  export PATH="$PATH:$GOPATH/bin"
fi
