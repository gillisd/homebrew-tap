class Dico < Formula
  desc "DICT protocol dictionary server and client"
  homepage "https://www.gnu.org/software/dico/"
  url "https://ftpmirror.gnu.org/gnu/dico/dico-2.12.tar.gz"
  mirror "https://ftp.gnu.org/gnu/dico/dico-2.12.tar.gz"
  sha256 "8c86f94e37368653035de347b86f50cbc9a9046ba840d58ef69bea4699aec86e"
  license "GPL-3.0-or-later"

  depends_on "readline"
  depends_on "zlib"

  on_macos do
    depends_on "gettext"
  end

  def install
    # Build with core features only — skip optional modules that add heavy deps
    system "./configure", *std_configure_args, "--disable-dependency-tracking",
                          "--without-guile", "--without-python", "--without-ldap",
                          "--without-pcre", "--without-wordnet", "--without-tk",
                          "--disable-pam"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dico --version")

    # Functional test: query a test word against the client (will fail to connect
    # but proves the binary works and parses arguments)
    output = shell_output("#{bin}/dico --host localhost --port 1 hello 2>&1", 1)
    assert_match(/connect|refused|error/i, output)

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "Dico", dir_content
  end
end
