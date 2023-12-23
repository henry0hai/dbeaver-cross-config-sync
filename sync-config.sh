#!/usr/bin/env bash

# Source the .env file
source .env

dbeaver_installed=false
param=$1
password=$2
password_2=$3

# Check if 'compress' folder exists
if [[ ! -d "compress" ]]; then
  # If not, create it
  echo "Creating 'compress' folder..."
  mkdir compress
fi

# Check if 'data' folder exists
if [[ ! -d "data" ]]; then
  # If not, create it
  echo "Creating 'data' folder..."
  mkdir data
fi

# Define the path of installed DBeaver based on the OS
if [[ $(uname) == "Darwin" ]]; then
  main_path="$HOME/Library/DBeaverData"
  if [ ! -d "$main_path" ]; then
    echo "DBeaver is not installed. Installing now..."
    brew install --cask dbeaver-community
    dbeaver_installed=true
  fi
  compress_cmd() {
    tar -czvf compress/config.tar.gz data/ && openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -in compress/config.tar.gz -out compress/config.tar.gz.enc -pass pass:$password && openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -in compress/config.tar.gz.enc -out compress/config.tar.gz.enc2 -pass pass:$password_2
  }

  decompress_cmd() {
    openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in compress/config.tar.gz.enc2 -out compress/config.tar.gz.enc -pass pass:$password_2 && openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in compress/config.tar.gz.enc -out compress/config.tar.gz -pass pass:$password && tar -xvzf compress/config.tar.gz -C .
  }
elif [[ $(uname) == "Linux" ]]; then
  if [[ -z "$XDG_DATA_HOME" ]]; then
    main_path="$HOME/.local/share/DBeaverData"
  else
    main_path="$XDG_DATA_HOME/DBeaverData"
    dbeaver_installed=true
  fi
  if [ ! -d "$main_path" ]; then
    echo "DBeaver is not installed. Installing now..."
    sudo apt update && sudo snap install dbeaver-ce
  fi
  compress_cmd() {
    tar -czvf compress/config.tar.gz data/ && openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -in compress/config.tar.gz -out compress/config.tar.gz.enc -pass pass:$password && openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -in compress/config.tar.gz.enc -out compress/config.tar.gz.enc2 -pass pass:$password_2
  }

  decompress_cmd() {
    openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in compress/config.tar.gz.enc2 -out compress/config.tar.gz.enc -pass pass:$password_2 && openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in compress/config.tar.gz.enc -out compress/config.tar.gz -pass pass:$password && tar -xvzf compress/config.tar.gz -C .
  }
elif [[ $(uname) == "MINGW64_NT-10.0" || $(uname) == "MSYS_NT-10.0" ]]; then
  main_path="$APPDATA/DBeaverData"
  if [ ! -d "$main_path" ]; then
    echo "You should go to this link: https://dbeaver.io/download/ to download and install DBeaver, then run this script again."
  fi
  compress_cmd() {
    Compress-Archive -Path data -DestinationPath compress/config.zip && openssl enc -aes-256-cbc -salt -in compress/config.zip -out compress/config.zip.enc -pass pass:$password && openssl enc -aes-256-cbc -salt -in compress/config.zip.enc -out compress/config.zip.enc2 -pass pass:$password_2
  }

  decompress_cmd() {
    openssl enc -d -aes-256-cbc -in compress/config.zip.enc2 -out compress/config.zip.enc -pass pass:$password_2 && openssl enc -d -aes-256-cbc -in compress/config.zip.enc -out compress/config.zip -pass pass:$password && Expand-Archive -Path compress/config.zip -DestinationPath data -Force
  }
fi

workspace="workspace6"
workspace_path="$main_path/$workspace"

echo "Main Path: $main_path"
echo "Workspace Path: $workspace_path"

clear_data_folder() {
  # clear the data directory
  rm -rf data/*
  rm -rf data/.metadata
}

clear_workspace_folder() {
  # clear the workspace directory
  rm -rf $workspace_path/*
  rm -rf $workspace_path/.metadata
}

clear_all() {
  clear_data_folder
  rm -rf compress/*.tar.gz
  rm -rf compress/*.tar.gz.enc
}

remove_when_decrypt_failed() {
  rm -rf compress/*.tar.gz
  rm -rf compress/*.tar.gz.enc
}

github_pull() {
  echo "Pull from github."
  echo "Repository URL: $GITHUB_REPOSITORY_URL"

  # Get the current remote URL
  CURRENT_REMOTE_URL=$(git config --get remote.origin.url)

  # Check if the current remote URL is the same as GITHUB_REPOSITORY_URL
  if [[ "$CURRENT_REMOTE_URL" != "$GITHUB_REPOSITORY_URL" ]]; then
    # If not, remove the current origin
    git remote remove origin

    # And add a new origin with GITHUB_REPOSITORY_URL
    git remote add origin $GITHUB_REPOSITORY_URL
  fi

  git pull origin master
}

github_push() {
  echo "Add all changes."
  git add --all
  echo "Init the commit."
  git commit -am "Apply changes"
  echo "Push all to your repository."
  git push origin master
}

# Check if GITHUB_REPOSITORY_URL is set and not empty
if [[ -n $GITHUB_REPOSITORY_URL ]]; then

  if [ $? -ne 0 ]; then
    echo "Something went wrong, please manual check again."
    exit 1
  fi
  # Make sure pull first before doing anything
  github_pull

  sleep 3
else
  echo "GITHUB_REPOSITORY_URL is not set. Please check your .env file."
fi

sync_from_remote() {
  echo "Sync remote to local."

  # extract the file that download from remote
  decompress_cmd
  if [ $? -ne 0 ]; then
    echo "Decompression failed. Please check your password and try again."
    remove_when_decrypt_failed
    exit 1
  fi

  # clear the workspace directory
  clear_workspace_folder

  echo "Copy config data to workspace"

  # rename .metadata to metadata:
  mv data/.metadata data/metadata

  # copy files inside data into workspace_path, replace all exiting files
  cp -Rf data/* "$workspace_path"

  # rename metadata back to .metadata in both data and workspace_path
  mv data/metadata data/.metadata
  mv "$workspace_path"/metadata "$workspace_path"/.metadata

  # clear all
  clear_all
}

sync_from_local() {
  echo "Sync local to remote."
  # clear the data directory
  clear_data_folder

  mv "$workspace_path"/.metadata "$workspace_path"/metadata
  cp -Rf "$workspace_path"/* data

  mv "$workspace_path"/metadata "$workspace_path"/.metadata
  mv data/metadata data/.metadata

  # compress file prepare to upload
  compress_cmd

  # clear all
  clear_all

  echo "Sync local data to remote."
}

if [[ $param == "--local-data" ]]; then
  if [ -d "$main_path" ]; then
    sync_from_local
  else
    echo "Failed!"
  fi
elif [[ $param == "--remote-data" ]]; then
  if [ ! -d "$main_path" ]; then
    # check if dbeaver installed
    if [ "$dbeaver_installed" = true ]; then
      echo "First initialize DBeaver. Create workspace: $workspace"
      mkdir -p "$workspace_path"

      # check again if main_path exist
      if [ -d "$main_path" ]; then
        sync_from_remote
      else
        echo "Failed!"
      fi
    fi
  else
    sync_from_remote
  fi
fi

# make sure to delete the undecrypted compress file
# clear all
clear_all

# commit & push all the change
if [ $? -ne 0 ]; then
  echo "Something went wrong, please manual check again."
  exit 1
fi

# Ready to push
github_push

# Refer: https://dbeaver.com/docs/dbeaver/Workspace-Location/
