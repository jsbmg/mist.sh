# /bin/sh -e
#
# Unison with remote encryption 
#
# This script performs local/remote directory synchronization via
# Unison, but with the remote end GPG encrypted.
# 
# The synced directory is archived, encrypted, and uploaded to the
# remote host.  Directory syncing is handled client side via downloading,
# decrypting, and extracting the tarball to a temporary directory,
# which is synced with the corresponding local folder using Unison.
# After Unison has finished, the synced folder is once again archived,
# encrypted, and re-uploaded to the remote host, along with an md5
# digest of its contents.
# 
# Options:
#     --push         Copy local sync folder to remote, overwriting
#                    it if it exists
#     --pull         Copy the remote sync folder to local, overwriting
#                    if it exists
#     --batch        Syncronize directories with no interaction
#
# Environment variables (required):
#     LOCAL_DIR      The name of the directory in the home folder to sync
#     SSH_ADDRESS    The remote ssh address where the remote folder is kept
#     GPG_RECIPIENT  The gpg id to encrypt the files with (likely your own)
#
# Examples:
# Upload the directory to be synced to the remote server:
#     $ LOCAL_DIR=sync SSH_ADDRESS=<user@host> GPG_RECIPIENT=<your-email> mist.sh --push
#
# Syncronize the local directory with the remote server:
#     $ LOCAL_DIR=sync SSH_ADDRESS=<user@host> GPG_RECIPIENT=<your-email> mist.sh 
#
# Download the synced directory (e.g., to a new machine):
#     $ LOCAL_DIR=sync SSH_ADDRESS=<user@host> GPG_RECIPIENT=<your-email> mist.sh --pull
# 
# Caveats:
# Though the directory syncronization itself is incremental, the encrypted 
# archive must be transfered over the network intact, therefore results 
# will be more favorable if the sync directory is small.

[[ -z $LOCAL_DIR ]] && echo "LOCAL_DIR not set."
[[ -z $SSH_ADDRESS ]] && echo "SSH_ADDRESS not set."
[[ -z $GPG_RECIPIENT ]] && echo "GPG_RECIPIENT not set."
[[ -z $GPG_RECIPIENT || -z $SSH_ADDRESS || -z $LOCAL_DIR ]] && exit

REMOTE_DIR=$LOCAL_DIR-remote    # The name of the remote sync folder 
REMOTE_ARCHIVE=$REMOTE_DIR.tar.gz.gpg

pull() {
    rm -rf $REMOTE_DIR                            # just in case
    ssh $SSH_ADDRESS "cat $REMOTE_ARCHIVE" | \
            gpg -d | \
            tar -xzf - $REMOTE_DIR
}

push() {
    tar -czf - -C $HOME $REMOTE_DIR | \
            gpg -e -r hello@jordandsweet.com | \
            ssh $SSH_ADDRESS "dd of=$REMOTE_ARCHIVE"
    echo $1 | ssh $SSH_ADDRESS "dd of=$REMOTE_ARCHIVE.md5" 
    rm -rf $REMOTE_DIR 
}

check_remote_exists() {
    ssh $SSH_ADDRESS "test -f $REMOTE_ARCHIVE"
}

check_local_exists() {
    test -d $LOCAL_DIR 
}

compute_md5() {
    echo $(find "$LOCAL_DIR" -type f -exec md5 -q {} + | md5) 
}

confirm_continue() {
    read confirm
    [[ "${confirm}" != @(Y|y|yes) ]] && exit
}

cd $HOME
if [[ $1 == "--push" ]]; then
    if check_remote_exists; then
        echo "Are you sure? This will overwrite \
              $REMOTE_ARCHIVE on $SSH_ADDRESS (y/n):"
        confirm_continue
        echo "Are you really sure?"
        confirm_continue
    fi
    ! check_local_exists && echo "Local folder does not exist." && exit
    md5_digest=$(compute_md5) 
    cp -r $LOCAL_DIR $REMOTE_DIR
    push "$md5_digest"

elif [[ $1 == "--pull" ]]; then
    if check_local_exists; then
        echo "Are you sure? This will overwrite $HOME/$LOCAL_DIR (y/n):"
        confirm_continue
        echo "Are you really sure?"
        confirm_continue
    fi
    if ! check_remote_exists; then
        echo "$REMOTE_ARCHIVE does not exist at $SSH_ADDRESS." 
        exit
    fi
    pull
    mv $REMOTE_DIR $LOCAL_DIR

else
    if ! check_local_exists; then 
        echo "$HOME/$LOCAL_DIR does not exist, maybe run with --pull." 
        exit
    fi
    md5_digest=$(compute_md5) 
    if [[ $(ssh $SSH_ADDRESS "cat $REMOTE_ARCHIVE.md5") == $(compute_md5) ]] 
    then
        if ssh $SSH_ADDRESS "test -f $REMOTE_ARCHIVE"; then
            echo "Up to date."
            exit
        else
            echo "$REMOTE_ARCHIVE does not exist on $SSH_ADDRESS,\
maybe run with --push." 
            exit
        fi
    fi
    if [[ $1 == "--batch" ]]; then
        batch="-batch" 
    fi
    pull
    unison $LOCAL_DIR $REMOTE_DIR $batch
    push "$md5_digest"
fi
