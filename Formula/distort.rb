class Distort < Formula
  desc "Simple, symmetric, streaming encryption via xchacha20-poly1305"
  homepage "https://github.com/gillisd/distort"
  url "https://github.com/gillisd/distort.git",
      revision: "ddb0ad3bcf9c1c74fe062b58ad5700dcd7ab964f"
  version "0.1.0"
  license "MIT"
  head "https://github.com/gillisd/distort.git", branch: "master"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "help2man" => :build
  depends_on "pkgconf" => :build
  depends_on "libsodium"

  # ./bootstrap otherwise clones gnulib's full history on every build.
  resource "gnulib" do
    url "https://github.com/coreutils/gnulib.git",
        depth:    1,
        revision: "92d4a0deb5f8f332d3ea800f8fb41d0b56b4169a"
  end

  def install
    resource("gnulib").stage buildpath/"gnulib"

    system "./bootstrap", "--no-git", "--gnulib-srcdir=#{buildpath}/gnulib", "--no-bootstrap-sync"
    system "./configure", "--disable-silent-rules", "--disable-gcc-warnings", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    assert_match "distort #{version}", shell_output("#{bin}/distort --version")

    %w[key wrong_key].each { (testpath/it).binwrite SecureRandom.bytes(32) }
    plaintext = SecureRandom.bytes(200_000)

    ciphertext = pipe_output("#{bin}/distort encrypt -k key", plaintext).b
    assert_equal plaintext, pipe_output("#{bin}/distort decrypt -k key", ciphertext).b

    (testpath/"enc").binwrite ciphertext
    assert_match "invalid stream header", shell_output("#{bin}/distort decrypt -k wrong_key enc 2>&1", 1)
  end
end
