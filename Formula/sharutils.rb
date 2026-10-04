class Sharutils < Formula
  desc "Shell archive and uuencode/uudecode utilities"
  homepage "https://www.gnu.org/software/sharutils/"
  url "https://ftpmirror.gnu.org/gnu/sharutils/sharutils-4.15.2.tar.gz"
  mirror "https://ftp.gnu.org/gnu/sharutils/sharutils-4.15.2.tar.gz"
  sha256 "ee336e68549664e7a19b117adf02edfdeac6307f22e5ba78baca457116914637"
  license "GPL-3.0-or-later"

  depends_on "automake" => :build

  on_macos do
    depends_on "gettext"
  end

  def install
    # Replace outdated config.guess/config.sub (2013) that may not recognize modern archs
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, fn
    end

    # Bundled libopts redefines true/false as enum constants, which is illegal
    # in C23 (GCC 15+ default). Force C11 to allow the legacy code to compile.
    ENV.append "CFLAGS", "-std=gnu11"
    # Old code has duplicate global definitions that worked with -fcommon (GCC <10
    # default). Modern GCC defaults to -fno-common, causing linker errors.
    ENV.append "CFLAGS", "-fcommon"

    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/shar --version")

    # Functional test: create a shell archive and extract it
    (testpath/"hello.txt").write "Hello, World!\n"
    shar_output = shell_output("#{bin}/shar #{testpath}/hello.txt")
    assert_match "#!/bin/sh", shar_output
    assert_match "hello.txt", shar_output

    # Test uuencode/uudecode round-trip
    (testpath/"test.bin").write "binary data test\n"
    encoded = shell_output("#{bin}/uuencode #{testpath}/test.bin test.bin")
    assert_match "begin ", encoded

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "Shar utilities", dir_content
  end
end
