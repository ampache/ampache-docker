#!/usr/bin/env bash
# This script is used to create or update directories for specific versions and variants of Ampache.
# It generates Dockerfiles from templates and replaces variables in the Dockerfiles.
# It also copies configuration directories to destination directories,
# processes the files to remove or rename variants.

# Function to check if a command is available in the system
function check_command() {
    command -v $1 >/dev/null 2>&1 || { echo >&2 "The script requires '$1' but it's not installed. Aborting."; exit 1; }
}

# Check All Command used
commands=("git" "grep" "tr" "sort" "cp" "find" "basename" "dirname" "echo" "sed" "mkdir" "cat")
for cmd in "${commands[@]}"; do check_command $cmd; done


set -eo pipefail

##### Configure Base information
#

# Minimum Support version of Ampache
min_version='6.4'

# All Possible Variant
variants=(
    aio
    apache
)

# Get All version of Ampache
declare ampache_versions=( $(
    git ls-remote --tags https://github.com/ampache/ampache.git \
        | cut -d/ -f3 \
        | grep -viE '[a-z]' \
        | tr -d '^{}' \
        | sort -V 
))

declare -A php_version=(
    [default]='8.3'
    [6.0.0]='8.2'
    [6.0.1]='8.2'
    [6.0.2]='8.2'
    [6.0.3]='8.2'
    [6.1.0]='8.2'
)

declare -A debian_version=(
    [default]='bookworm'
)

declare -A crontab_int=(
    [default]='30 * * * *'
)

declare -A base=(
    [apache]='debian'
    [aio]='debian-aio'
)

#
# Function Utilities:
#

# Version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
    [[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

# is_in checks whether a string is in an array in bash
function is_in() {
    local variant_to_check=$1
    shift 1
    local ivariants=("$@")

    for known_variant in "${ivariants[@]}"; do
        if [[ "$variant_to_check" == "$known_variant" ]]; then
            return 0
        fi
    done
    return 1
}

#
# Reals Steps:
#


# This function copies a configuration directory to a destination directory,
# processes the files to remove or rename variants, and deletes files with unknown variants.
# 
# Arguments:
#   $1 - Source directory
#   $2 - Destination directory
#   $3 - Variant (e.g., "iao")
#   $4 - List of known variants
#
# File format example: ReadMe.tpl_iao.md
function copy_config(){
    
    # $1 - Source directory
    local source_dir=$1

    #   $2 - Destination directory
    local dest_dir=$2

    #   $3 - Variant (e.g., "iao")
    local variant=$3

    #   $4 - List of known variants
    shift 3
    local  known_variants=("$@")

    # Recursive Copy
    cp -rT "$source_dir" "$dest_dir"

    # Process files on destination
    find "$dest_dir" -type f | while read file; do
        base_name=$(basename "$file")
        dir_name=$(dirname "$file")
        
        # Extract variant prefix if exist
        current_variant=$(echo "$base_name" | grep -oP '\.tpl_\K[^.]+(?=\.)' || true )
        
        # Manage Variant 
        if [[ "$base_name" == *".tpl_$variant"* ]]; then
            # if the file variant is the current variant then remove from the name the variant prefix
            new_name=$(echo "$base_name" | sed "s/\.tpl_$variant//")
            mv "$file" "$dir_name/$new_name"
        elif is_in "$current_variant" "${variants[@]}"; then
            # if the file variant is not the current and is a known variant then remove it
            rm "$file"
        fi
    done
}


# This function creates or updates a directory for a specific variant and version,
# generates a Dockerfile from a template, and replaces variables in the Dockerfile.
#
# Arguments:
#   $1 - Version (e.g., "1.0.0")
#   $2 - Variant (e.g., "variant")
#
# File format example: Dockerfile-variant.template
function create_variant() {
    
    local version=$1
    local variant=$2
    shift 2
    local variants=("$@")

    local dir="$version/$variant"
    local debianVersion=${debian_version[$version]-${debian_version[default]}}
    local phpVersion=${php_version[$version]-${php_version[default]}}
    local crontabInt=${crontab_int[$version]-${crontab_int[default]}}
    local    url="https://github.com/ampache/ampache/releases/download/${version}/ampache-${version}_all_php${phpVersion}.zip"
    local ascUrl="https://github.com/ampache/ampache/releases/download/${version}/ampache-${version}_all_php${phpVersion}.zip.asc"
    
    
    echo "[ ] Create/Update $dir "
    
    mkdir -p "$dir"

    template="Dockerfile-${base[$variant]}.template"
    echo "# DO NOT EDIT: created by update_maintainer_version from $template " > "$dir/Dockerfile"
    cat "$template" >> "$dir/Dockerfile"

    # Replace the variables.
    sed -ri -e '
        s/%%DEBIAN_VERSION%%/'"$debianVersion"'/g;
        s/%%PHP_VERSION%%/'"$phpVersion"'/g;
        s/%%VARIANT%%/'"$variant"'/g;
        s/%%VERSION%%/'"$fullversion"'/g;
        s/%%VERSION%%/'"$fullversion"'/g;
        s/%%CRON_TIME%%/'"$crontabInt"'/g;
        s/%%DOWNLOAD_URL%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$url")"'/g;
        s/%%DOWNLOAD_URL_ASC%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$ascUrl")"'/g;
        
    ' "$dir/Dockerfile"

    copy_config  data "$dir/data" $variant "${variants[@]}"
}



#
# MAIN
#
for version in "${ampache_versions[@]}"; do
    if version_greater_or_equal "$version" "$min_version"; then
        for variant in "${variants[@]}"; do
            create_variant $version $variant "${variants[@]}"
        done
    fi
done


