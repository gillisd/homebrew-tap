class Pies < Formula
  desc "Program invocation and execution supervisor"
  homepage "https://www.gnu.org/software/pies/"
  url "https://ftpmirror.gnu.org/gnu/pies/pies-1.9.tar.gz"
  mirror "https://ftp.gnu.org/gnu/pies/pies-1.9.tar.gz"
  sha256 "425ad6c961eb77cd777c99846f23fbcf603e7a9a92d9e002e8e4332d82de3dea"
  license "GPL-3.0-or-later"

  depends_on "help2man" => :build

  on_macos do
    depends_on "gettext"
  end

  def install
    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"

    # Upstream doesn't ship man pages; generate from --help/--version
    system "help2man", "#{bin}/piesctl", "-o", "piesctl.1"
    man1.install "piesctl.1"
    system "help2man", "#{sbin}/pies", "-o", "pies.8"
    man8.install "pies.8"
  end

  test do
    assert_match version.to_s, shell_output("#{sbin}/pies --version")
    assert_match version.to_s, shell_output("#{bin}/piesctl --version")

    # Functional test: verify pies can parse a minimal config file (--lint
    # exits 0 on success with no output)
    (testpath/"pies.conf").write <<~CONF
      component test {
        command "/bin/echo hello";
        mode respawn;
      }
    CONF
    system sbin/"pies", "--config-file=#{testpath}/pies.conf", "--lint"

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "pies", dir_content
  end
end
