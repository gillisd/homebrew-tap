class Combine < Formula
  desc "Flexible tool for merging files on a common key"
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
    # Replace outdated config.guess/config.sub that don't recognize aarch64
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, fn
    end

    # Source predates C99-strict compilers; allow legacy implicit declarations
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"
    ENV.append "CFLAGS", "-Wno-int-conversion"
    ENV.append "CFLAGS", "-Wno-implicit-int"

    # Guile support is non-functional (requires obsolete gh_ API), but configure
    # leaves GUILE_SITE empty when Guile isn't found, causing make install to
    # write to /combine_scm. Point it safely under the prefix.
    system "./configure", *std_configure_args, "--disable-dependency-tracking",
                          "GUILE_SITE=#{share}"
    system "make", "install"

    # Upstream texinfo source is missing @dircategory/@direntry, so install-info
    # cannot register combine in the info directory. Inject the metadata so that
    # Homebrew's automatic install-info call during linking picks it up.
    info_file = info/"combine.info"
    dir_entry = <<~TEXT
      INFO-DIR-SECTION Text processing
      START-INFO-DIR-ENTRY
      * combine: (combine).            Flexible tool for merging files on a common key.
      END-INFO-DIR-ENTRY

    TEXT
    inreplace info_file, /\A/, dir_entry

    # Upstream doesn't ship a man page; generate one from --help/--version
    system "help2man", "#{bin}/combine", "-o", "combine.1"
    man1.install "combine.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/combine --version")

    # Functional test: match data file records against a reference file
    (testpath/"ref.txt").write "1\n2\n3\n"
    (testpath/"data.txt").write "1 apple\n2 banana\n4 date\n"
    output = shell_output("#{bin}/combine -o 1-2 -w -r #{testpath}/ref.txt -k 1 -m 1 #{testpath}/data.txt 2>/dev/null")
    assert_match "1", output
    assert_match "2", output

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "* combine: (combine).", dir_content
  end
end
