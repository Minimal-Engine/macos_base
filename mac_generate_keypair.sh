#!/bin/bash
# This script is written to be compatible with both Bash and Zsh (default on macOS).

# --- Configuration ---
DOTFILES_REPO="git@github.com:Minimal-Engine/.dotfiles.git"
DEFAULT_DOTFILES_DIR="${HOME}/.dotfiles"

# --- Get User and Machine Names ---
# Get the current logged-in username
USERNAME=$(whoami)
# Get the machine hostname
HOSTNAME=$(hostname -s)

# Construct the key file name
KEY_NAME="${USERNAME}-${HOSTNAME}"
KEY_PATH="${HOME}/.ssh/${KEY_NAME}"

echo "--- GitHub SSH Key Generation and Git Configuration Script ---"
echo "This script will generate an ED25519 SSH key pair named '${KEY_NAME}' for GitHub."
echo "It will also configure your global Git user.name and user.email."
echo "The public key will be copied to your clipboard, and Safari will open to GitHub's SSH settings page."
echo ""

# --- Prompt for GitHub Email ---
read -r -p "Please enter the email address associated with your GitHub account (e.g., your_email@example.com): " GITHUB_EMAIL

# Validate if email is provided
if [[ -z "$GITHUB_EMAIL" ]]; then
    echo "Error: GitHub email cannot be empty. Exiting."
    exit 1
fi

echo ""

# --- Prompt for Git User Name ---
read -r -p "Please enter the name you want to use for Git commits (e.g., John Doe): " GIT_USER_NAME

# Validate if name is provided
if [[ -z "$GIT_USER_NAME" ]]; then
    echo "Error: Git user name cannot be empty. Exiting."
    exit 1
fi

echo ""

# --- Check if key already exists ---
if [ -f "${KEY_PATH}" ]; then
    read -r -p "A key named '${KEY_NAME}' already exists. Do you want to overwrite it? (y/N) " OVERWRITE_CHOICE
    # Use [[ ]] for pattern matching, which is compatible with both bash and zsh
    if [[ ! "$OVERWRITE_CHOICE" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled. Exiting."
        exit 0
    fi
fi

# --- Generate SSH Key Pair ---
echo "Generating SSH key pair..."
# -t ed25519: Specifies the type of key to create. GitHub recommends Ed25519 for security.
# -C "${GITHUB_EMAIL}": Provides a comment for the key, typically your email address.
# -f "${KEY_PATH}": Specifies the filename of the generated key.
# -N "": Sets an empty passphrase (no passphrase).
ssh-keygen -t ed25519 -C "${GITHUB_EMAIL}" -f "${KEY_PATH}" -N ""

if [ $? -eq 0 ]; then
    echo "SSH key pair generated successfully:"
    echo "  Private key: ${KEY_PATH}"
    echo "  Public key: ${KEY_PATH}.pub"
else
    echo "Error: Failed to generate SSH key pair. Exiting."
    exit 1
fi

echo ""

# --- Integrate Key with macOS SSH Agent ---
echo "Adding SSH key to macOS ssh-agent and keychain..."
# Start the ssh-agent in the background if it's not already running.
# 'eval "$(ssh-agent -s)"' sets the SSH_AUTH_SOCK and SSH_AGENT_PID variables in the current shell.
eval "$(ssh-agent -s)"

# Add the private key to the ssh-agent and store its passphrase in the keychain.
# The --apple-use-keychain flag ensures the passphrase (even if empty) is saved in macOS Keychain,
# so you don't need to enter it every time.
ssh-add --apple-use-keychain "${KEY_PATH}"

if [ $? -eq 0 ]; then
    echo "Key successfully added to ssh-agent and integrated with macOS Keychain."
else
    echo "Warning: Could not add key to ssh-agent or integrate with Keychain. You might need to add it manually later."
fi

echo ""

# --- Configure Git User Details ---
echo "Configuring global Git user details..."
# Set global user name
git config --global user.name "${GIT_USER_NAME}"
if [ $? -eq 0 ]; then
    echo "Git user.name set to: ${GIT_USER_NAME}"
else
    echo "Warning: Could not set Git user.name. Please check your Git installation."
fi

# Set global user email using the email entered earlier
git config --global user.email "${GITHUB_EMAIL}"
if [ $? -eq 0 ]; then
    echo "Git user.email set to: ${GITHUB_EMAIL}"
else
    echo "Warning: Could not set Git user.email. Please check your Git installation."
fi

echo ""

# --- Copy Public Key to Clipboard ---
echo "Copying public key to clipboard..."
pbcopy < "${KEY_PATH}.pub"

if [ $? -eq 0 ]; then
    echo "Public key (${KEY_PATH}.pub) copied to your clipboard!"
else
    echo "Error: Could not copy public key to clipboard. You will need to copy it manually."
    echo "You can view the public key content by running: cat ${KEY_PATH}.pub"
fi

echo ""

# --- Open GitHub SSH Settings Page ---
echo "Opening Safari to GitHub's SSH and GPG keys settings page..."
open -a Safari "https://github.com/settings/keys"

echo "Please paste the copied public key into the 'New SSH key' field on the GitHub page."
echo "You can give it a title like '${KEY_NAME}' to easily identify it."
echo ""

# --- Wait for User Confirmation ---
read -r -p "Press Enter after you have successfully uploaded your SSH key to GitHub..."

echo ""
echo "--- Testing Your SSH Setup ---"
echo "You can now test if your SSH key setup is working correctly."

while true; do
    echo ""
    echo "Choose a test option:"
    echo "1) Test if the new key is loaded into your SSH agent (ssh-add -l)"
    echo "2) Test your SSH connection to GitHub (ssh -T git@github.com)"
    echo "3) Finish Testing and Proceed"
    read -r -p "Enter your choice (1, 2, or 3): " TEST_CHOICE

    case "$TEST_CHOICE" in
        1)
            echo ""
            echo "--- Running: ssh-add -l ---"
            ssh-add -l
            if [ $? -eq 0 ]; then
                echo ""
                echo "If you see your key's fingerprint and path above, it means it's loaded into the SSH agent."
            else
                echo ""
                echo "Failed to list keys. Ensure ssh-agent is running."
            fi
            ;;
        2)
            echo ""
            echo "--- Running: ssh -T git@github.com ---"
            echo "Attempting to connect to GitHub. If this is your first time, you may be asked to confirm the host's authenticity."
            ssh -T git@github.com
            if [ $? -eq 0 ]; then
                echo ""
                echo "If the message above contains 'Hi YOUR_GITHUB_USERNAME! You\'ve successfully authenticated', your SSH connection to GitHub is working!"
            else
                echo ""
                echo "SSH connection to GitHub failed. Please review the error message above."
                echo "Common issues: Key not uploaded to GitHub, incorrect key, or firewall issues."
            fi
            ;;
        3)
            echo "Proceeding to next step..."
            break # Exit the while loop
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, or 3."
            ;;
    esac
done

echo ""
echo "--- Optional: Clone Dotfiles Repository ---"
read -r -p "Would you like to clone the dotfiles repository (${DOTFILES_REPO})? (y/N) " CLONE_DOTFILES_CHOICE

if [[ "$CLONE_DOTFILES_CHOICE" =~ ^[Yy]$ ]]; then
    read -r -p "Enter the directory to clone the dotfiles into (default: ${DEFAULT_DOTFILES_DIR}): " DOTFILES_CLONE_DIR
    # If user input is empty, use the default
    DOTFILES_CLONE_DIR="${DOTFILES_CLONE_DIR:-$DEFAULT_DOTFILES_DIR}"

    echo "Attempting to clone ${DOTFILES_REPO} into ${DOTFILES_CLONE_DIR}..."
    git clone "${DOTFILES_REPO}" "${DOTFILES_CLONE_DIR}"

    if [ $? -eq 0 ]; then
        echo "Dotfiles repository cloned successfully into: ${DOTFILES_CLONE_DIR}"
    else
        echo "Error: Failed to clone dotfiles repository. Please check the path and your SSH access."
    fi
else
    echo "Skipping dotfiles repository clone."
fi

echo ""
echo "Script finished. Your SSH key should now be set up for GitHub, your Git configuration updated, and dotfiles handled."
