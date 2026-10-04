class Dap < Formula
  desc "GNU statistics and graphics package with SAS-compatible syntax"
  homepage "https://www.gnu.org/software/dap/"
  url "https://ftpmirror.gnu.org/gnu/dap/dap-3.10.tar.gz"
  mirror "https://ftp.gnu.org/gnu/dap/dap-3.10.tar.gz"
  sha256 "064e6cb72ff8dfc8cb6f53e9bab310e4ea8c6ebe89a94bae423720d9b7a38766"
  license "GPL-3.0-or-later"

  depends_on "automake" => :build
  depends_on "help2man" => :build

  def install
    # Replace outdated config.guess/config.sub (2012) that don't recognize modern archs
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, "build-aux/#{fn}"
    end

    # Source predates C99-strict compilers; GCC 15 defaults to C23 where
    # implicit function declarations create zero-arg prototypes. Force C11
    # so that implicit declarations remain compatible with actual signatures.
    ENV.append "CFLAGS", "-std=gnu11"
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"
    ENV.append "CFLAGS", "-Wno-int-conversion"
    ENV.append "CFLAGS", "-Wno-implicit-int"
    ENV.append "CFLAGS", "-Wno-incompatible-pointer-types"

    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"

    # Upstream doesn't ship man pages; generate from --help/--version
    system "help2man", "--no-discard-stderr", "#{bin}/dap", "-o", "dap.1"
    man1.install "dap.1"
  end

  test do
    # dap --version outputs to stderr and returns non-zero
    assert_match "Dap", shell_output("#{bin}/dap --version 2>&1", 1)

    # Functional test: verify dap can preprocess a simple C program
    (testpath/"test.c").write "#include \"dap.h\"\nint main(){return 0;}\n"
    system "#{bin}/dappp", testpath/"test.c"

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "Dap", dir_content
  end
end
