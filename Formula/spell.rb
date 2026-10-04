class Spell < Formula
  desc "Classic Unix spell checker wrapping Ispell or Aspell"
  homepage "https://www.gnu.org/software/spell/"
  url "https://ftpmirror.gnu.org/gnu/spell/spell-1.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/spell/spell-1.1.tar.gz"
  sha256 "7cc243547eb31360ff769835dc88b5ba4f2f47385daa230523beecf9e1c29744"
  license "GPL-3.0-or-later"

  depends_on "help2man" => :build

  depends_on "aspell"

  def install
    # Makefile.in hardcodes infodir=$(prefix)/info, ignoring configure's --infodir.
    # Fix it to use the standard share/info layout.
    inreplace "Makefile.in", "infodir = $(prefix)/info", "infodir = @infodir@"

    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make"
    # Run install targets sequentially — the hand-written Makefile does not
    # declare ordering dependencies between installdirs and install-info.
    ENV.deparallelize
    system "make", "install"

    # Upstream doesn't ship a man page; generate one from --help/--version
    system "help2man", "#{bin}/spell", "-o", "spell.1"
    man1.install "spell.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/spell --version")

    # Functional test: check spelling of a word list
    (testpath/"words.txt").write "hello\nwrold\ngoodbye\n"
    output = shell_output("#{bin}/spell #{testpath}/words.txt", 0)
    assert_match "wrold", output

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "spell", dir_content
  end
end
