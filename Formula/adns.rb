class Adns < Formula
  desc "Async DNS resolver library and CLI tools"
  homepage "https://www.gnu.org/software/adns/"
  url "https://ftpmirror.gnu.org/gnu/adns/adns-1.6.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/adns/adns-1.6.0.tar.gz"
  sha256 "fb427265a981e033d1548f2b117cc021073dc8be2eaf2c45fd64ab7b00ed20de"
  license "GPL-3.0-or-later"

  depends_on "m4" => :build

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/adnshost --version")

    # Functional test: verify the library header is installed
    (testpath/"test.c").write <<~C
      #include <adns.h>
      int main() { return adns_s_ok; }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-ladns", "-o", "test"
    system "./test"
  end
end
