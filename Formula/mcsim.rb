class Mcsim < Formula
  desc "GNU Monte Carlo simulation and MCMC statistical modeling suite"
  homepage "https://www.gnu.org/software/mcsim/"
  url "https://ftpmirror.gnu.org/gnu/mcsim/mcsim-6.2.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/mcsim/mcsim-6.2.0.tar.gz"
  sha256 "c6a3a685dfb9a6f0e99760f2628a91cf40798f6f05d4577e49fade9d80664f7e"
  license "GPL-3.0-or-later"

  depends_on "automake" => :build
  depends_on "help2man" => :build
  depends_on "gsl"

  def install
    # Replace outdated config.guess/config.sub (2018) that may not recognize modern archs
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, fn
    end

    # GCC 15 defaults to C23; force C11 for compatibility with 2017-era code
    ENV.append "CFLAGS", "-std=gnu11"
    # Source stores getc() return in char, which is unsigned on aarch64,
    # causing infinite loop when comparing to EOF (-1)
    ENV.append "CFLAGS", "-fsigned-char"

    system "./configure", *std_configure_args, "--disable-dependency-tracking",
                          "--without-mpi"
    system "make", "install"

    # Generate man page for the mod binary (upstream ships none)
    system "help2man", "#{bin}/mod", "-o", "mod.1"
    man1.install "mod.1"
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/mod -h")

    # Functional test: compile a simple model
    (testpath/"linear.model").write <<~MODEL
      Outputs = {y};
      A = 0;
      B = 1;
      SD_true = 0;
      CalcOutputs { y = A + B * t; }
      End.
    MODEL
    system "#{bin}/mod", testpath/"linear.model", testpath/"linear.c"
    assert_path_exists testpath/"linear.c"

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "Mcsim", dir_content
  end
end
