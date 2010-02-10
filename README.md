# Aurb

An AUR (Arch User Repository) utility.

Aurb can download from, search and look for updates on the AUR.

## Install

For Arch users, aurb is [available on the aur](http://aur.archlinux.org/packages.php?ID=24395).

If you rather install it as a gem, you could:

  # gem install aurb

## Usage

Download one or more packages:

  $ aurb download "hon ioquake3"

Search for one or more packages:

  $ aurb search "firefox opera"

Look for upgrades to packages you have installed from the AUR:

  $ aurb upgrade

## Tests

Clone the project, and run

  $ rake test:units

## Documentation

See http://rdoc.info/projects/gigamo/aurb

## Copyright

Copyright (c) 2009-2010 Gigamo. See LICENSE for details.
