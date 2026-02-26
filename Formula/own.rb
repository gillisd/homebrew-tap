class Own < Formula
  desc "Take ownership of your git history — remove AI tool attribution"
  homepage "https://github.com/gillisd/own"
  license "MIT"
  head "https://github.com/gillisd/own.git", branch: "master"

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X own/internal/cli.Version=HEAD-#{Utils.git_short_head}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/own"
    man1.install Dir["man/man1/*.1"]
  end

  test do
    assert_match "HEAD-", shell_output("#{bin}/own --version")

    system "git", "init", "test-repo"
    Dir.chdir("test-repo") do
      system "git", "config", "user.email", "test@test.com"
      system "git", "config", "user.name", "Test"
      output = shell_output("#{bin}/own init")
      assert_match "Done", output
    end
  end
end
