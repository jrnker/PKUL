# Public Key User Login
..or just *PKUL*

The project will in a distributed way, manage your different SSH public keys, based on a keyfile in a repository.
The goal with the project is to with ease add the script itself, and then by only updating one file have admins added or removed automatically.

This is by far the easiest way to do key management of a bunch of machines, or at least the easiest I've found. It isn't a new idea, but when I needed this and wanted to find basically "managed public keys by git repository", then obviously the only things I found was simple articles talking about how to use public keys to login to GitHub. Lot's of noise there... ;)
So I wrote it myself.


## Notice / Warning 
As will all systems handling *who can logon where and how*, it's crucial that you do it properly. In this case, if a malicious person takes control over your repository, or if you fail to adhere to the instructions here - then the setup will give the wrong people access to your system.

Then again, if you give the wrong person access to any part of your infrastructure, then ...
But I assume you're a sensible person knowing what you're doing :D    

# What is this?
PKUL will
* Periodically fetch the default branch of your repo
* Look into `public_keys_file`
* Ignore empty lines or lines staring with #
* If a username starts with `!` kill that user and remove it from the system
* If a username is found in the file, ensure it's setup 
* Push the registered public key into `authorized_keys`
* Ensure the user is a local admin and can sudo without a password
* Wash, rinse, repeat, every 5 minutes

# Initial setup
## Setup a new repository
Use any git repo flavour you'd like, but you want a repo that can:
* Have basic users with read only access
* Have branch permissions

1. Create a new repo and copy these files over / Fork this one. Ensure the repo doesn't have public access
2. Setup a user in your organisation that can only read this repo (you use access keys or basic username pw like in this example)
3. Set the master branch to have the following restrictions
* Prevent deletion
* Prevent rewriting history
* Prevent changes without a pull request (this one is very important!!)
4.   Update the credentials in `REPO_URL` in `pkul.sh` to match your read only user

## Execute the script on your nodes
Modify the below text to match your credentials as well
```
REPO_URL="https://username:password@yourgithost.com/reponame/pkul.git"
REPO_LOCAL_PATH="/root/pkul"
sudo git clone $REPO_URL $REPO_LOCAL_PATH
sudo chmod +x $REPO_LOCAL_PATH/pkul.sh
sudo $REPO_LOCAL_PATH/pkul.sh
```
..then copy and paste this into a shell on your node. It will clone the repo, execute the script, and schedule it to run every 5 minutes.

# Adding and removing users

1. You can either work in a different branch of your repository, or preferably you fork your own repo into a personal repo.
2. Update `public_keys_file` as below
3. Commit and create a pull request to the main repository
4. Once the pull request is approved, it will be committed by the nodes using this setup

## The `public_keys_file` file
The file contains four columns
* username
* keytype
* public key
* email

I will not go through how to setup / generate / enable ssh public key login.  Just google it. It's been described a gazillion times already.

To add a user, simply add a new line with username, the info from your generated public key, and your email
To remove a user, simply add an exclamation mark `!` before the username. On next sync the user will be removed from the system, but the users files will remain. There are comments in the code that describes how to change the script to remove the directories.

# Todo

Nothing is perfect, but I already know one thing I'd like in this, but I don't have a need for it right now.
1. If a username is in all upper case, make it an admin, if it is in lower case, make it a user. Should be easy enough ;)

# Author and such

License: GNU GPLv3
Author: Christoffer Järnåker 2024
Disclaimer: Is this really needed? Don't blame me, I'm just trying to help, I don't take any responsibility whatsoever. Party on! 