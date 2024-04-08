#!/bin/bash

# Check if a GPG key already exists
existing_keys=$(gpg --list-secret-keys --keyid-format LONG)

if [[ -n "$existing_keys" ]]; then
  # Extract the GPG key ID from the existing keys
  gpg_key_id=$(echo "$existing_keys" | grep -E "^sec" | awk '{print $2}' | cut -d '/' -f 2)
  # info "You already have an existing GPG key. Your GPG key ID is: $gpg_key_id"
  git config --global user.signingkey $gpg_key_id 
else
  # Generate a new GPG key
  gpg --full-generate-key

  # Extract the GPG key ID from the newly generated key
  gpg_key_id=$(gpg --list-secret-keys --keyid-format LONG | grep -E "^sec" | awk '{print $2}' | cut -d '/' -f 2)
  info "GPG key generated successfully. Your GPG key ID is: $gpg_key_id"
  git config --global user.signingkey $gpg_key_id     
fi

# Print the GPG public key
gpg --armor --export $gpg_key_id
