#!/usr/bin/env zsh


# anon function ensures the "always" block runs. Otherwise early return, etc won't run it
() {
  emulate -L zsh
  set -eo pipefail
  zmodload zsh/mapfile
  local scriptdir=${0:A:h}
  local tapname="gillisd/tap"
  local tapdir=$(brew --repository $tapname)
  local srcdir=$(mktemp -d)
  local formula_definition=$scriptdir/Formula/recutils.rb
  local srcbranch=add-libsodium-support 
  local srcrepo=gillisd/recutils
  local tarball_response=$(grep -E 'url "https:[^ ]+recutil[^ ]+\.tar\.gz' $tapdir/Formula/*.rb)
  local tarball_url=${(Q)${${(z)tarball_response}[-1]}}
  local downloads=$scriptdir/downloads
  local patch_path=$scriptdir/patches/patch.patch
  {
    () {
      (
        builtin cd $srcdir >/dev/null
        gh repo clone $srcrepo -- -b $srcbranch --single-branch
      )
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
          $srcdir > $patch_path || true
      )
      if ! [[ -f ${patch_path:P} ]] || [[ -z ${mapfile[${patch_path:P}]} ]]; then
        print -u2 "Failed to produce patch. exiting."
        exit 1
      fi

      brew ruby -r digest -e '
          path = $<.path
          str = $<.read
          $<.close

          patch_path = "patches/patch.patch"
          pattern = /(?<=patch.patch\"\n\s\s\s\ssha256 \")[^"]+(?=\")/m
          digest = Digest::SHA256.file(patch_path).hexdigest
          str.gsub!(pattern, digest)
          File.write(path, str)
      ' $formula_definition

      brew uninstall recutils || true
      brew install --verbose --debug --build-from-source $tapname/recutils
  } always {
    print "done"
    rm -rf $srcdir
  }
}
