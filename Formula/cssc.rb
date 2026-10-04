class Cssc < Formula
  desc "GNU replacement for SCCS (Source Code Control System)"
  homepage "https://www.gnu.org/software/cssc/"
  url "https://ftpmirror.gnu.org/gnu/cssc/CSSC-1.4.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/cssc/CSSC-1.4.1.tar.gz"
  sha256 "d1bed0c80246ee4cd49d0aa45307c075d0876fe531057bb1c8b28f5330d651ef"
  license "GPL-3.0-or-later"

  def install
    # GCC 15 defaults to C23 where 'bool' is a keyword and implicit function
    # declarations create zero-arg prototypes. Force C11 for compatibility.
    ENV.append "CFLAGS", "-std=gnu11"

    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sccs --version 2>&1")

    # Functional test: use sccs admin to create an SCCS file
    mkdir "SCCS"
    (testpath/"hello.c").write "#include <stdio.h>\nint main(){return 0;}\n"
    system "#{bin}/sccs", "create", "hello.c"
    system "#{bin}/sccs", "get", "hello.c"
    assert_predicate testpath/"hello.c", :exist?

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "cssc", dir_content
  end
end
