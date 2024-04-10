#!/bin/bash

if test "$(uname)" = "Darwin"
then
  gpg="/opt/homebrew/bin/gpg"
elif test "$(expr substr $(uname -s) 1 5)" = "Linux"
then
  gpg="/home/linuxbrew/.linuxbrew/bin/gpg"
fi 

# Check if a GPG key already exists
existing_keys=$($gpg --list-secret-keys --keyid-format LONG)

if [[ -n "$existing_keys" ]]; then
  # Extract the GPG key ID from the existing keys
  gpg_key_id=$(echo "$existing_keys" | grep -E "^sec" | awk '{print $2}' | cut -d '/' -f 2)
  # info "You already have an existing GPG key. Your GPG key ID is: $gpg_key_id"
  # git config --global user.signingkey $gpg_key_id 
  # echo $gpg_key_id
  
else
  # Generate a new GPG key
  $gpg --full-generate-key

  # Extract the GPG key ID from the newly generated key
  gpg_key_id=$($gpg --list-secret-keys --keyid-format LONG | grep -E "^sec" | awk '{print $2}' | cut -d '/' -f 2)
  # echo "GPG key generated successfully. Your GPG key ID is: $gpg_key_id"
  # git config --global user.signingkey $gpg_key_id     
  # echo $gpg_key_id
fi

# Print the GPG public key
# gpg --armor --export $gpg_key_id
cat <<'EOF'
[user]
  name = {{ .name }}
  email = {{ .email }}
  signingkey = ${gpg_key_id}
[credential]
  {{ if eq .chezmoi.os "darwin" -}}
  helper = osxkeychain
  {{ else if eq .chezmoi.os "linux" -}}
  helper = cache
  {{ end -}}
[commit]
  gpgsign = true
EOF
