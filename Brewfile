##
# Brewfile by James Teague II
#
# I use this Brewfile developer laptops.
# This is a work in progress. Use at your own discretion.
#
#
# ## Introduction
#
# This file installs many apps, including office suites, multimedia suites,
# programming langauges, unix utilities, sysadmin tools, and fonts.
#
# This file is organized in meaningful sections because we want to
# make it easy for you to pick and choose sections that you want.
#
# There are many TODO items in this file. If you want, help us
# describe these and organize them into the relevant sections.
#
# The file is generally organized in these sections:
#
#   * Software that's fine for everyone,
#     e.g., browsers, players, editors.
#
#   * Software that's especially suitable for programmers,
#     e.g., compilers, databases, languages, servers, etc.
#
#   * Paid software that requires a license or purchase,
#     e.g. JetBrains, OmniGroup, Paw, etc.
#
#   * Libraries: operating system libraries e.g. lib*.
#
#   * TODO: a section of uncategorized software.
#
#   * Fonts
#
#
# ### About Brewfile capabilities
#
# To learn about Brewfile capabilties, please see:
#
#   * http://brew.sh/
#   * http://homebrew-file.readthedocs.io/
#   * https://github.com/Homebrew/homebrew-bundle
#
#
# ### Usage
#
# To use this Brewfile via `brew bundle`:
#
#     $ brew bundle
#
# To use this Brewfile via `brew-file`, which has more capabilties than bundle:
#
#     $ brew install rcmdnk/file/brew-file
#     $ brew file init
#     Do you want to set a repository (y)? ((n) for local Brewfile). [y/n]: y
#     Set repository, "non" for local Brewfile,
#     <user>/<repo> for github repository,
#     or full path for the repository: joelparkerhenderson/brewfile
#
#
# ### Mac tools vs. GNU tools
#
# We generaly prefer GNU tools over preinstalled Mac software tools.
# For example, we prefer the GNU `sed` command vs. macOS `sed` command.
#
# However, we have seen this cause conflicts with macOS software that
# isn't aware of GNU; therefore we install the dupes in parallel.
#
# See:
#
#   * https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/
#
#
# ## Epilog
#
#
# ### Contributing
#
# Feedback welcome. Pull requests welcome.
#
# For more information, see the file `CONTRIBUTING.md` in the repository.
#
#
# ### Thanks
#
# Thanks to the Homebrew team, and all the brew file package teams.
# Your work makes macOS much better for so many people!
#
#
# ### Tracking
#
# * Package: https://github.com/joelparkerhenderson/brewfile
# * Version: 3.1.0
# * Created: 2017-01-01
# * Updated: 2020-05-29
# * License: GPL
# * Contact: Joel Parker Henderson (http://joelparkerhenderson.com)
##

##
# Preflight
##

# Tap homebrew
tap 'homebrew/cask'
tap 'homebrew/cask-drivers'
tap 'homebrew/cask-fonts'
tap 'homebrew/cask-versions'
tap 'homebrew/core'
tap 'homebrew/boneyard'
tap 'homebrew/dev-tools'
tap 'homebrew/bundle'
tap 'homebrew/services'
tap 'romkatv/powerlevel10k'

###########################################################################
#
# SOFTWARE THAT IS TYPICALLY FINE FOR EVERYONE
#
###########################################################################

##
# Browsers
#
# We prefer Firefox because it's open source.
##

# Firefox web browser
cask 'firefox'

# Firefox developer edition, which features programming tools.
cask 'firefox-developer-edition'

# Google Chrome web browser
cask 'google-chrome'

##
# Chat
##

# Discord chat
cask 'discord'

# Slack chat client
#cask 'slack'

##
# Terminals
##

# iTerm is our favorite terminal app.
cask 'iterm2'

##
# Shell
##

# Bash is the Bourne Again SHell. Bash is an sh-compatible shell.
brew 'bash'

# Programmable completion functions for bash
brew 'bash-completion'

# Zsh is a shell designed for interactive use.
brew 'zsh'
brew 'zsh-completions'
brew 'zsh-autosuggestions'
brew 'zsh-fast-syntax-highlighting'
brew 'romkatv/powerlevel10k/powerlevel10k'

# Mobile Shell (MOSH) is like SSH plus roaming and smart echo.
brew 'mobile-shell'

##
# Passwords
##

# Keybase.io digital signature manager
cask 'keybase'

# Bitwarden password manager, which is open-source
cask 'bitwarden'

##
# Editors
##

# bat is like `cat` plus line numbers, syntax highlighting, and more.
brew 'bat'

# less is like `more` plus has more capability.
brew 'less'

# most is like `more` plus has more power.
brew 'most'

# Vim editor
brew 'vim'

# Atom editor by GitHub
cask 'atom'

# Sublime text editor
cask 'sublime-text'

# MacTex: LaTeX document preparation system with high-quality typesetting.
cask 'mactex'

##
# Office software
##

# LibreOffice is a large suite of software for documents, spreadsheets, diagrams.
cask 'libreoffice'

# Microsof Office is a large suite of software for documents, spreadsheets, diagrams.
cask "microsoft-office"

##
# Downloaders
##

# Carthage is a simple, decentralized dependency manager for Cocoa.
#brew 'carthage'

# curl is a command line tool for transferring data with URL syntax.
brew 'curl', link: true

# HTTrack is a free and easy-to-use offline browser utility.
#brew 'httrack'

# Wget is a free software package for retrieving files using HTTP and FTP.
brew 'wget'

##
# Version control
##

# Git is a free and open source distributed version control system.
brew 'git'

##
# GNU command line tools
#
# If you are moving onto macOS from GNU/Linux, then you would probably
# find out that the command line tools shipped with macOS are not as
# powerful and easy to use as the tools in Linux. The reason is that
# macOS uses the BSD version command line tools, which are different
# from the Linux version.
#
# Note: if you choose to replace the macOS commands with GNU commands,
# then be aware that you may have some compatibility issues with shell
# scripts written specifically for macOS.
#
# If you like using man pages, then you may also want to add an
# itemto the to the MANPATH environmental variable:
#
#     $HOMEBREW_PREFIX/opt/coreutils/libexec/gnuman
#
# For more about the GNU command line tools and brew, see this:
# https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/
##

# Basic file, shell and text manipulation utilities of the GNU operating system.
#brew 'coreutils'

#brew 'binutils'
#brew 'diffutils'
#brew 'ed'
#brew 'findutils'
#brew 'gawk'
#brew 'gnu-indent'
#brew 'gnu-sed'
#brew 'gnu-tar'
#brew 'gnu-which'
#brew 'gnutls'
#brew 'gzip'
#brew 'watch'
#brew 'wdiff'

##
# Some GNU command line tools already exist by default on OS X.
# We choose to replace these with newer versions.
##

brew 'gdb'  # gdb requires further actions to make it work. See `brew info gdb`.
brew 'gpatch'
brew 'm4'
brew 'make'
brew 'nano'

##
# System related
#
# These are fundamental operating system tools that we use often.
##

# Automake is a tool for automatically generating Makefile installation files.
#brew 'automake'

# GNU Privacy Guard (GnuPG) provides encryption as a free replacement for PGP.
#brew 'gpg'

# GNU Privacy Guard (GnuPG) PIN entry for macOS to do GPG terminal decryption
#brew 'pinentry-mac'

# OpenSSL is an open-source implementation of the SSL and TLS protocols.
brew 'openssl'

# pkg-config is a helper tool used when compiling applications and libraries.
#brew 'pkg-config', link: true

# Functions for use by applications that allow users to edit command lines while typing.
brew 'readline'

# Parallel SSH
#brew 'pssh'

# pkg-config is a helper tool used when compiling applications and libraries.
#brew 'pkg-config'

# PCRE: Perl-compatible regular expressions, for better searching.
#brew 'pcre'
#brew 'pcre++'

# fd: a simple, fast and user-friendly alternative to find.
brew 'fd'

# RPM is the RedHat Package manager.
#brew 'rpm'

# FZF is a command line fuzzy finder.
#brew 'fzf'

# The `z` command to `cd` among directories.
#brew 'zoxide'

# jdupes: detect duplicate files
#brew 'jdupe'

##
# Command line system operator helpers
##

# Navi is a command line cheat sheet navigator
brew 'denisidoro/tools/navi'

# e.g. is a command line examples
brew 'eg-examples'

# TLDR provides simplified and community-driven man pages
brew 'tldr'

# howdoi shows instant coding answers via the command line
brew 'howdoi'

##
# File handling
##

## Compression & decompression

# Zstandard is the best modern compression
brew 'zstd'

# WinRAR provides compression/decompression for RAR and ZIP files.
brew 'unrar'

# unzip is the classic command.
brew 'unzip'

# bzip
brew 'bzip2', link: true

# ZIP file compression
brew 'libzip'

# pp7zip
brew 'p7zip'

# GNU zip
brew 'gzip'

# RPM to CPIO converts a Red Hat RPM package file to a cpio archive
brew 'rpm2cpio'


## Encryption & decryption

# bcrypt is high quality encryption that is very popular
brew 'bcrypt'

# scrypt is high quality encryption
brew 'scrypt'

##
# File synchronization
##

# rsync is the classic unix file synchronizer.
#brew 'rsync'

# Unison is a high-level file synchronization utility.
#brew 'unison'

# Syncthing is open source file sharing.
#brew 'syncthing'

# Dropbox file sharing.
#cask 'dropbox'

# Transmission bittorrent client.
#brew 'transmission-cli'
#cask 'transmission'

# Box.com sync
#cask 'box-sync'

##
# Text search
#
# We prefer ripgrep because it is very fast and very safe.
##

# ripgrep is text search; we prefer it over grep, ag, git grep, ucg, pt, sift.
brew 'ripgrep'

# grep is the classic searcher
brew 'grep'

# jq is a lightweight and flexible command-line JSON processor.
brew 'jq'

# yq is a lightweight and flexible command-line YAML processor.
brew 'yq'

# xsv is for CSV file parsing, and is fast, full featured, and flexible.
brew 'xsv'

# Tad is CSV viewer with features for pivot, search, etc.
cask 'tad'

##
# Cross-platform tooling
#
# These installations tend to be large.
##

##
# Multimedia
##

# Image libraries
brew 'libgphoto2'
brew 'libpng'
brew 'libtiff'

## Multimedia players

# VLC media player
cask 'vlc'

# YT Music player
cask 'ytmdesktop-youtube-music'

## Sound controls

# Airfoil: Wireless audio app with a free sound equalizer (EQ)
#cask 'airfoil'

# eqMac2: System-wide Audio Equalizer for the Mac; free open source
#cask 'eqmac'

# Audio-Hijack: Records audio from any application
cask 'audio-hijack'

# VB-CABLE Virtual Audio Device: Virtual audio cable for routing audio from one application to another
cask 'vb-cable'

## Multimedia editors

# Gimp pixel-based image editor, similar to Adobe Photoshop
cask 'gimp'

# Inkscape vector-based image editor, similar to Adobe Illustrator
#cask 'inkscape'

# Blender 3D modeller
#cask 'blender'

# Shotcut movie editor
cask 'shotcut'

# Freemind mind map editor
#cask 'freemind'

# yEd is desktop application to generate high-quality diagrams
#cask 'yed'

# Visualization Toolkit for manipulating and displaying scientific data
#brew 'vtk'

## ebooks

# Calibre ebook reader and manager
#cask 'calibre'

# Kindle book reader by Amazon
#cask 'kindle'

# Adobe Air player for multimedia content
#cask 'adobe-air'

## Misc

# GraphicsMagick is the swiss army knife of image processing.
#brew 'graphicsmagick'

# FF MPEG for video
brew 'ffmpeg'
brew 'ffmpeg2theora'
brew 'ffmpegthumbnailer'

# TODO
#brew 'imagemagick'


## Streaming Software

# OBS: Open-source software for live streaming and screen recording
cask 'obs'

# OBS-Websocket: Remote-control OBS Studio through WebSockets
cask 'obs-websocket'

# Touch Portal: Macro remote control
cask 'touch-portal'

##
# Server-Related
##

# Docker software containers to help distribute applications.
brew 'docker'
#brew 'boot2docker'

# Compose is a tool for defining and running multi-container Docker applications.
brew 'docker-compose'

# Docker Machine installs Docker Engine on virtual hosts, and manages the hosts.
#brew 'docker-machine'

##
# Font-Related
##

# Fontconfig is a library for configuring and customizing font access.
brew 'fontconfig'

# FreeType is a freely available software library to render fonts.
brew 'freetype'

# Command-line programs for manipulating fonts
brew 'lcdf-typetools'

##
# Dupes
#
# These formulas duplicate software provided by OS X,
# though may provide more recent or bugfix versions.
#
# We prefer to keep these explicitly listed in `/dupes`
# because these are potentially shadowing system tools,
# and we want to show that these are unusual and special.
#
# If you prefer to type less, then you can tap, like this:
#
#     brew tap homebrew/dupes
#
# Then you can install any forumla, such as:
#
#     brew 'awk'
#
##

brew 'awk'
brew 'diffstat'
brew 'diffutils'
brew 'ed'
brew 'expect'
brew 'fetchmail'
brew 'file-formula'
brew 'gdb'
brew 'gpatch'
brew 'gperf'
brew 'groff'
brew 'heimdal'
brew 'lapack'
brew 'libedit'
brew 'libiconv'
brew 'libpcap'
brew 'lsof'
brew 'm4'
brew 'make'
brew 'nano'
brew 'ncurses'
brew 'openldap'
brew 'openssh'
brew 'tcl-tk'
brew 'tcpdump'
brew 'gnu-units'
brew 'whois'
brew 'zlib'

##
# Brew cask enables installing typical Mac OS X applications.
# For example, these formulas may download a `*.dmg` file,
# then unpack it into the correct `/Applications` directory,
# and possibly configure the app with typical settings.
##

# Adium is an open source multi-protocol instant messaging client.
#cask 'adium'

# TDB
cask 'alfred'

# Window management
cask "rectangle"

# Markdown Presentation in the terminal
brew "slides"

# AppCleaner thoroughly uninstalls unwanted apps.
cask 'appcleaner'

# Flux dims the screen colors for better nighttime visibility.
cask 'flux'

##
# Mac App Store
#
# We use the Mac App Store only when an app is not available
# in a comparable way via brew install and/or brew cask.
#
# We comment out the "mas" commands below, because Apple has
# changed the App Store capability for command line sign in.
#
# Feel free to uncomment any of the below commands that you
# want, try them, and see if you're able to sign in manually.
##

# Apple apps
#mas 'Numbers', id: 409203825
#mas 'Pages', id: 409201541

# Our favorites
#mas "Apple Configurator 2", id: 1037126344
#mas "Blackmagic Disk Speed Test", id: 425264550
#mas "Brightness Slider", id: 456624497
#mas "Color Picker", id: 641027709
#mas "Deliveries", id: 924726344
#mas "Expressions", id: 913158085
#mas "InspectPNG", id: 498851708
#mas "PCalc", id: 403504866
#mas "Pixelmator", id: 407963104
#mas "Telegram", id: 747648890
#mas "Textual", id: 896450579
#mas "Trello", id: 1278508951
#mas "Tweetbot", id: 557168941
#mas 'Simplenote', id: 692867256
#mas 'Sip', id: 507257563
#mas 'Slack', id: 803453959
#mas 'Todoist', id: 585829637

##
# brew-install-our-stacks-automatically.sh
#
# Use Homebrew to install our favorite tech-related packages
# that can be installed fully automatically i.e. unattended;
# these packages do not ask for passwords, do not have any
# prompts, and do not have any issues that need a human.
#
# If you're using this file and you find any packages that
# do not install automatically, please let us know by opening
# an issue, or emailing us, or creating a pull request. Thanks!
#
# ## Link
#
# Some of the brew packages need to link to others.
#
#   * `brew link cmake` before mysql
#   * `brew link cmake` before wireshark can be installed
#   * `brew link cmake` before homebrew/science/opencv
#   * `brew link pandoc` before shellcheck can be installed
#
##

##
# Environment
##


##
# Shell
##

##
# Clients
##

##
# Languages
##

##
# Mac programming
##

# Tunnelblick remote access VPN
cask 'tunnelblick'

##
# Networking
##

# Netcat is a networking utility for the TCP/IP protocol.
brew 'netcat'

# prettyping: ping with colorful output and progress bars
brew 'prettyping'

# mtr: a better tool for ping and traceroute
brew 'mtr'

# Wireshark network monitoring, with the QT GUI.
brew 'cmake', link: true

# Wireshark-chmodbft enables regular users to capture network packets.
# Use this for typical macOS behaviors; use this insted of 'wireshark'.
cask 'wireshark-chmodbpf'

# Charles web debugging proxy
cask 'charles'

# Siege is an http load testing and benchmarking utility.
brew 'siege'

# nmap network mapper is a security scanner
brew 'nmap'

# Certbot: automatically enable HTTPS on your website via Let's Encrypt
brew 'certbot'

##
# Markup languages
#
# For example this section is a good place for HTML tools,
# Markdown tools, UML tools, XML tools, and similar.
##

# Pandoc converts among various formats, such as Markdown and HTML
brew 'pandoc'

## LaTex app that comes with lua(la)tex engines
cask 'TeXShop'

## Markdown

# MacDown simple markdown editor
cask 'macdown'

# MarkText free open source markdown editor
cask 'mark-text'


###########################################################################
#
# SOFTWARE THAT IS ESPECIALLY SUITABLE FOR DEVELOPERS
#
###########################################################################

##
# IDEs: Integrated Development Environments
##

##
# Tooling
##

# Shared Compilation Cache
brew 'sccache'

##
# Databases
#
# This section installs many databases and database tooling:
# Cassandra, CouchDB, MySQL, PostgreSQL, RabbitMQ, Redis
# Riak, Sphinx, SQLite.
##

# Cassandra database.
#brew 'cassandra'

# CouchDB database, esp. for document-oriented storage.
#brew 'couchdb'

# Hadoop database.
#brew 'hadoop' # Disbled because it interferes with 'yarn'

# MariaDB database
#brew 'mariadb'  # Disabled because it interferes with 'mysql' and 'percona'

# MySQL dadtabase.
#brew 'mysql'

# Memcached data cachce server..
#brew 'libmemcached'
#brew 'memcached'

# PostgreSQL database.
#brew 'postgresql'

# DBeaver database manager, community edition
#cask 'dbeaver-community'

# Postgres commmand line interface (CLI) with autocomplete
#brew 'pgcli'

# Prisma replaces traditional ORMs and adds GraphQL
#tap 'prisma/prisma'
#brew 'prisma'

# RabbitMQ enterprise message queue based on the emerging AMQP standard.
#brew 'rabbitmq'

# Redis database, esp. for key-value cache and store, and data structures.
#brew 'redis', restart_service: true

# Riak open-source distributed database.
#brew 'riak'

# SQLite database: self-contained, serverless, zero-configuration, transactional engine.
#brew 'sqlite', link: true

# ZeroMQ message queue
#brew 'zeromq'

##
# Database searchers
##

# Sphinx search engine, which runs on top of MySQL and/or PostgreSQL.
#brew 'cmake', link: true
#brew 'postgresql'
#brew 'sphinx'

# Xapian is an open-source search engine library.
#brew 'xapian'

# Miller is like awk, sed, cut, join, sort for data, CSV, TSV, etc.
#brew 'miller'

##
# Database managers
##

# Liquibase database migration tool
#brew 'liquibase'

# Realm browser mobile database editor.
#cask 'realm-browser'

# Sequel Pro database management application.
#cask 'sequel-pro'

# Realm browser for the Realm embedded database
#cask 'realm-browser'

# Valentina Studio database manager.
#cask 'valentina-studio'

##
# Data analytics
##

# Elasticsearch is a real-time, distributed storage, search, and analytics engine.
#brew 'elasticsearch'

# Logstash helps parse, enrich, transform, and buffer data from a variety of sources.
#brew 'logstash'

# Kibana is an open source analytics and visualization platform designed to work with Elasticsearch.
#brew 'kibana'

##
# Programming languages
#
# This section installs many programming languages:
# Clojure, Elixir, Erlang, Go, Haskell, Java, JavaScript,
# Perl, Python, R, Ruby, Scala, Swift, and tooling.
##

## Clojure

# Clojure programming language compiler.
#brew 'clojure'

# Leiningen automates Clojure projects.
#brew 'leiningen'

## Elixir

# Elixir programming language built on top of the Erlang VM.
#brew 'elixir'

## Erlang

# Erlang programming language for scalable high-availability systems.
#brew 'erlang'

## Go

# Go programming language by Google; compare `C`.
#brew 'go'

## Haskell

# Cabal is a package manager for Haskell
#brew 'ghc'
#brew 'cabal-install'

## Java

# Java programming language
# We prefer open source package 'openjdk' over Oracle cask 'java'
#brew 'openjdk'

# Gradle is a Java build tool
#brew 'gradle'

# Maven is a Java build tool
#brew 'maven'

# Jetty provides a Java web server and javax.servlet container
#brew 'jetty'

# Apache Tomcat implements Java Servlet and JavaServer Pages technologies.
#brew 'tomcat'

# Glassfish application server.
#brew 'glassfish'

# Android
#cask 'android-studio'
#cask 'android-file-transfer'
#cask 'android-messages'
#cask 'android-ndk'
#cask 'android-platform-tools'
#cask 'android-sdk'

## JavaScript

# Node.js is a JavaScript platform for building fast, scalable network app.
brew 'node'

# V8 JavaScript Engine.
brew 'v8'

# JSON output using the shell
brew 'jo'

# Package Managers
brew 'volta'
brew 'npm'
brew 'yarn'

# JID JSON explorer
tap 'simeji/jid'
brew 'jid'

## Lua

# Lua scripting language
#brew 'lua'

# Lua just-in-time compiler
#brew 'luajit'

## Perl

# Perl programming language, esp. for systems administration.
#brew 'perl'

# Perl-Compatible Regular Expressions pattern matching tools.
#brew 'pcre'

# CPAN search for perl modules
#brew 'cpansearch'

## Python

# Python programming language, esp. for systems scripting.
brew 'python'
brew 'python3'

# Python on the JVM
#brew 'jython'

## R

# R programming language, esp. for statistics. TODO: which R do we want?
#brew 'r'

## Ruby

# chruby changes the current Ruby.
#brew 'chruby'

# JRuby is a high performance, stable, fully threaded Java implementation of Ruby.
#brew 'jruby'

# Ruby programming language; compare `perl`, `python`.
#brew 'ruby'

# Tool to install various implementations of Ruby.
#brew 'ruby-install'

## Rust

# Rust programming language
#brew 'rust'

## Scala

# Scala programming language, that runs on top of the JVM.
#brew 'scala'

## iOS, Objective-C, Swift

# Alcatraz Xcode plugin manager
#cask 'alcatraz'

# Appium test automation framework
#cask 'appium'

# Carthage Xcode project dependency manager.
#brew 'carthage'

# Command-line application launcher for the iOS Simulator
#brew 'ios-sim'

# Tool to help with Swift style and conventions.
#brew 'swiftlint'

# SourceKitten attaches to SourceKit AST.
#brew 'sourcekitten'

## Tcl/Tk cross-platform toolkit
#brew 'tcl-tk'

##
# Programming processes
##

## Compilers

# GCC GNU Compiler Collection
brew 'gcc'

# LLVM compiler
brew 'llvm', args: ['with-toolchain']

## Continuous automation

# Jenkins open source automation server for continuous integration
#brew 'jenkins'

## Serializers

# Protocol buffers for serializing structured data; compare thrift.
#brew 'protobuf'
#brew 'protobuf-c'

##
# Platforms
##

# Azure by Microsoft
#brew 'azure-cli'

# Amazon Web Services (AWS) Command Line Interface (CLI)
brew 'awscli'

# AWS command line tools
tap 'wallix/awless'
brew 'awless'

# Google Cloud Platform (GCP)
#brew 'gcloud'

# Heroku app hosting
#brew 'heroku'

## Virtual machines

# QEMU is a free and open-source emulator that performs hardware virtualization.
#brew 'qemu'

# VirtualBox creates and configures portable development environments, by Oracle.
#cask 'virtualbox'

# VMWare Fusion virutal machines
#cask 'vmware-fusion'

# Vagrant lightweight, reproducible, portable development environments
#cask 'vagrant'
#cask 'vagrant-manager'

## Provisioning

# Terraform common configuration to launch infrastructure.
#brew 'terraform'

## Configuration management

# Ansible is a simple way to automate apps and IT infrastructure.
#brew 'ansible'

## Containeriztion

# Docker assembles applications from components.
cask 'docker'

## Orchestration

# Kubernetes Solo cluster for macOS.
#cask 'kube-solo'

# Kubernetes command-line tool to run commands against Kubernetes clusters.
#brew 'kubectl'

# Run a single-node Kubernetes cluster in a virtual machine on your personal computer.
#brew 'minikube'

###########################################################################
#
# PAID SOFTWARE
#
###########################################################################

##
# This section installs software that costs money.
# In general, we aim to install free trial versions.
#
# We pay for licenses for this software for our teammates
# when we work on projects that use this software.
#
# You may want to customize this section by deleting any items that
# you don't want to use or purchase, because this will save disk space.
##

##
# JetBrains
#
# JetBrains is paid software suitable for professional programmers,
# such as Integrated Development Environments (IDEs) for popular
# programming languages, including Java, Python, Ruby, PHP, etc.
##

# AppCode Swift IDE
#cask 'appcode'

# CLion C/C++ IDE
#cask 'clion'

# DataGrip SQL IDE
#cask 'datagrip'

# IntelliJ Java IDE
cask 'intellij-idea'

# PhpStorm PHP IDE
#cask 'phpstorm'

# PyCharm Python IDE
#cask 'pycharm'

# RubyMine Ruby IDE
#cask 'rubymine'

# WebStorm IDE
#cask 'webstorm'

###########################################################################
#
# LIBRARIES
#
###########################################################################

##
# Libraries
#
# We do this near the end of this file,
# because we expect these will already be
# installed by a bunch of the software above.
#
# This section here is really just to cover our
# bases to make sure we have the libraries that we
# sometimes need for building other software later on.
##

# THe libevent API provides provides asynchronous event notification and callbacks.
brew 'libevent'

# Magic number recognition library for file types.
brew 'libmagic'

# Audio/Visual converters
brew 'libav'

# Curl web fetcher
#brew 'libcurl'  # EOL

# Foreign Function Interface Library
brew 'libffi'

# Text encoding
brew 'libiconv'

# File magic number recognizer
brew 'libmagic'

# Sodium secure cryptography
brew 'libsodium'

# GNU libtool is a generic library support script.
brew 'libtool'

# XML handlers
brew 'libxml2'
brew 'libxslt'

# High-level interface to X.509 and CMS (Cryptographic Message Syntax)
brew 'libksba'

# YAML markup language
brew 'libyaml'

# YAML lint validator
brew 'yamllint'

# Images
brew 'libjpg'
brew 'libpng'
brew 'libtiff'


###########################################################################
#
# FONTS
#
###########################################################################

##
# Fonts
#
# We like having lots of fonts.
#
# You may prefer to trim this list.
#
##

cask 'font-3270'
cask 'font-abeezee'
cask 'font-abel'
cask 'font-aboriginal-sans'
cask 'font-aboriginal-serif'
cask 'font-abril-fatface'
cask 'font-aclonica'
cask 'font-acme'
cask 'font-actor'
cask 'font-adamina'
cask 'font-adinatha-tamil-brahmi'
cask 'font-advent-pro'
cask 'font-african-sans'
cask 'font-african-serif'
cask 'font-aguafina-script'
cask 'font-ahuramzda'
cask 'font-aileron'
cask 'font-akronim'
cask 'font-aladin'
cask 'font-aldrich'
cask 'font-alef'
cask 'font-aleo'
cask 'font-alex-brush'
cask 'font-alfa-slab-one'
cask 'font-alice'
cask 'font-alike-angular'
cask 'font-alike'
cask 'font-allan'
cask 'font-allerta-stencil'
cask 'font-allerta'
cask 'font-allura'
cask 'font-almendra-display'
cask 'font-almendra-sc'
cask 'font-almendra'
cask 'font-amarante'
cask 'font-amaranth'
cask 'font-amatic-sc'
cask 'font-amethysta'
cask 'font-amiri'
cask 'font-anaheim'
cask 'font-andada-sc'
cask 'font-andada'
cask 'font-andagii'
cask 'font-andale-mono'
cask 'font-andika'
cask 'font-angkor'
cask 'font-anka-coder'
cask 'font-annie-use-your-telescope'
cask 'font-anonymice-powerline'
cask 'font-anonymous-pro'
cask 'font-antic-didone'
cask 'font-antic-slab'
cask 'font-antic'
cask 'font-antinoou'
cask 'font-anton'
cask 'font-arapey'
cask 'font-arbutus-slab'
cask 'font-arbutus'
cask 'font-architects-daughter'
cask 'font-archivo-black'
cask 'font-archivo-narrow'
cask 'font-arial-black'
cask 'font-arial'
cask 'font-arimo'
cask 'font-arizonia'
cask 'font-armata'
cask 'font-artifika'
cask 'font-arvo'
cask 'font-asap'
cask 'font-asset'
cask 'font-astloch'
cask 'font-asul'
cask 'font-atomic-age'
cask 'font-aubrey'
cask 'font-audiowide'
cask 'font-autour-one'
cask 'font-average-sans'
cask 'font-average'
cask 'font-averia-gruesa-libre'
cask 'font-averia-libre'
cask 'font-averia-sans-libre'
cask 'font-averia-serif-libre'
cask 'font-awesome-terminal-fonts'
cask 'font-babelstone-han'
cask 'font-bad-script'
cask 'font-baloo'
cask 'font-balthazar'
cask 'font-bangers'
cask 'font-baron'
cask 'font-basic'
cask 'font-battambang'
cask 'font-baumans'
cask 'font-bayon'
cask 'font-belgrano'
cask 'font-belleza'
cask 'font-benchnine'
cask 'font-bentham'
cask 'font-berkshire-swash'
cask 'font-bevan'
cask 'font-bf-tiny-hand'
cask 'font-bigelow-rules'
cask 'font-bigshot-one'
cask 'font-bilbo-swash-caps'
cask 'font-bilbo'
cask 'font-bitstream-vera'
cask 'font-bitter'
cask 'font-black-ops-one'
cask 'font-blokk-neue'
cask 'font-bokor'
cask 'font-bonbon'
cask 'font-boogaloo'
cask 'font-bowlby-one-sc'
cask 'font-bowlby-one'
cask 'font-bravura'
cask 'font-brawler'
cask 'font-bree-serif'
cask 'font-bubblegum-sans'
cask 'font-bubbler-one'
cask 'font-buda'
cask 'font-buenard'
cask 'font-bukyvede-bold'
cask 'font-bukyvede-italic'
cask 'font-bukyvede-regular'
cask 'font-bungee'
cask 'font-butcherman'
cask 'font-butterfly-kids'
cask 'font-cabin-condensed'
cask 'font-cabin-sketch'
cask 'font-cabin'
cask 'font-caesar-dressing'
cask 'font-cagliostro'
cask 'font-calligraffitti'
cask 'font-cambo'
cask 'font-camingocode'
cask 'font-candal'
cask 'font-cantarell'
cask 'font-cantata-one'
cask 'font-cantora-one'
cask 'font-capriola'
cask 'font-cardo'
cask 'font-carme'
cask 'font-carrois-gothic-sc'
cask 'font-carrois-gothic'
cask 'font-carter-one'
cask 'font-caudex'
cask 'font-cedarville-cursive'
cask 'font-ceviche-one'
cask 'font-changa-one'
cask 'font-chango'
cask 'font-chapbook'
cask 'font-charis-sil'
cask 'font-charter'
cask 'font-chau-philomene-one'
cask 'font-chela-one'
cask 'font-chelsea-market'
cask 'font-chenla'
cask 'font-cherry-cream-soda'
cask 'font-cherry-swash'
cask 'font-chewy'
cask 'font-chicle'
cask 'font-chivo'
cask 'font-cinzel-decorative'
cask 'font-cinzel'
cask 'font-clear-sans'
cask 'font-clicker-script'
cask 'font-coda-caption'
cask 'font-coda'
cask 'font-code'
cask 'font-code2000'
cask 'font-code2001'
cask 'font-code2002'
cask 'font-codystar'
cask 'font-combo'
cask 'font-comfortaa'
cask 'font-comic-neue'
cask 'font-comic-sans-ms'
cask 'font-coming-soon'
cask 'font-computer-modern'
cask 'font-conakry'
cask 'font-concert-one'
cask 'font-condiment'
cask 'font-consolas-for-powerline'
cask 'font-constructium'
cask 'font-content'
cask 'font-contrail-one'
cask 'font-convergence'
cask 'font-cookie'
cask 'font-copse'
cask 'font-corben'
cask 'font-courgette'
cask 'font-courier-new'
cask 'font-courier-prime'
cask 'font-cousine'
cask 'font-coustard'
cask 'font-covered-by-your-grace'
cask 'font-crafty-girls'
cask 'font-creepster'
cask 'font-crete-round'
cask 'font-crimson-text'
cask 'font-croissant-one'
cask 'font-crushed'
cask 'font-cuprum'
cask 'font-cutive-mono'
cask 'font-cutive'
cask 'font-cwtex-q'
cask 'font-d2coding'
cask 'font-damion'
cask 'font-dancing-script'
cask 'font-dangrek'
cask 'font-dashicons'
cask 'font-dawning-of-a-new-day'
cask 'font-days-one'
cask 'font-dejavu-sans-mono-for-powerline'
cask 'font-dejavu-sans'
cask 'font-delius-swash-caps'
cask 'font-delius-unicase'
cask 'font-delius'
cask 'font-della-respira'
cask 'font-denk-one'
cask 'font-devicons'
cask 'font-devonshire'
cask 'font-dhyana'
cask 'font-didact-gothic'
cask 'font-digohweli-old-do'
cask 'font-digohweli'
cask 'font-diplomata-sc'
cask 'font-diplomata'
cask 'font-disclaimer'
cask 'font-domine'
cask 'font-donegal-one'
cask 'font-doppio-one'
cask 'font-dorsa'
cask 'font-dosis'
cask 'font-dr-sugiyama'
cask 'font-droid-sans-mono-for-powerline'
cask 'font-droidsansmono-nerd-font'
cask 'font-droidsansmono-nerd-font-mono'
cask 'font-dukor'
cask 'font-duru-sans'
cask 'font-dynalight'
cask 'font-eagle-lake'
cask 'font-eater'
cask 'font-eb-garamond'
cask 'font-economica'
cask 'font-edlo'
cask 'font-eeyek-unicode'
cask 'font-electrolize'
cask 'font-elsie-swash-caps'
cask 'font-elsie'
cask 'font-emblema-one'
cask 'font-emilys-candy'
cask 'font-engagement'
cask 'font-englebert'
cask 'font-enriqueta'
cask 'font-erica-one'
cask 'font-esteban'
cask 'font-et-book'
cask 'font-euphoria-script'
cask 'font-everson-mono'
cask 'font-ewert'
cask 'font-exo'
cask 'font-exo2'
cask 'font-expletus-sans'
cask 'font-ezra-sil'
cask 'font-fairfax'
cask 'font-fantasque-sans-mono'
cask 'font-fanwood-text'
cask 'font-fascinate-inline'
cask 'font-fascinate'
cask 'font-faster-one'
cask 'font-fasthand'
cask 'font-fauna-one'
cask 'font-federant'
cask 'font-federo'
cask 'font-felipa'
cask 'font-fenix'
cask 'font-finger-paint'
cask 'font-fira-code'
cask 'font-fira-mono-for-powerline'
cask 'font-fira-mono'
cask 'font-fira-sans'
cask 'font-firacode-nerd-font-mono'
cask 'font-firacode-nerd-font'
cask 'font-fjalla-one'
cask 'font-fjord-one'
cask 'font-flamenco'
cask 'font-flavors'
cask 'font-fondamento'
cask 'font-fontawesome'
cask 'font-fontdiner-swanky'
cask 'font-forum'
cask 'font-foundation-icons'
cask 'font-francois-one'
cask 'font-freckle-face'
cask 'font-fredericka-the-great'
cask 'font-fredoka-one'
cask 'font-free-hk-kai'
cask 'font-freehand'
cask 'font-freesans'
cask 'font-fresca'
cask 'font-frijole'
cask 'font-fruktur'
cask 'font-fugaz-one'
cask 'font-gabriela'
cask 'font-gafata'
cask 'font-galdeano'
cask 'font-galindo'
cask 'font-gandom'
cask 'font-genjyuugothic-l'
cask 'font-genjyuugothic-x'
cask 'font-genjyuugothic'
cask 'font-genshingothic'
cask 'font-gentium-basic'
cask 'font-gentium-book-basic'
cask 'font-gentium-plus'
cask 'font-geo'
cask 'font-georgia'
cask 'font-geostar-fill'
cask 'font-geostar'
cask 'font-germania-one'
cask 'font-gfs-didot'
cask 'font-gfs-neohellenic'
cask 'font-gidole'
cask 'font-gilda-display'
cask 'font-give-you-glory'
cask 'font-glass-antiqua'
cask 'font-glegoo'
cask 'font-glober'
cask 'font-gloria-hallelujah'
cask 'font-gnu-unifont'
cask 'font-go-medium'
cask 'font-go-mono'
cask 'font-go'
cask 'font-goblin-one'
cask 'font-gochi-hand'
cask 'font-gorditas'
cask 'font-goudy-bookletter1911'
cask 'font-graduate'
cask 'font-grand-hotel'
cask 'font-gravitas-one'
cask 'font-great-vibes'
cask 'font-griffy'
cask 'font-gruppo'
cask 'font-gudea'
cask 'font-habibi'
cask 'font-hack-nerd-font'
cask 'font-halant'
cask 'font-hammersmith-one'
cask 'font-han-nom-a'
cask 'font-hanalei-fill'
cask 'font-hanalei'
cask 'font-hanamina'
cask 'font-handlee'
cask 'font-hanuman'
cask 'font-happy-monkey'
cask 'font-hasklig'
cask 'font-headland-one'
cask 'font-henny-penny'
cask 'font-hermit'
cask 'font-herr-von-muellerhoff'
cask 'font-hind'
cask 'font-holtwood-one-sc'
cask 'font-homemade-apple'
cask 'font-homenaje'
cask 'font-hyppolit'
cask 'font-iceberg'
cask 'font-iceland'
cask 'font-icomoon'
cask 'font-idealist-sans'
cask 'font-impact'
cask 'font-imprima'
cask 'font-inconsolata-dz-for-powerline'
cask 'font-inconsolata-dz'
cask 'font-inconsolata-for-powerline'
cask 'font-inconsolata-g-for-powerline'
cask 'font-inconsolata-lgc'
cask 'font-inconsolata'
cask 'font-inder'
cask 'font-indie-flower'
cask 'font-inika'
cask 'font-input'
cask 'font-ionicons'
cask 'font-iosevka'
cask 'font-iranian-sans'
cask 'font-iranian-serif'
cask 'font-irish-grover'
cask 'font-istok-web'
cask 'font-italiana'
cask 'font-italianno'
cask 'font-jaapokki'
cask 'font-jacques-francois-shadow'
cask 'font-jacques-francois'
cask 'font-jim-nightshade'
cask 'font-jockey-one'
cask 'font-jolly-lodger'
cask 'font-josefin-sans'
cask 'font-josefin-slab'
cask 'font-joti-one'
cask 'font-jsmath-cmbx10'
cask 'font-judson'
cask 'font-julee'
cask 'font-julius-sans-one'
cask 'font-junge'
cask 'font-junicode'
cask 'font-jura'
cask 'font-just-another-hand'
cask 'font-just-me-again-down-here'
cask 'font-kacstone'
cask 'font-kalam'
cask 'font-kameron'
cask 'font-kantumruy'
cask 'font-karla-tamil-inclined'
cask 'font-karla-tamil-upright'
cask 'font-karla'
cask 'font-karma'
cask 'font-kaushan-script'
cask 'font-kavoon'
cask 'font-kawkab-mono'
cask 'font-kayases'
cask 'font-kdam-thmor'
cask 'font-keania-one'
cask 'font-keep-calm'
cask 'font-kelly-slab'
cask 'font-kenia'
cask 'font-khand'
cask 'font-khmer'
cask 'font-kisiska'
cask 'font-kite-one'
cask 'font-knewave'
cask 'font-koruri'
cask 'font-kotta-one'
cask 'font-koulen'
cask 'font-kranky'
cask 'font-kreon'
cask 'font-kristi'
cask 'font-krona-one'
cask 'font-la-belle-aurore'
cask 'font-laila'
cask 'font-lalezar'
cask 'font-lancelot'
cask 'font-lateef'
cask 'font-latin-modern-math'
cask 'font-latin-modern'
cask 'font-lato'
cask 'font-league-gothic'
cask 'font-league-script'
cask 'font-league-spartan'
cask 'font-leckerli-one'
cask 'font-ledger'
cask 'font-lekton'
cask 'font-lemon'
cask 'font-liberation-mono-for-powerline'
cask 'font-liberation-sans'
cask 'font-libertinus'
cask 'font-libre-baskerville'
cask 'font-libre-caslon-text'
cask 'font-libre-franklin'
cask 'font-life-savers'
cask 'font-ligature-symbols'
cask 'font-lilita-one'
cask 'font-lily-script-one'
cask 'font-limelight'
cask 'font-linden-hill'
cask 'font-linux-biolinum'
cask 'font-linux-libertine'
cask 'font-lobster-two'
cask 'font-lobster'
cask 'font-londrina-outline'
cask 'font-londrina-shadow'
cask 'font-londrina-sketch'
cask 'font-londrina-solid'
cask 'font-lora'
cask 'font-love-ya-like-a-sister'
cask 'font-loved-by-the-king'
cask 'font-lovers-quarrel'
cask 'font-luckiest-guy'
cask 'font-luculent'
cask 'font-lusitana'
cask 'font-lustria'
cask 'font-m-plus'
cask 'font-macondo-swash-caps'
cask 'font-macondo'
cask 'font-magra'
cask 'font-maiden-orange'
cask 'font-mako'
cask 'font-marcellus-sc'
cask 'font-marcellus'
cask 'font-marck-script'
cask 'font-margarine'
cask 'font-marko-one'
cask 'font-marmelad'
cask 'font-marta'
cask 'font-marvel'
cask 'font-masinahikan-dene'
cask 'font-masinahikan'
cask 'font-mate-sc'
cask 'font-mate'
cask 'font-material-icons'
cask 'font-materialdesignicons-webfont'
cask 'font-maven-pro'
cask 'font-mclaren'
cask 'font-meddon'
cask 'font-medievalsharp'
cask 'font-medula-one'
cask 'font-megrim'
cask 'font-meie-script'
cask 'font-menlo-for-powerline'
cask 'font-merienda-one'
cask 'font-merienda'
cask 'font-merriweather-sans'
cask 'font-merriweather'
cask 'font-metal-mania'
cask 'font-metal'
cask 'font-metamorphous'
cask 'font-metrophobic'
cask 'font-mfizz'
cask 'font-miao-unicode'
cask 'font-michroma'
cask 'font-migmix-1m'
cask 'font-migmix-1p'
cask 'font-migmix-2m'
cask 'font-migmix-2p'
cask 'font-migu-1c'
cask 'font-migu-1m'
cask 'font-migu-1p'
cask 'font-migu-2m'
cask 'font-milonga'
cask 'font-miltonian-tattoo'
cask 'font-miltonian'
cask 'font-miniver'
cask 'font-miss-fajardose'
cask 'font-modern-antiqua'
cask 'font-molengo'
cask 'font-molle'
cask 'font-monda'
cask 'font-monofett'
cask 'font-monofur-for-powerline'
cask 'font-monoid'
cask 'font-monoisome'
cask 'font-mononoki'
cask 'font-monoton'
cask 'font-monsieur-la-doulaise'
cask 'font-montaga'
cask 'font-montez'
cask 'font-montserrat-subrayada'
cask 'font-montserrat'
cask 'font-moul'
cask 'font-moulpali'
cask 'font-mountains-of-christmas'
cask 'font-mouse-memoirs'
cask 'font-mr-bedfort'
cask 'font-mr-dafoe'
cask 'font-mr-de-haviland'
cask 'font-mrs-saint-delafield'
cask 'font-mrs-sheppards'
cask 'font-mukti-narrow'
cask 'font-muli'
cask 'font-myrica'
cask 'font-myricam'
cask 'font-mystery-quest'
cask 'font-n-gage'
cask 'font-namdhinggo-sil'
cask 'font-nanumgothic'
cask 'font-nanumgothiccoding'
cask 'font-nanummyeongjo'
cask 'font-neucha'
cask 'font-neuton'
cask 'font-new-athena-unicode'
cask 'font-new-rocker'
cask 'font-news-cycle'
cask 'font-nexa'
cask 'font-niconne'
cask 'font-nika'
cask 'font-nixie-one'
cask 'font-nobile'
cask 'font-nokora'
cask 'font-norican'
cask 'font-norwester'
cask 'font-nosifer'
cask 'font-nothing-you-could-do'
cask 'font-noticia-text'
cask 'font-noto-color-emoji'
cask 'font-noto-emoji'
cask 'font-noto-kufi-arabic'
cask 'font-noto-mono'
cask 'font-noto-naskh-arabic'
cask 'font-noto-nastaliq-urdu'
cask 'font-noto-sans-armenian'
cask 'font-noto-sans-avestan'
cask 'font-noto-sans-balinese'
cask 'font-noto-sans-bamum'
cask 'font-noto-sans-batak'
cask 'font-noto-sans-bengali'
cask 'font-noto-sans-brahmi'
cask 'font-noto-sans-buginese'
cask 'font-noto-sans-buhid'
cask 'font-noto-sans-canadian-aboriginal'
cask 'font-noto-sans-carian'
cask 'font-noto-sans-cham'
cask 'font-noto-sans-cherokee'
cask 'font-noto-sans-cjk-jp'
cask 'font-noto-sans-cjk-kr'
cask 'font-noto-sans-cjk-sc'
cask 'font-noto-sans-cjk-tc'
cask 'font-noto-sans-cjk'
cask 'font-noto-sans-coptic'
cask 'font-noto-sans-cuneiform'
cask 'font-noto-sans-cypriot'
cask 'font-noto-sans-deseret'
cask 'font-noto-sans-devanagari'
cask 'font-noto-sans-egyptian-hieroglyphs'
cask 'font-noto-sans-ethiopic'
cask 'font-noto-sans-georgian'
cask 'font-noto-sans-glagolitic'
cask 'font-noto-sans-gothic'
cask 'font-noto-sans-gujarati'
cask 'font-noto-sans-gurmukhi'
cask 'font-noto-sans-hanunoo'
cask 'font-noto-sans-imperial-aramaic'
cask 'font-noto-sans-inscriptional-pahlavi'
cask 'font-noto-sans-inscriptional-parthian'
cask 'font-noto-sans-javanese'
cask 'font-noto-sans-kaithi'
cask 'font-noto-sans-kannada'
cask 'font-noto-sans-kayah-li'
cask 'font-noto-sans-kharoshthi'
cask 'font-noto-sans-khmer'
cask 'font-noto-sans-lao'
cask 'font-noto-sans-lepcha'
cask 'font-noto-sans-limbu'
cask 'font-noto-sans-linear-b'
cask 'font-noto-sans-lisu'
cask 'font-noto-sans-lycian'
cask 'font-noto-sans-lydian'
cask 'font-noto-sans-malayalam'
cask 'font-noto-sans-mandaic'
cask 'font-noto-sans-meetei-mayek'
cask 'font-noto-sans-mongolian'
cask 'font-noto-sans-myanmar'
cask 'font-noto-sans-n-ko'
cask 'font-noto-sans-new-tai-lue'
cask 'font-noto-sans-ogham'
cask 'font-noto-sans-ol-chiki'
cask 'font-noto-sans-old-italic'
cask 'font-noto-sans-old-persian'
cask 'font-noto-sans-old-south-arabian'
cask 'font-noto-sans-old-turkic'
cask 'font-noto-sans-oriya'
cask 'font-noto-sans-osmanya'
cask 'font-noto-sans-phags-pa'
cask 'font-noto-sans-phoenician'
cask 'font-noto-sans-rejang'
cask 'font-noto-sans-runic'
cask 'font-noto-sans-samaritan'
cask 'font-noto-sans-saurashtra'
cask 'font-noto-sans-shavian'
cask 'font-noto-sans-sinhala'
cask 'font-noto-sans-sundanese'
cask 'font-noto-sans-syloti-nagri'
cask 'font-noto-sans-symbols'
cask 'font-noto-sans-syriac-eastern'
cask 'font-noto-sans-syriac-estrangela'
cask 'font-noto-sans-syriac-western'
cask 'font-noto-sans-tagalog'
cask 'font-noto-sans-tagbanwa'
cask 'font-noto-sans-tai-le'
cask 'font-noto-sans-tai-tham'
cask 'font-noto-sans-tai-viet'
cask 'font-noto-sans-tamil'
cask 'font-noto-sans-telugu'
cask 'font-noto-sans-thaana'
cask 'font-noto-sans-thai'
cask 'font-noto-sans-tibetan'
cask 'font-noto-sans-tifinagh'
cask 'font-noto-sans-ugaritic'
cask 'font-noto-sans-vai'
cask 'font-noto-sans-yi'
cask 'font-noto-sans'
cask 'font-noto-serif-armenian'
cask 'font-noto-serif-georgian'
cask 'font-noto-serif-khmer'
cask 'font-noto-serif-lao'
cask 'font-noto-serif-thai'
cask 'font-noto-serif'
cask 'font-nova-cut'
cask 'font-nova-flat'
cask 'font-nova-mono'
cask 'font-nova-oval'
cask 'font-nova-round'
cask 'font-nova-script'
cask 'font-nova-slim'
cask 'font-nova-square'
cask 'font-numans'
cask 'font-nunito'
cask 'font-odor-mean-chey'
cask 'font-office-code-pro'
cask 'font-offside'
cask 'font-old-standard-tt'
cask 'font-oldenburg'
cask 'font-oleo-script-swash-caps'
cask 'font-oleo-script'
cask 'font-open-iconic'
cask 'font-open-sans-condensed'
cask 'font-open-sans'
cask 'font-opendyslexic'
cask 'font-oranienbaum'
cask 'font-orbitron'
cask 'font-oregano'
cask 'font-orienta'
cask 'font-original-surfer'
cask 'font-oskiblackfoot'
cask 'font-oskidakelh'
cask 'font-oskidenea'
cask 'font-oskideneb'
cask 'font-oskidenec'
cask 'font-oskidenes'
cask 'font-oskieast'
cask 'font-oskiwest'
cask 'font-oswald'
cask 'font-over-the-rainbow'
cask 'font-overlock-sc'
cask 'font-overlock'
cask 'font-overpass'
cask 'font-ovo'
cask 'font-oxygen-mono'
cask 'font-oxygen'
cask 'font-pacifico'
cask 'font-padauk'
cask 'font-palemonas'
cask 'font-paprika'
cask 'font-parastoo'
cask 'font-parisienne'
cask 'font-passero-one'
cask 'font-passion-one'
cask 'font-pathway-gothic-one'
cask 'font-patrick-hand-sc'
cask 'font-patrick-hand'
cask 'font-patua-one'
cask 'font-paytone-one'
cask 'font-penuturesu'
cask 'font-peralta'
cask 'font-permanent-marker'
cask 'font-petit-formal-script'
cask 'font-petrona'
cask 'font-phetsarath'
cask 'font-philosopher'
cask 'font-piedra'
cask 'font-pinyon-script'
cask 'font-pirata-one'
cask 'font-pitabek'
cask 'font-plaster'
cask 'font-play'
cask 'font-playball'
cask 'font-playfair-display-sc'
cask 'font-playfair-display'
cask 'font-podkova'
cask 'font-poiret-one'
cask 'font-poller-one'
cask 'font-poly'
cask 'font-pompiere'
cask 'font-pontano-sans'
cask 'font-poppins'
cask 'font-port-lligat-sans'
cask 'font-port-lligat-slab'
cask 'font-prata'
cask 'font-preahvihear'
cask 'font-press-start2p'
cask 'font-prime'
cask 'font-prince-valiant'
cask 'font-princess-sofia'
cask 'font-prociono'
cask 'font-profontx'
cask 'font-prosto-one'
cask 'font-pt-mono'
cask 'font-pt-sans'
cask 'font-pt-serif'
cask 'font-puritan'
cask 'font-purple-purse'
cask 'font-qataban'
cask 'font-quando'
cask 'font-quantico'
cask 'font-quattrocento-sans'
cask 'font-quattrocento'
cask 'font-questrial'
cask 'font-quicksand'
cask 'font-quintessential'
cask 'font-quivira'
cask 'font-qwigley'
cask 'font-racing-sans-one'
cask 'font-radley'
cask 'font-rajdhani'
cask 'font-raleway-dots'
cask 'font-raleway'
cask 'font-rambla'
cask 'font-rammetto-one'
cask 'font-ranchers'
cask 'font-rancho'
cask 'font-rationale'
cask 'font-redacted'
cask 'font-redressed'
cask 'font-reenie-beanie'
cask 'font-revalia'
cask 'font-ribeye-marrow'
cask 'font-ribeye'
cask 'font-ricty-diminished'
cask 'font-righteous'
cask 'font-risque'
cask 'font-roboto-condensed'
cask 'font-roboto-mono-for-powerline'
cask 'font-roboto-mono'
cask 'font-roboto-slab'
cask 'font-roboto'
cask 'font-rochester'
cask 'font-rock-salt'
cask 'font-rokkitt'
cask 'font-romanesco'
cask 'font-ropa-sans'
cask 'font-rosario'
cask 'font-rosarivo'
cask 'font-rotinonhsonni-sans'
cask 'font-rotinonhsonni-serif'
cask 'font-rouge-script'
cask 'font-rounded-m-plus'
cask 'font-rozha-one'
cask 'font-ruda'
cask 'font-rufina'
cask 'font-ruge-boogie'
cask 'font-ruluko'
cask 'font-rum-raisin'
cask 'font-rupakara'
cask 'font-ruslan-display'
cask 'font-russo-one'
cask 'font-ruthie'
cask 'font-rye'
cask 'font-sacramento'
cask 'font-sadagolthina'
cask 'font-sail'
cask 'font-salsa'
cask 'font-samim'
cask 'font-sanchez'
cask 'font-sancreek'
cask 'font-sansita-one'
cask 'font-sarina'
cask 'font-sarpanch'
cask 'font-satisfy'
cask 'font-scada'
cask 'font-scheherazade'
cask 'font-schoolbell'
cask 'font-seaweed-script'
cask 'font-sevillana'
cask 'font-seymour-one'
cask 'font-shabnam'
cask 'font-shadows-into-light-two'
cask 'font-shadows-into-light'
cask 'font-shanti'
cask 'font-share-tech-mono'
cask 'font-share-tech'
cask 'font-share'
cask 'font-shojumaru'
cask 'font-short-stack'
cask 'font-siemreap'
cask 'font-sigmar-one'
cask 'font-signika-negative'
cask 'font-silent-lips'
cask 'font-simonetta'
cask 'font-sinkin-sans'
cask 'font-sintony'
cask 'font-sirin-stencil'
cask 'font-six-caps'
cask 'font-skranji'
cask 'font-slackey'
cask 'font-smokum'
cask 'font-smythe'
cask 'font-sniglet'
cask 'font-snippet'
cask 'font-snowburst-one'
cask 'font-sofadi-one'
cask 'font-sofia'
cask 'font-sonsie-one'
cask 'font-sorts-mill-goudy'
cask 'font-source-code-pro-for-powerline'
cask 'font-source-code-pro'
cask 'font-source-han-code-jp'
cask 'font-source-han-sans'
cask 'font-source-sans-pro'
cask 'font-source-serif-pro'
cask 'font-space-mono'
cask 'font-special-elite'
cask 'font-spicy-rice'
cask 'font-spinnaker'
cask 'font-spirax'
cask 'font-squada-one'
cask 'font-stalemate'
cask 'font-stalinist-one'
cask 'font-stardos-stencil'
cask 'font-stint-ultra-condensed'
cask 'font-stint-ultra-expanded'
cask 'font-stoke'
cask 'font-strait'
cask 'font-sue-ellen-francisco'
cask 'font-sunshiney'
cask 'font-supermercado-one'
cask 'font-swanky-and-moo-moo'
cask 'font-symbola'
cask 'font-syncopate'
cask 'font-tai-le-valentinium'
cask 'font-takaoex'
cask 'font-tangerine'
cask 'font-taprom'
cask 'font-tauri'
cask 'font-teko'
cask 'font-telex'
cask 'font-tenor-sans'
cask 'font-terminus'
cask 'font-tex-gyre-adventor'
cask 'font-tex-gyre-bonum'
cask 'font-tex-gyre-chorus'
cask 'font-tex-gyre-cursor'
cask 'font-tex-gyre-heros'
cask 'font-tex-gyre-pagella-math'
cask 'font-tex-gyre-pagella'
cask 'font-tex-gyre-schola'
cask 'font-tex-gyre-termes'
cask 'font-text-me-one'
cask 'font-thabit'
cask 'font-the-girl-next-door'
cask 'font-tibetan-machine-uni'
cask 'font-tienne'
cask 'font-tillana'
cask 'font-times-new-roman'
cask 'font-tinos'
cask 'font-titan-one'
cask 'font-trade-winds'
cask 'font-trebuchet-ms'
cask 'font-trocchi'
cask 'font-trochut'
cask 'font-trykker'
cask 'font-tuffy'
cask 'font-tulpen-one'
cask 'font-twitter-color-emoji'
cask 'font-ubuntu-mono-derivative-powerline'
cask 'font-ubuntu'
cask 'font-ultra'
cask 'font-uncial-antiqua'
cask 'font-underdog'
cask 'font-unica-one'
cask 'font-unifrakturcook'
cask 'font-unifrakturmaguntia'
cask 'font-unkempt'
cask 'font-unlock'
cask 'font-unna'
cask 'font-vampiro-one'
cask 'font-varela-round'
cask 'font-varela'
cask 'font-vast-shadow'
cask 'font-vazir-code'
cask 'font-vazir'
cask 'font-verdana'
cask 'font-vibur'
cask 'font-vidaloka'
cask 'font-viga'
cask 'font-voces'
cask 'font-volkhov'
cask 'font-vollkorn'
cask 'font-voltaire'
cask 'font-vt323'
cask 'font-waiting-for-the-sunrise'
cask 'font-wakor'
cask 'font-wallpoet'
cask 'font-walter-turncoat'
cask 'font-waltograph'
cask 'font-warnes'
cask 'font-webdings'
cask 'font-wellfleet'
cask 'font-wendy-one'
cask 'font-wenquanyi-micro-hei-lite'
cask 'font-wenquanyi-micro-hei'
cask 'font-wenquanyi-zen-hei'
cask 'font-wire-one'
cask 'font-work-sans'
cask 'font-xits'
cask 'font-yanone-kaffeesatz'
cask 'font-yellowtail'
cask 'font-yeseva-one'
cask 'font-yesteryear'
cask 'font-zeyada'
