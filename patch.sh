#!/usr/bin/env zsh

set -euo pipefail

local scriptdir=${0:A:h}
local tapdir=$(brew --repository gillisd/generaltap)
local srcdir=~/repos/tries/2025-12-19-moregnu/recutils
local tarball_response=$(grep -E 'url "https:[^ ]+recutil[^ ]+\.tar\.gz' $tapdir/Formula/*.rb)
local tarball_url=${(Q)${${(z)tarball_response}[-1]}}
local downloads=$scriptdir/downloads
mkdir -p $downloads
rm -rf $downloads/*(N)
(
  cd $downloads
  wget --verbose -O tarball.tar.gz $tarball_url
  tar xzvf tarball.tar.gz
  rm tarball.tar.gz

  cd *(/Y1)

  mv $scriptdir/patches/patch.patch $scriptdir/patches/patch_$(date +%s).patch

  command gdiff \
    -c \
    -r \
    -N \
    --exclude=build_recutils.sh \
    --exclude-from=$srcdir/.gitignore \
    --exclude-from=$srcdir/../anotherignored.txt \
    --exclude-from=$srcdir/../ignored.txt \
    . \
    $srcdir >$scriptdir/patches/patch.patch || true
  )

ruby -i -r ronin/support -e 'include Ronin::Support; str=$<.read; str.gsub!(/(?<=patch.patch\"\n\s\s\s\ssha256 \")[^"]+(?=\")/m, File.sha256("patches/patch.patch")); puts str' Formula/recutils.rb

brew uninstall recutils || true
brew install --verbose --debug --build-from-source gillisd/generaltap/recutils
