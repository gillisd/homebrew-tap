class Acct < Formula
  desc "GNU process and login accounting utilities"
  homepage "https://www.gnu.org/software/acct/"
  url "https://ftpmirror.gnu.org/gnu/acct/acct-6.6.4.tar.bz2"
  mirror "https://ftp.gnu.org/gnu/acct/acct-6.6.4.tar.bz2"
  sha256 "13c2d18bdfa11ca0200d8c0f9df2e4572113d3fa5f44db219e5c71e04ae3fa03"
  license "GPL-3.0-or-later"

  depends_on "automake" => :build
  depends_on :linux

  on_macos do
    depends_on "gettext"
  end

  def install
    # Replace outdated config.guess/config.sub (2013) that may not recognize modern archs
    %w[config.guess config.sub].each do |fn|
      am_dir = Formula["automake"].opt_share/"automake-#{Formula["automake"].version.major_minor}"
      cp am_dir/fn, fn
    end

    # GCC 15 defaults to C23; force C11 for compatibility
    ENV.append "CFLAGS", "-std=gnu11"

    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ac --version")

    # Functional test: ac should run even with no accounting file
    shell_output("#{bin}/ac 2>&1")

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "acct", dir_content
  end
end
