#!/bin/bash

# Repository URL with credentials (use HTTPS URL)
REPO_URL="https://username:password@yourgithost.com/reponame/pkul.git"
REPO_LOCAL_PATH="/root/pkul"
CRON_JOB="*/5 * * * * /root/pkul/pkul.sh"

# Function to set up passwordless sudo for a user
setup_sudo() {
    local username=$1
    if ! grep -q "^$username ALL=(ALL) NOPASSWD: ALL$" /etc/sudoers; then
        echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi
}

# Function to create a user if they don't exist
create_user_if_not_exists() {
    local username=$1
    if ! id "$username" &>/dev/null; then
        useradd -m "$username"  # The -m option creates the home directory if it doesn't exist
        # Optionally, specify a default shell
        # useradd -m -s /bin/bash "$username"
    fi
}

# Function to add script to root's crontab if it's not already there
add_to_crontab() {
    local script_path=$1
    local job="$CRON_JOB"
    if crontab -l &> /dev/null; then
        # crontab exists, check if the job is already scheduled
        if ! crontab -l | grep -Fq "$script_path"; then
            (crontab -l 2>/dev/null; echo "$job") | crontab -
        fi
    else
        # crontab does not exist, create one with the job
        echo "$job" | crontab -
    fi
}

# Clone the repo if it does not exist
if [ ! -d "$REPO_LOCAL_PATH/.git" ]; then
    git clone $REPO_URL $REPO_LOCAL_PATH
fi

# Go to the repository directory and pull latest changes
cd $REPO_LOCAL_PATH
git reset --hard > /dev/null 2>&1
git pull > /dev/null 2>&1

# Ensure execute on this script
chmod +x $REPO_LOCAL_PATH/pkul.sh

# Process the keys file
while read line; do
    # Ignore empty lines and lines starting with '#'
    if [[ -z $line || $line == \#* ]]; then
        continue
    fi

    # Splitting the line into username, keytype, key, and email
    username=$(echo "$line" | cut -d ' ' -f1)

    # Check if the username starts with '!'
    if [[ $username == \!* ]]; then
        # Remove the '!' from the username
        username=${username:1}

        # Kill user processes to log them out
        pkill -u $username
        # Alternatively, use killall -u $username
        
        # Delete the user
        userdel $username
        # If you also want to remove the user's home directory and mail spool, use:
        # userdel -r $username

        continue
    fi

    keytype=$(echo "$line" | cut -d ' ' -f2)
    key=$(echo "$line" | cut -d ' ' -f3)
    email=$(echo "$line" | cut -d ' ' -f4-)

    # Combining keytype, key, and email to form the full key
    full_key="$keytype $key $email"

    create_user_if_not_exists $username

    mkdir -p /home/$username/.ssh
    echo $full_key > /home/$username/.ssh/authorized_keys
    chown -R $username:$username /home/$username/.ssh
    chmod 700 /home/$username/.ssh
    chmod 600 /home/$username/.ssh/authorized_keys

    # Set up passwordless sudo
    setup_sudo $username
done < public_keys_file

# At the end of the script, call add_to_crontab
add_to_crontab "$(realpath $0)"
