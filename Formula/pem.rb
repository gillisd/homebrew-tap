class Pem < Formula
  desc "Personal income and expense tracking tool"
  homepage "https://www.gnu.org/software/pem/"
  url "https://ftpmirror.gnu.org/gnu/pem/pem-0.7.9.tar.gz"
  mirror "https://ftp.gnu.org/gnu/pem/pem-0.7.9.tar.gz"
  sha256 "e23ddcd94c4c65284f8b68c00ce8500dbfaba4a4dbb7a9c264732a1ae264380e"
  license "GPL-3.0-or-later"

  uses_from_macos "perl"

  def install
    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    assert_match "GNU Pem", shell_output("#{bin}/pem --version")

    # Functional test: add an expense record and verify file contents
    system bin/"pem", "-f", testpath/"expenses.txt", "Groceries", "25.50"
    assert_path_exists testpath/"expenses.txt"
    assert_match "Groceries", (testpath/"expenses.txt").read

    # Info page must be registered (upstream has @dircategory/@direntry)
    assert_match "pem", (HOMEBREW_PREFIX/"share/info/dir").read
  end
end
