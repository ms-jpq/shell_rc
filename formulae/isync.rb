# frozen_string_literal: true

class Isync < Formula
  head do
    url 'https://git.code.sf.net/p/isync/isync.git', branch: 'master'
    depends_on 'autoconf' => :build
    depends_on 'automake' => :build
  end

  depends_on 'berkeley-db@5'
  depends_on 'openssl@3'
  depends_on 'cyrus-sasl'

  uses_from_macos 'zlib'

  def install
    sasl = HOMEBREW_PREFIX / 'opt' / 'cyrus-sasl'
    system('./autogen.sh') if build.head?
    system('./configure', *std_configure_args, '--disable-silent-rules', "--with-sasl=#{sasl}")
    system('make', 'install')
  end
end
