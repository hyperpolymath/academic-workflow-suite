class Aws < Formula
  desc "Academic Workflow Suite - Streamline and automate academic workflows"
  homepage "https://github.com/academicworkflow/suite"
  url "https://github.com/academicworkflow/suite/archive/v{{VERSION}}.tar.gz"
  sha256 "{{SHA256}}"
  license "MIT"

  depends_on "rust" => :build
  depends_on "openssl@3"

  def install
    system "cargo", "build", "--release"
    bin.install "target/release/aws"

    # Install shell completions
    # bash_completion.install "completions/aws.bash" => "aws"
    # zsh_completion.install "completions/_aws"
    # fish_completion.install "completions/aws.fish"

    # Install man page
    # man1.install "docs/aws.1"
  end

  test do
    system "#{bin}/aws", "--version"
  end

  def caveats
    <<~EOS
      Academic Workflow Suite has been installed!

      Get started by running:
        aws --help

      For documentation, visit:
        https://github.com/academicworkflow/suite
    EOS
  end
end
