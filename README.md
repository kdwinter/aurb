# Aurb

A very minimalistic AUR (Archlinux User Repository) utility.

Aurb can download packages, search packages, and look for updates on the AUR.
It can not *automatically* upgrade AUR packages.

## Installation

    $ mv /path/to/aurb.rb ~/.bin/aurb # or anywhere else in your $PATH
    $ chmod +x ~/.bin/aurb

## Configuration

On first run, aurb will create a default configuration file at
`$HOME/.config/aurb/aurb.conf`.

## Usage

Download packages:

    $ aurb download i3-gaps i-nex

By default, this will save the package to $HOME/AUR. Edit `save_path` in the config file to modify this.

Download and install packages:

    $ aurb install i3-gaps

Search for packages:

    $ aurb search firefox

Print all available info for given packages:

    $ aurb info aurbuild

Look for upgrades to local packages you have ever installed from the AUR:

    $ aurb updates

## License

See LICENSE.
