class Distort < Formula
  desc "Simple, symmetric, streaming encryption via xchacha20-poly1305"
  homepage "https://github.com/gillisd/distort"
  url "https://github.com/gillisd/distort.git",
      revision: "ddb0ad3bcf9c1c74fe062b58ad5700dcd7ab964f"
  version "0.1.0"
  license "MIT"
  head "https://github.com/gillisd/distort.git", branch: "master"

  bottle do
    root_url "https://ghcr.io/v2/gillisd/tap"
    rebuild 1
    sha256 cellar: :any, arm64_golden_gate: "23972de1c684a425581ec5914de96757fd35ed299cbbda8e2e537ffe19260479"
    sha256 cellar: :any, arm64_tahoe:       "610fe7bee26bce1450b0394ae68a5b8db22b831b808bdc7a1311a08c20df344d"
    sha256 cellar: :any, arm64_linux:       "c45d0e4d7869ade66084f2a76fe5f0583cd438ecd3017a1f66ad38679eb78a4f"
    sha256 cellar: :any, x86_64_linux:      "3635a1f2bb272f12c26a1fb5391a8b61d459af5a01d80589c6c751337e707205"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "help2man" => :build
  depends_on "pkgconf" => :build
  depends_on "libsodium"

  fails_with :gcc do
    version "13"
    cause "Requires `-std=gnu23`"
  end

  # ./bootstrap otherwise clones gnulib's full history on every build.
  resource "gnulib" do
    url "https://github.com/coreutils/gnulib.git",
        depth:    1,
        revision: "92d4a0deb5f8f332d3ea800f8fb41d0b56b4169a"
  end

  deny_network_access!

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
    assert_match "authentication failed", shell_output("#{bin}/distort decrypt -k wrong_key enc 2>&1", 1)
  end
end
