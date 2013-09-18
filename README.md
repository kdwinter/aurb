# Aurb

An AUR (Arch User Repository) utility.

Aurb can download from, search, and look for updates on the AUR.

## Usage

Download one or more packages:

    $ ruby aurb.rb -D hon -D ioquake3

By default, this will save the package to $HOME/pkgbuilds. Edit SAVE_PATH in the script to change this.

Search for one or more packages:

    $ ruby aurb.rb -S firefox

List all available info for a given package:

    $ ruby aurb.rb -I aurbuild

Look for upgrades to packages you have installed from the AUR:

    $ ruby aurb.rb -U

## Copyright

Copyright (c) 2013 Gigamo. See LICENSE for details.
