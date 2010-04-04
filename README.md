# Aurb

An AUR (Arch User Repository) utility.

Aurb can download from, search and look for updates on the AUR.

## Install

For Arch users, aurb is [available on the aur](http://aur.archlinux.org/packages.php?ID=24395).

If you rather install it as a gem, you could:

    # gem install aurb

## Usage

Download one or more packages:

    $ aurb download hon ioquake3

*By default, this will save the package to $HOME/abs. Override with `--path=/mypath`*

Search for one or more packages:

    $ aurb search firefox opera

List all available info for a given package:

    $ aurb info aurb

Look for upgrades to packages you have installed from the AUR:

    $ aurb upgrade

## Tests

Clone the project, and run:

    $ rake test

## Documentation

See [rdoc.info](http://rdoc.info/projects/gigamo/aurb).

## Copyright

Copyright (c) 2009-2010 Gigamo. See LICENSE for details.
