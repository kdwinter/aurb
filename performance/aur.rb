require 'pp'
require 'benchmark'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'aurb'

Benchmark.bm 20 do |x|
  x.report 'aurb info' do
    Aurb.aur.info :aurb
  end

  x.report 'aurb upgrade' do
    Aurb.aur.upgrade *`pacman -Qm`.split(/\n/)
  end

  x.report 'aurb search' do
    Aurb.aur.search *:quake
  end

  x.report 'slurpy search' do
    `slurpy --search quake`
  end

  x.report 'bauerbill search' do
    `bauerbill -Ss quake --aur`
  end
end
