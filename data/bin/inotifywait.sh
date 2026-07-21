#!/bin/bash

# inotifywait event types:
#    access        file or directory contents were read
#    modify        file or directory contents were written
#    attrib        file or directory attributes changed
#    close_write   file or directory closed, after being opened in writable mode
#    close_nowrite file or directory closed, after being opened in read-only mode
#    close         file or directory closed, regardless of read/write mode
#    open          file or directory opened
#    moved_to      file or directory moved to watched directory
#    moved_from    file or directory moved from watched directory
#    move          file or directory moved to or from watched directory
#    create        file or directory created within watched directory
#    delete        file or directory deleted within watched directory
#    delete_self   file or directory was deleted
#    unmount       file system containing file or directory unmounted

# cli command run:updateCatalogFile
#
# Perform catalog actions for a single file.
#
# Usage: run:updateCatalogFile <catalogName> <filePath> [OPTIONS...]
#
# Arguments:
#   <catalogName>    Catalog Name
#   <filePath>       File Path
#
# Options:
#   [-a|--add]        Adds new media files to the database
#   [-g|--art]        Gathers media Art
#   [-c|--cleanup]    Removes missing files from the database
#   [-e|--verify]     Reads your files and updates the database to match changes

# music file extensions to look for
declare -a arr=("mp3" "mpc" "m4p" "m4a" "aac" "ogg" "oga" "wav" "aif" "aiff" "rm" "wma" "asf" "flac" "opus" "spx" "ra" "ape" "shn" "wv")

# name of the Ampache catalog to update (must match an existing catalog name)
CATALOG_NAME="${CATALOG_NAME:-music}"

# monitor your media folder for updates
inotifywait -m -r --event close_write --event moved_to --event create --event delete --format '%w%f' /media |
    while read file; do
        for i in "${arr[@]}"
        do
            if [[ "$file" =~ .*$i$ ]]; then
                echo "$file"
                if [[ "$DISABLE_INOTIFYWAIT_CLEAN" == "1" ]]; then
                    php /var/www/bin/cli run:updateCatalogFile "$CATALOG_NAME" "$file" -a -e -g
                else
                    php /var/www/bin/cli run:updateCatalogFile "$CATALOG_NAME" "$file" -a -c -e -g
                fi
            fi
        done
    done

