class Mcron < Formula
  desc "Guile-based cron replacement for scheduling tasks"
  homepage "https://www.gnu.org/software/mcron/"
  url "https://ftpmirror.gnu.org/gnu/mcron/mcron-1.2.3.tar.gz"
  mirror "https://ftp.gnu.org/gnu/mcron/mcron-1.2.3.tar.gz"
  sha256 "1bc8c0d362d3b1a30fa0071d7fab696bbfc1da1ed536c42e0480bb9ffd22154e"
  license "GPL-3.0-or-later"

  depends_on "help2man" => :build

  depends_on "guile"

  def install
    # The crontab-access helper is built even with --disable-multi-user (as a
    # noinst target). Its Makefile.am hard-codes -static, which fails without
    # a static libc. Remove the flag since the binary is never installed.
    inreplace "Makefile.in", "bin_crontab_access_LDFLAGS = -static",
                             "bin_crontab_access_LDFLAGS ="

    # Single-user mode only — Homebrew installs should not manage system cron
    system "./configure", *std_configure_args, "--disable-dependency-tracking",
                          "--disable-multi-user"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mcron --version")

    # Functional test: parse a Guile-syntax cron job definition
    (testpath/"test.guile").write <<~SCHEME
      (job '(next-minute) "echo hello")
    SCHEME
    # mcron --schedule lists upcoming jobs; providing 1 means show 1 entry
    output = shell_output("#{bin}/mcron --schedule=1 #{testpath}/test.guile 2>&1")
    assert_match(/echo hello|#{Date.today.year}/, output)
  end
end
