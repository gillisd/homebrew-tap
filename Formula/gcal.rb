class Gcal < Formula
  desc "GNU calendar program with astronomical and holiday calculations"
  homepage "https://www.gnu.org/software/gcal/"
  url "https://ftpmirror.gnu.org/gnu/gcal/gcal-4.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gcal/gcal-4.1.tar.gz"
  sha256 "363cdb016125bd64cfe5fcaa28b4b828fdfe88b1ee76d9f58ba9ea120587bb39"
  license "GPL-3.0-or-later"

  depends_on "help2man" => :build

  on_macos do
    depends_on "gettext"
  end

  def install
    # GCC 15 defaults to C23; force C11 for compatibility with older code
    ENV.append "CFLAGS", "-std=gnu11"

    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"

    # Upstream doesn't ship man pages; generate from --help/--version
    system "help2man", "#{bin}/gcal", "-o", "gcal.1"
    man1.install "gcal.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gcal --version")

    # Functional test: display current month calendar
    output = shell_output("#{bin}/gcal .")
    assert_match Time.now.year.to_s, output

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "Gcal", dir_content
  end
end
