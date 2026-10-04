class Miscfiles < Formula
  desc "Collection of various useful data files"
  homepage "https://www.gnu.org/software/miscfiles/"
  url "https://ftpmirror.gnu.org/gnu/miscfiles/miscfiles-1.5.tar.gz"
  mirror "https://ftp.gnu.org/gnu/miscfiles/miscfiles-1.5.tar.gz"
  sha256 "6aaaa8898b0f6dac18bcaa5492874a6cd1243ffbe7a6dd347ca8f3ec3642a500"
  license "GPL-2.0-or-later"

  def install
    system "./configure", *std_configure_args, "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    # Verify key data files are installed and contain expected content.
    # Upstream installs directly into share/, not share/miscfiles/.
    assert_path_exists share/"web2"
    assert_path_exists share/"airport"
    assert_path_exists share/"currency"
    assert_path_exists share/"unicode"

    # Content verification: web2 (Webster's dictionary) should contain common words
    web2 = (share/"web2").read
    assert_match "apple", web2

    # Content verification: airport codes should contain well-known airports
    airports = (share/"airport").read
    assert_match "JFK", airports
  end
end
