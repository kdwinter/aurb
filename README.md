# Aurb

A very minimalistic AUR (Arch User Repository) utility.

Aurb can download, search, and look for updates on the AUR.
It can *not* automatically upgrade or install AUR dependencies for downloaded packages.

## Installation

    $ mv /path/to/aurb.rb ~/.bin/aurb # or anywhere else in your $PATH
    $ chmod +x ~/.bin/aurb

## Configuration

On first run, aurb will create a default configuration file at
`$HOME/.config/aurb/aurb.conf`.

## Usage

Download packages:

    $ aurb -d i3-gaps -d i-nex

By default, this will save the package to $HOME/AUR. Edit `save_path` in the config file to modify this.

Download and install packages:

    $ aurb --install i3-gaps

Search for packages:

    $ aurb -s firefox

Print all available info for given packages:

    $ aurb -i aurbuild

Look for upgrades to local packages you have ever installed from the AUR:

    $ aurb -u

Print the amount of AUR packages with updates available; useful for statusbar scripts:

    $ aurb -uc

## License

Public domain.
