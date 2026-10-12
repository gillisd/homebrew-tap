class Stow < Formula
  desc "Organize software neatly under a single directory tree"
  homepage "https://www.gnu.org/software/stow/"
  url "https://ftpmirror.gnu.org/gnu/stow/stow-2.4.1.tar.bz2"
  mirror "https://ftp.gnu.org/gnu/stow/stow-2.4.1.tar.bz2"
  sha256 "0d85a8513677e7923697bce42cdbb33d2b57af915abde1d0671e7ae80b2ef0b4"
  license "GPL-3.0-or-later"

  uses_from_macos "perl"

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/stow --version")

    # Functional test: actual stow/unstow round-trip
    stow_dir = testpath/"stow"
    target_dir = testpath/"target"
    pkg_dir = stow_dir/"test-pkg/bin"
    pkg_dir.mkpath
    target_dir.mkpath
    (pkg_dir/"hello").write "#!/bin/sh\necho hello\n"
    system bin/"stow", "-d", stow_dir, "-t", target_dir, "-S", "test-pkg"
    assert_predicate target_dir/"bin", :symlink?
    assert_path_exists target_dir/"bin/hello"

    # Info page must be registered in the info directory
    assert_match "stow", (HOMEBREW_PREFIX/"share/info/dir").read
  end
end
