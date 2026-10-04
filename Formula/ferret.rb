class Ferret < Formula
  desc "Entity-relationship diagram tool for data modeling"
  homepage "https://www.gnu.org/software/ferret/"
  url "https://ftpmirror.gnu.org/gnu/ferret/ferret-0.7.tar.gz"
  mirror "https://ftp.gnu.org/gnu/ferret/ferret-0.7.tar.gz"
  sha256 "b7b00f3fd908ef8d3ba9f6db2edc1c15089e975dbbcc642218b9f3dcb7223ac9"
  license "GPL-3.0-or-later"

  depends_on "tcl-tk"

  def install
    # No autotools build system — pure Tcl/Tk scripts with bundled widgets.
    # Install all source and data files to libexec.
    libexec.install "src", "widgets", "gerwinml"

    # Create a wrapper that changes to libexec (the scripts use relative
    # paths like "source src/gerwin.tcl" and "[file join . widgets ...]").
    (bin/"ferret").write <<~SCRIPT
      #!/bin/bash
      cd "#{libexec}"
      exec "#{Formula["tcl-tk"].opt_bin}/wish" src/gerwin.tcl "$@"
    SCRIPT
  end

  test do
    assert_predicate bin/"ferret", :executable?
    assert_predicate libexec/"src/gerwin.tcl", :exist?
    assert_predicate libexec/"widgets/bwidget/pkgIndex.tcl", :exist?
  end
end
