# Mist.sh

Mist.sh is a shell implementation for syncing private directories via an untrusted remote SSH server. This script served as the portable prototype for a Rust implementation which can be found [here](https://github.com:jsbmg/mist).

## Usage 
The script will read the following variables from the environment:

`LOCAL_DIR` the directory in your home folder to sync

`GPG_RECIPIENT` - your gpg id 

`SSH_ADDRESS` - the remote SSH address 

Example:

`$ LOCAL_DIR=sync SSH_ADDRESS=user@host.com GPG_RECIPIENT=your@email.com mist.sh [OPTIONS]`

If no options are passed, the default action is to sync the local folder with the remote archive.

### Options
`--push`

Create an encrypted tar.gz of your directory and copy it to the remote host.

`--pull`

Copy the encrypted tar.gz diretory on the remote host to the local machine.

`--batch`

Run with no user interaction

## Requirements
* [Unison](https://www.cis.upenn.edu/~bcpierce/unison/)
* A GPG key capable of encryption
* A remote SSH server with filesystem access