#!/bin/bash

if test $(which bat)
then
  echo "Building bat cache"
  bat cache --build
fi
