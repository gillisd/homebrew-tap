class Recutils < Formula
  desc "Tools to work with human-editable, plain text data files"
  homepage "https://www.gnu.org/software/recutils/"
  url "https://ftpmirror.gnu.org/gnu/recutils/recutils-1.9.tar.gz"
  sha256 "6301592b0020c14b456757ef5d434d49f6027b8e5f3a499d13362f205c486e0e"
  license "GPL-3.0-or-later"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "bison" => :build
  depends_on "help2man" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "gettext"
  depends_on "libsodium"
  depends_on "ossp-uuid"

  on_linux do
    depends_on "libgcrypt"
  end

  # Add libsodium encryption backend
  # TODO: Submit upstream and remove when merged
  patch do
    url "file://#{HOMEBREW_LIBRARY_PATH}/../Taps/gillisd/homebrew-tap/patches/patch.patch"
    sha256 "caf03894c0caca2dd1fb85cd88a45abc57dcf88c8ee9646c38ae7e1955f7699e"
  end

  def install
    ENV.prepend_path "PATH", formula_opt_bin("bison")

    system "autoreconf", "-fiv"

    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "./configure", "--with-libsodium",
                          "--datarootdir=#{elisp}",
                          "--disable-silent-rules",
                          *std_configure_args

    # Fix gnulib C23 [[__maybe_unused__]] incompatibility with Clang
    inreplace "src/config.h", "[[__maybe_unused__]]", "__attribute__((unused))"

    system "make", "install"
  end

  test do
    (testpath/"test.rec").write <<~EOS
      %rec: Book
      %mandatory: Title

      Title: GNU Emacs Manual
    EOS
    system bin/"recsel", "test.rec"
  end
end
