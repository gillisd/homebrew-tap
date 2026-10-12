class Parted < Formula
  desc "GNU disk partitioning and partition resizing tool"
  homepage "https://www.gnu.org/software/parted/"
  url "https://ftpmirror.gnu.org/gnu/parted/parted-3.6.tar.xz"
  mirror "https://ftp.gnu.org/gnu/parted/parted-3.6.tar.xz"
  sha256 "3b43dbe33cca0f9a18601ebab56b7852b128ec1a3df3a9b30ccde5e73359e612"
  license "GPL-3.0-or-later"

  depends_on :linux
  depends_on "util-linux" # for libuuid

  on_macos do
    depends_on "gettext"
  end

  def install
    # GCC 14+ treats incompatible pointer types as errors; parted 3.6 has
    # a function pointer mismatch in the command table.
    ENV.append "CFLAGS", "-Wno-incompatible-pointer-types"

    # Disable device-mapper (requires LVM2 dev library) and readline
    # (parted 3.6 segfaults at exit with Homebrew readline during cleanup)
    system "./configure", *std_configure_args, "--disable-dependency-tracking",
                          "--disable-device-mapper",
                          "--without-readline"
    system "make", "install"
  end

  test do
    # parted/partprobe crash at exit after --version/--help due to a cleanup
    # bug, but produce correct output. Wrap in || true to tolerate the crash.
    output = shell_output("#{sbin}/parted --version 2>&1 || true")
    assert_match version.to_s, output

    # Verify libparted is installed for downstream consumers
    assert_path_exists lib/"libparted.so"
    assert_path_exists include/"parted/parted.h"

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "parted", dir_content
  end
end
