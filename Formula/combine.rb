class Combine < Formula
  desc "Flexible tool for merging files on a common key field"
  homepage "https://www.gnu.org/software/combine/"
  url "https://ftpmirror.gnu.org/gnu/combine/combine-0.4.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/combine/combine-0.4.0.tar.gz"
  sha256 "56e71cd9cc38404fc4e6dac02d5fb76e894d481f9be8719072b1f8b1d8afbe14"
  license "GPL-3.0-or-later"

  depends_on "automake" => :build
  depends_on "help2man" => :build

  on_macos do
    depends_on "gettext"
  end

  def install
    # The tarball's config.guess (2003) predates aarch64. We cannot use
    # autoreconf here because AM_GNU_GETTEXT in configure.ac would invoke
    # autopoint, which is not available. Copy fresh files from automake.
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, fn
    end

    # Pre-C99 K&R code; fatal on modern Clang/GCC without these flags.
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"
    ENV.append "CFLAGS", "-Wno-implicit-int"
    ENV.append "CFLAGS", "-Wno-int-conversion"

    # Without Guile, GUILE_SITE is empty and make install tries to write
    # to /combine_scm. Point it safely under the prefix.
    system "./configure", *std_configure_args,
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "GUILE_SITE=#{share}/guile/site"

    system "make", "install"

    # Upstream ships no man page; generate one from --help/--version.
    system "help2man", "--no-discard-stderr", bin/"combine", "-o", "combine.1"
    man1.install "combine.1"

    # Upstream texinfo is missing @dircategory/@direntry, so install-info
    # silently skips it during linking. Inject the dir entry metadata.
    dir_entry = <<~TEXT
      INFO-DIR-SECTION Text processing
      START-INFO-DIR-ENTRY
      * combine: (combine).            Flexible tool for merging files on a common key.
      END-INFO-DIR-ENTRY

    TEXT
    inreplace info/"combine.info", /\A/, dir_entry
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/combine --version")

    # Functional test: cut-emulation mode to extract field 1.
    (testpath/"data.txt").write "alpha:beta:gamma\ndelta:epsilon:zeta\n"
    output = shell_output("#{bin}/combine -e cut -d : -f 1 #{testpath}/data.txt")
    assert_match "alpha", output
    assert_match "delta", output
    refute_match "beta", output

    # Info page must be registered in the info directory.
    assert_match "* combine: (combine).", (HOMEBREW_PREFIX/"share/info/dir").read
  end
end
