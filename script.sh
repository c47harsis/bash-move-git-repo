#!/bin/bash

set -eE

trap "terminate 130" 2
trap "terminate 1" ERR

function help() {
  echo ""
  echo "Usage: $0 [--help] [--ssl-off] [--clean] <src_url> <dst_url>"
  # [--src-u <user>] [--src-p <pass>] [--dst-u <user>] [--dst-p <pass>]
  printf "%s\t\t%s\n" "--help" "Usage"
  printf "%s\t%s\n" "--ssl-off" "Turn off SSL"
  printf "%s\t\t%s\n" "--clean" "Remove created folder after exit"
  # printf "%s\t\t%s\n" "--src-u" "Source git username"
  # printf "%s\t\t%s\n" "--src-p" "Source git password"
  # printf "%s\t\t%s\n" "--dst-u" "Destination git username"
  # printf "%s\t\t%s\n" "--dst-p" "Destination git password"
  exit 1
}

# --- PARSE ARGUMENTS ---
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  --help | \?) help ;;
  --ssl-off)
    ssl_off=1
    shift
    ;;
  --clean)
    clean=1
    shift
    ;;
  --src-u)
    src_username="$2"
    shift
    shift 
    ;;
  --src-p)
    src_password="$2"
    shift 
    shift 
    ;;
  --dst-u)
    dst_username="$2"
    shift 
    shift 
    ;;
  --dst-p)
    dst_password="$2"
    shift 
    shift 
    ;;
  *) 
    POSITIONAL+=("$1") 
    shift              
    ;;
  esac
done
set -- "${POSITIONAL[@]}"

src_url="$1"
shift
dst_url="$1"
# --- / PARSE ARGUMENTS ---

printf "\n%s\n" "[ OPTIONS ]"
# --- PRINT OPTIONS ---
[[ -n $ssl_off ]]       && printf "%s\t\t%s\n"  "Disable SSL:" "true"
[[ -n $clean ]]         && printf "%s\t\t%s\n"  "Remove folder:" "true"
[[ -n $src_username ]]  && printf "%s\t\t%s\n"  "Source username:" "$src_username"
[[ -n $src_password ]]  && printf "%s\t\t%s\n"  "Source password:" "$src_password"
[[ -n $dst_username ]]  && printf "%s\t%s\n"    "Destination username:" "$dst_username"
[[ -n $dst_password ]]  && printf "%s\t%s\n"    "Destination password:" "$dst_password"
[[ -n $src_url ]]       && printf "%s\t\t%s\n"  "Source URL:" "$src_url"
[[ -n $dst_url ]]       && printf "%s\t%s\n"    "Destination URL:" "$dst_url"
printf "\n"
# --- / PRINT OPTIONS ---


# --- VARIABLES ---
ssl_original=$(git config --global --get http.sslverify)
repo_regex=".*/(.*).git$"
workdir=$(pwd)
# --- / VARIABLES ---


# -- FUNCTIONS ---
function get_folder_name() {
  [[ $dst_url =~ $repo_regex ]] && echo "${BASH_REMATCH[1]}"
}

function preconditions() {
  echo "Checking preconditions..."
  local error=0

  [[ -z "$src_url" ]] && 
  echo "fatal: source git repository must be specified." && error=1

  [[ ! $src_url =~ $repo_regex ]] && 
  echo "fatal: invalid source repository url." && error=1

  [[ -z "$dst_url" ]] && 
  echo "fatal: target git repository must be specified." && error=1

  [[ ! $dst_url =~ $repo_regex ]] && 
  echo "fatal: invalid target repository url." && error=1

  [[ "$src_url" == "$dst_url" ]] && 
  echo "fatal: source and destination are the same." && error=1

  repo_folder="$(get_folder_name)"

  [[ -d $repo_folder ]] && 
  echo "fatal: directory '$repo_folder' already exists." && error=1

  [[ $error == 1 ]] && return 1 
  echo "Everything is fine."
  return 0
}

function ssl_off() {
  [[ $ssl_original == true ]] && 
  echo "Turning off SSL globally..." && 
  git config --global http.sslVerify false ||
  return 0
}

function ssl_default() {
  [[ $ssl_original == true ]] && 
  echo "Turning on SSL globally..." && 
  git config --global http.sslVerify true ||
  return 0
}

function git_clone() {
  printf "\n%s\n" "[ CLONE ]"
  git clone --bare "$1" "$2"
}

function git_push() {
  printf "\n%s\n" "[ PUSH ]"
  git push --mirror origin
}

function git_change_origin() {
  printf "\n%s\n" "[ CHANGE ]"
  git remote rm origin
  echo "Old origin was removed..."
  git remote add origin "$1"
  echo "Added new origin: $1"
}

function rm_folder() {
  echo "Removing folder if it exists..."
  cd "$workdir"
  rm -rf "$1"
}

function finalize() {
  printf "\n%s\n" "[ FINALIZE ]"
  local happened=0
  [[ -n $ssl_off ]] && ssl_default && happened=1
  [[ -n $clean ]] || [[ -n $1 ]] && rm_folder "$repo_folder" && happened=1
  [[ $happened == 1 ]] && echo "Done."
  [[ $happened == 0 ]] && echo "Nothing to do."

  return 0
}

function terminate() {
  [[ -n $1 ]] && [[ $1 == 130 ]] && 
  printf "\n%s\n" "!!!Interrupted!!!" && local interrupted=1

  finalize $([[ -n $interrupted ]] && echo "$1")

  [[ -n $1 ]] && printf "\n%s%d\n" "Exited with exit code " $1 && exit "$1"

  exit 0
}
# -- / FUNCTIONS ---


# ---  MAIN LOGIC ---
printf "\n%s\n" "[ START ]"
preconditions 

[[ -n $ssl_off ]] && ssl_off 

git_clone "$src_url" "$repo_folder" 

cd "$repo_folder"
  
git_change_origin "$dst_url"

git_push

terminate 
# ---  / MAIN LOGIC ---