class GnuPwMgr < Formula
  desc "Deterministic password manager using master seed and site ID"
  homepage "https://www.gnu.org/software/gnu-pw-mgr/"
  url "https://ftpmirror.gnu.org/gnu/gnu-pw-mgr/gnu-pw-mgr-2.7.4.tar.xz"
  mirror "https://ftp.gnu.org/gnu/gnu-pw-mgr/gnu-pw-mgr-2.7.4.tar.xz"
  sha256 "e8cb8b8d6c81ac2b01a226f2d2ce7698bf8be830cf65b5a3dd805facabde1c3a"
  license "GPL-3.0-or-later"

  def install
    # GCC 15 defaults to C23; force C11 for compatibility
    ENV.append "CFLAGS", "-std=gnu11"

    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gnu-pw-mgr --version")

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "gnu-pw-mgr", dir_content
  end
end
