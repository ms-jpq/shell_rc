# frozen_string_literal: true

# https://github.com/moriyoshi/cyrus-sasl-xoauth2/issues/9#issuecomment-2161796043
class CyrusSaslXoauth2 < Formula
  head do
    url 'https://github.com/moriyoshi/cyrus-sasl-xoauth2.git', branch: 'master'
    depends_on 'libtool' => :build
    depends_on 'autoconf' => :build
    depends_on 'automake' => :build
  end

  depends_on 'cyrus-sasl'

  def install
    system('glibtoolize')
    File.open('./autogen.sh') do |f|
      f.drop(1).each { system(_1) }
    end

    system('./configure', "--with-cyrus-sasl=#{prefix}")
    system('make', 'install')
  end
end
