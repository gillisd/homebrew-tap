class Cursynth < Formula
  desc "Polyphonic synthesizer controlled via ncurses interface"
  homepage "https://www.gnu.org/software/cursynth/"
  url "https://ftpmirror.gnu.org/gnu/cursynth/cursynth-1.5.tar.gz"
  mirror "https://ftp.gnu.org/gnu/cursynth/cursynth-1.5.tar.gz"
  sha256 "1b9066526a368df8e337c507f8896e9aeac59da16933eccd473b07a2bc8617b6"
  license "GPL-3.0-or-later"

  depends_on "automake" => :build
  depends_on "help2man" => :build
  on_linux do
    depends_on "alsa-lib"
  end

  uses_from_macos "ncurses"

  on_macos do
    depends_on "gettext"
  end

  def install
    # config.guess (2013) predates aarch64. AM_GNU_GETTEXT means
    # autoreconf would invoke autopoint, so copy files from automake.
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, fn
      # Also update the bundled libraries' copies
      %w[mopo rtaudio/config rtmidi/config].each do |subdir|
        cp am_dir/fn, "#{subdir}/#{fn}" if File.exist?("#{subdir}/#{fn}")
      end
    end

    # Disable -Werror (all four configure.ac files set it via
    # AM_INIT_AUTOMAKE; modern compilers emit new warnings).
    ENV.append "CXXFLAGS", "-Wno-error"
    ENV.append "CFLAGS", "-Wno-error"

    # Create stub fdl.texi to prevent makeinfo rebuild failures
    # (upstream forgot to ship it but the .texi @include references it).
    unless File.exist?("doc/fdl.texi")
      File.write("doc/fdl.texi", "@c GNU Free Documentation License\n")
    end

    system "./configure", *std_configure_args,
                          "--disable-dependency-tracking",
                          "--disable-silent-rules"
    system "make", "install"

    # Upstream ships no man page; cursynth has --version but no --help.
    system "help2man", "--no-discard-stderr", "--no-info",
           bin/"cursynth", "-o", "cursynth.1"
    man1.install "cursynth.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cursynth --version")
  end
end
