# Mist.sh

Mist.sh is a shell implementation for syncing private directories via an untrusted remote SSH server. This script served as the prototype a Rust implementation [found here](https://github.com:jsbmg/mist).

## Usage 
Modify the `LOCAL_DIR` variable to the name of the directory in your home folder to sync. The script will read the required `GPG_RECIPIENT` (your gpg id) and `SSH_ADDRESS` (the ssh address your data is on) variables from the environment:

`$ SSH_ADDRESS=user@host.com GPG_RECIPIENT=your@email.com mist.sh [OPTIONS]`

If no options are passed, the script will sync the remote archive with the local folder. 

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
