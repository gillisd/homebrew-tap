class Macchanger < Formula
  desc "Utility for viewing and manipulating MAC addresses"
  homepage "https://www.gnu.org/software/macchanger/"
  url "https://ftpmirror.gnu.org/gnu/macchanger/macchanger-1.6.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/macchanger/macchanger-1.6.0.tar.gz"
  sha256 "31534f138f1d21fa247be74ba6bef3fbfa47bbcd5033e99bd10c432fe58e51f7"
  license "GPL-2.0-or-later"

  depends_on :linux

  def install
    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    assert_match "GNU MAC changer", shell_output("#{bin}/macchanger --version")

    # Functional test: query the OUI vendor database (no root/device needed)
    list_output = shell_output("#{bin}/macchanger --list")
    assert_match "00:00:", list_output

    # Info page must be registered (upstream has @dircategory/@direntry)
    assert_match "macchanger", (HOMEBREW_PREFIX/"share/info/dir").read
  end
end
