#!/bin/bash

# Directory containing the files
directory="."

# Loop through files in the directory
for file in "$directory"/*; do
    if [ -f "$file" ]; then
        # Remove "_L001" and "_001" from filenames
        new_filename="${file//_L001}"
        new_filename="${new_filename//_001}"

        new_filename="${new_filename/_S[0-9]/}"

        # Change "I1" to "R1" and "I2" to "R2"
        new_filename="${new_filename//I1/R1}"
        new_filename="${new_filename//I2/R2}"

        # Check if the new filename is different
        if [ "$file" != "$new_filename" ]; then
            # Rename the file
            mv "$file" "$new_filename"
            echo "Renamed file: $file to $new_filename"
        fi
    fi
done