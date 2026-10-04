class Hyperbole < Formula
  desc "Programmable information and hypertext system for GNU Emacs"
  homepage "https://www.gnu.org/software/hyperbole/"
  url "https://ftpmirror.gnu.org/gnu/hyperbole/hyperbole-9.0.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/hyperbole/hyperbole-9.0.1.tar.gz"
  sha256 "46f6920aacf0d18af57c985b872eb603275a87439ad5372a376f1db40e92708b"
  license "GPL-3.0-or-later"

  depends_on "emacs"

  def install
    # Install Emacs Lisp files to site-lisp
    site_lisp = share/"emacs/site-lisp/hyperbole"
    site_lisp.install Dir["*.el"]
    (site_lisp/"kotl").install Dir["kotl/*.el"]

    # Byte-compile for performance
    Dir[site_lisp/"*.el"].each do |el|
      system "emacs", "--batch", "--quick",
             "-L", site_lisp, "-L", site_lisp/"kotl",
             "-f", "batch-byte-compile", el
    end
    Dir[(site_lisp/"kotl")/"*.el"].each do |el|
      system "emacs", "--batch", "--quick",
             "-L", site_lisp, "-L", site_lisp/"kotl",
             "-f", "batch-byte-compile", el
    end

    # Install pre-built info documentation
    info.install "man/hyperbole.info"

    # Install data files needed at runtime
    site_lisp.install "man/hkey-help.txt" => "hkey-help.txt"
    (site_lisp/"HY-TALK").install Dir["HY-TALK/*"] if (buildpath/"HY-TALK").exist?
  end

  test do
    # Verify Emacs can load hyperbole
    output = shell_output("emacs --batch --quick -L #{share}/emacs/site-lisp/hyperbole " \
                          "-L #{share}/emacs/site-lisp/hyperbole/kotl " \
                          '-eval "(require \'hyperbole)" -eval "(princ hyperb:version)" 2>&1')
    assert_match version.to_s, output

    # Info page must be registered in the info directory
    dir_content = (HOMEBREW_PREFIX/"share/info/dir").read
    assert_match "Hyperbole", dir_content
  end
end
