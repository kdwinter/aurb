require 'pp'
require 'benchmark'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'aurb'

Benchmark.bm 7 do |x|
  x.report 'search' do
    Aurb.aur.search *:quake
  end

  x.report 'upgrade' do
    Aurb.aur.upgrade *`pacman -Qm`.split(/\n/)
  end
end
