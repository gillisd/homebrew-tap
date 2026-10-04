class Alive < Formula
  desc "Periodic ping utility to check Internet connectivity"
  homepage "https://www.gnu.org/software/alive/"
  url "https://ftpmirror.gnu.org/gnu/alive/alive-2.0.5.tar.lz"
  mirror "https://ftp.gnu.org/gnu/alive/alive-2.0.5.tar.lz"
  sha256 "94cf3dbffd9644405ed4944f94a7bb989674321607318c5a35d5fabc56a75089"
  license "GPL-3.0-or-later"

  depends_on "help2man" => :build
  depends_on "guile"

  def install
    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"

    # Upstream ships no man page; generate one from --help/--version.
    system "help2man", "--no-discard-stderr", bin/"alive", "-o", "alive.1"
    man1.install "alive.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/alive --version")
    assert_match "--help", shell_output("#{bin}/alive --help 2>&1")

    # Info page must be registered (upstream has @dircategory/@direntry)
    assert_match "Alive", (HOMEBREW_PREFIX/"share/info/dir").read
  end
end
