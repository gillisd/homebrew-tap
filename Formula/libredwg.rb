class Libredwg < Formula
  desc "GNU library to read and write DWG/DXF CAD files"
  homepage "https://www.gnu.org/software/libredwg/"
  url "https://ftpmirror.gnu.org/gnu/libredwg/libredwg-0.13.3.tar.xz"
  mirror "https://ftp.gnu.org/gnu/libredwg/libredwg-0.13.3.tar.xz"
  sha256 "83f1f6e78a744777a481ff4520e4cef3f8ac4b2c1c25671077ca12fe81e8816e"
  license "GPL-3.0-or-later"

  depends_on "pcre2"

  def install
    system "./configure", *std_configure_args, "--disable-dependency-tracking",
                          "--disable-bindings"
    # Large source files (decode.c ~7000 lines) with security hardening flags
    # exceed memory limits on constrained systems when compiled in parallel
    ENV.deparallelize
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dwgread --version")

    # Functional test: library can be linked against
    (testpath/"test.c").write <<~C
      #include <dwg.h>
      int main() {
        Dwg_Data dwg;
        dwg.header.version = R_2000;
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lredwg", "-o", "test"
    system "./test"

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "LibreDWG", dir_content
  end
end
