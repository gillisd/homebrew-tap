class Marst < Formula
  desc "GNU ALGOL 60 to C translator"
  homepage "https://www.gnu.org/software/marst/"
  url "https://ftpmirror.gnu.org/gnu/marst/marst-2.8.tar.gz"
  mirror "https://ftp.gnu.org/gnu/marst/marst-2.8.tar.gz"
  sha256 "d77f4703b0b44b50be57908f9d556ee6c3bedd97d638c42949d6aec84f8070ba"
  license "GPL-3.0-or-later"

  depends_on "automake" => :build
  depends_on "help2man" => :build
  depends_on "texinfo" => :build

  def install
    # Replace outdated config.guess/config.sub (2012) that don't recognize modern archs
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, fn
    end

    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"

    # Upstream doc/ isn't wired into the build system; build and install info manually
    system "makeinfo", "doc/marst.texi", "-o", "marst.info"
    info.install "marst.info"

    # Upstream doesn't ship man pages; generate from --help/--version
    system "help2man", "#{bin}/marst", "-o", "marst.1"
    man1.install "marst.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/marst --version")

    # Functional test: translate a simple ALGOL 60 program to C
    (testpath/"hello.alg").write "begin outstring(1, \"Hello\") end\n"
    output = shell_output("#{bin}/marst #{testpath}/hello.alg")
    assert_match "Hello", output

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "marst", dir_content
  end
end
