class Proxyknife < Formula
  desc "Customizable proxy validator and hunter"
  homepage "https://www.gnu.org/software/proxyknife/"
  url "https://ftpmirror.gnu.org/gnu/proxyknife/proxyknife-1.7.tar.gz"
  mirror "https://ftp.gnu.org/gnu/proxyknife/proxyknife-1.7.tar.gz"
  sha256 "622d7117f14175683551f9004b6f9713d3c0352470c0b2dce926c765c2e63e71"
  license "GPL-3.0-or-later"

  depends_on "automake" => :build

  on_macos do
    depends_on "gettext"
  end

  def install
    # config.guess (2006) predates aarch64. AM_GNU_GETTEXT means
    # autoreconf would invoke autopoint, so copy files from automake.
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, fn
    end

    # Pre-C99 code triggers warnings fatal on modern compilers.
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"
    ENV.append "CFLAGS", "-Wno-implicit-int"
    ENV.append "CFLAGS", "-Wno-int-conversion"
    # Header defines globals without extern; GCC 10+ defaults to -fno-common.
    ENV.append "CFLAGS", "-fcommon"

    system "./configure", *std_configure_args,
                          "--disable-dependency-tracking",
                          "--disable-silent-rules"

    # The upstream .texi has POD syntax errors that cause pod2man to fail
    # on modern Perl when make tries to regenerate the man page. Touch the
    # pre-built man page to prevent regeneration.
    touch "doc/proxyknife.1"

    # Build only the source (not docs), then install manually.
    system "make", "-C", "gl"
    system "make", "-C", "src"

    # Install manually to avoid the install-data-local target in
    # doc/Makefile which tries to build DVI/PDF/HTML and requires TeX.
    bin.install "src/proxyknife"
    man1.install "doc/proxyknife.1"
    info.install "doc/proxyknife.info"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/proxyknife --version")
    assert_match "Usage", shell_output("#{bin}/proxyknife --help")

    # Info page must be registered (upstream pre-built .info has dir entries)
    assert_match "proxyknife", (HOMEBREW_PREFIX/"share/info/dir").read
  end
end
