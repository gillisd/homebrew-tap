class Teseq < Formula
  desc "Terminal control sequence analyzer and describer"
  homepage "https://www.gnu.org/software/teseq/"
  url "https://ftpmirror.gnu.org/gnu/teseq/teseq-1.1.1.tar.bz2"
  mirror "https://ftp.gnu.org/gnu/teseq/teseq-1.1.1.tar.bz2"
  sha256 "4e681dbc05c61b4b60720fe00dfcc9a4527a1e847a08440ac64107f0065d1957"
  license "GPL-3.0-or-later"

  uses_from_macos "perl"

  def install
    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/teseq --version")

    # Functional test: analyze an ANSI color escape sequence
    (testpath/"input.txt").write "\e[31mHello\e[0m"
    output = shell_output("#{bin}/teseq #{testpath}/input.txt")
    assert_match "SGR", output

    # Test reseq companion script runs
    assert_match "reseq", shell_output("#{bin}/reseq --version 2>&1")

    # Info page must be registered (upstream has @dircategory/@direntry)
    assert_match "teseq", (HOMEBREW_PREFIX/"share/info/dir").read
  end
end
