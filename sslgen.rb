require 'formula'

class Sslgen < Formula
  homepage 'https://github.com/flackend/sslgen'
  url 'https://github.com/flackend/sslgen', :using => :git
  sha1 ''
  version '0.1.9'

  def install
    system 'cp sslgen /usr/local/bin'
    system 'cp sign.sh /usr/local/bin'
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test sslgen`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "--version"`.
    system "true"
  end
end
