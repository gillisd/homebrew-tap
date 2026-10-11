class WordnetAT31 < Formula
  desc "Lexical database for the English language"
  homepage "https://wordnet.princeton.edu/"
  url "https://wordnetcode.princeton.edu/3.0/WordNet-3.0.tar.bz2"
  # Version 3.1 is version 3.0 with the 3.1 dictionary.
  version "3.1"
  sha256 "6c492d0c7b4a40e7674d088191d3aa11f373bb1da60762e098b8ee2dda96ef22"
  license "WordNet"
  revision 2

  # From homepage: "Princeton WordNet is no longer developed, though the
  # database and all tools are freely available on the download page."
  #
  # Also needs unmaintained TCL/Tk 8
  depends_on "tcl-tk@8"

  resource "dict" do
    url "https://wordnetcode.princeton.edu/wn3.1.dict.tar.gz"
    sha256 "3f7d8be8ef6ecc7167d39b10d66954ec734280b5bdcd57f7d9eafe429d11c22a"
  end

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    (prefix/"dict").install resource("dict")

    # Disable calling deprecated fields within the Tcl_Interp during compilation.
    # https://bugzilla.redhat.com/show_bug.cgi?id=902561
    ENV.append_to_cflags "-DUSE_INTERP_RESULT"
    tcltk_lib = formula_opt_lib("tcl-tk@8")
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--mandir=#{man}",
                          "--with-tcl=#{tcltk_lib}",
                          "--with-tk=#{tcltk_lib}"
    ENV.deparallelize
    system "make", "install"
  end

  test do
    output = pipe_output("#{bin}/wn homebrew -synsn")
    assert_match "alcoholic beverage", output
  end
end
