# frozen_string_literal: true

class Mblaze < Formula
  head do
    url 'https://github.com/leahneukirchen/mblaze.git', branch: 'master'
  end

  def install
    system('make', 'all')
    system('make', 'install', '--', "PREFIX=#{prefix}")
  end
end
