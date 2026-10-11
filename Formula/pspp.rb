class Pspp < Formula
  desc "Free replacement for SPSS, a statistical analysis program"
  homepage "https://www.gnu.org/software/pspp/"
  url "https://ftpmirror.gnu.org/gnu/pspp/pspp-2.0.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/pspp/pspp-2.0.1.tar.gz"
  sha256 "8edbb0f09e8cf8010cad9e0559e0230d7fc5aae4721c756c350554df33024c00"
  license "GPL-3.0-or-later"

  depends_on "automake" => :build
  depends_on "python@3.13" => :build
  depends_on "texinfo" => :build

  depends_on "cairo"
  depends_on "gsl"
  depends_on "libxml2"
  depends_on "pango"
  depends_on "readline"
  depends_on "zlib"

  uses_from_macos "perl"

  on_macos do
    depends_on "gettext"
  end

  def install
    # Replace outdated config.guess (2018) that may not recognize modern archs
    %w[config.guess config.sub].each do |fn|
      target = buildpath/"build-aux"/fn
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, target
    end

    # CLI only — skip GTK GUI, PostgreSQL, and Perl module to minimize deps
    system "./configure", *std_configure_args, "--disable-dependency-tracking",
                          "--without-gui", "--without-libpq",
                          "--without-perl-module"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pspp --version 2>&1")

    # Functional test: run a basic PSPP syntax file
    (testpath/"test.sps").write <<~SPS
      DATA LIST LIST /x (F8.2).
      BEGIN DATA.
      1.0
      2.0
      3.0
      END DATA.
      DESCRIPTIVES x.
      FINISH.
    SPS
    system bin/"pspp", testpath/"test.sps", "-o", testpath/"output.txt"
    output = (testpath/"output.txt").read
    assert_match "Mean", output
  end
end
