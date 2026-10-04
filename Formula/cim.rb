class Cim < Formula
  desc "GNU Simula compiler — compiles Simula to C then to native code"
  homepage "https://www.gnu.org/software/cim/"
  url "https://ftpmirror.gnu.org/gnu/cim/cim-5.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/cim/cim-5.1.tar.gz"
  sha256 "b90717b66ec400503bdd69e537e8b7f3e8a9d106c3ba9a08a04ae57369a069a9"
  license "GPL-2.0-or-later"

  depends_on "automake" => :build

  def install
    # Replace outdated config.guess/config.sub (2013) that may not recognize modern archs
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, fn
    end

    # Source predates C99-strict compilers
    ENV.append "CFLAGS", "-std=gnu11"
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"
    ENV.append "CFLAGS", "-Wno-int-conversion"
    ENV.append "CFLAGS", "-Wno-implicit-int"
    ENV.append "CFLAGS", "-Wno-incompatible-pointer-types"
    ENV.append "CFLAGS", "-Wno-return-mismatch"

    # Pre-generated C files from Simula compilation have hardcoded relative
    # paths to cim.h that don't resolve in the build tree. Fix them.
    %w[lib/simset.c lib/simulation.c].each do |f|
      inreplace f, "../../lib/cim.h", "cim.h"
    end

    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    assert_match "cim", shell_output("#{bin}/cim --version 2>&1")

    # Functional test: compile a simple Simula program
    (testpath/"hello.sim").write <<~SIM
      Begin
        OutText("Hello from Simula");
        OutImage;
      End;
    SIM
    system "#{bin}/cim", testpath/"hello.sim"
    output = shell_output("#{testpath}/hello")
    assert_match "Hello from Simula", output

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "cim", dir_content
  end
end
