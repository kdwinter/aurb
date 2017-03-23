# Aurb

A very simplistic AUR (Arch User Repository) utility.

Aurb can download, search, and look for updates on the AUR.

## Installation

    $ mv aurb.rb ~/.bin/aurb # or anywhere else in your $PATH
    $ chmod +x ~/.bin/aurb

## Usage

Download one or more packages:

    $ aurb -d hon -d ioquake3

By default, this will save the package to $HOME/AUR. Edit SAVE_PATH in the script, or set the `AURB_PATH` ENV variable to change this.

Search for packages:

    $ aurb -s firefox

List all available info for a given package:

    $ aurb -i aurbuild

Look for upgrades to local packages you have ever installed from the AUR:

    $ aurb -u

## License

Public domain.
