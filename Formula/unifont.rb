class Unifont < Formula
  desc "Font with a glyph for every printable Unicode code point"
  homepage "https://www.gnu.org/software/unifont/"
  url "https://ftpmirror.gnu.org/gnu/unifont/unifont-17.0.03/unifont-17.0.03.tar.gz"
  mirror "https://ftp.gnu.org/gnu/unifont/unifont-17.0.03/unifont-17.0.03.tar.gz"
  sha256 "9a26aa9adfa8eb1f91b0cd9b83e7f95ea9e14c6e85be71aa3ab0df5cb4e69c35"
  license all_of: ["GPL-2.0-or-later", "OFL-1.1"]

  uses_from_macos "perl"

  def install
    # Build the C/Perl utilities, man pages, and docs; install precompiled fonts
    system "make"
    system "make", "install", "PREFIX=#{prefix}", "DESTDIR="
  end

  test do
    # Verify precompiled font files are installed
    assert_path_exists share/"fonts/opentype/unifont/unifont.otf"
    assert_path_exists share/"fonts/X11/misc/unifont.pcf.gz"

    # Functional test: generate a hex glyph range (utilities have no --version)
    output = shell_output("#{bin}/unihexgen 0041 005A")
    assert_match "0041:", output

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "Unifont", dir_content
  end
end
