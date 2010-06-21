require 'rubygems' if RUBY_DESCRIPTION =~ /rubinius/i
require 'benchmark'
require File.expand_path('../../lib/aurb', __FILE__)

Benchmark.bm 20 do |x|
  x.report 'aurb search' do
    Aurb.aur.search :quake
  end

  x.report 'slurpy search' do
    `slurpy --search quake`
  end

  x.report 'bauerbill search' do
    `bauerbill -Ss quake --aur`
  end
end
