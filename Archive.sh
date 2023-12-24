#!/bin/bash

# Function to compare Etag values
compare_etag() {
    local url=$1
    local etag=$2
    local stored_etag=$(grep -Po "\"$url\":\s*\"\K[^\"]+" Etag.json)

    if [[ "$etag" != "$stored_etag" ]]; then
        echo "Downloading $url..."
        new_etag=$(curl -sI "$url" | grep -i "etag" | awk -F'"' '{print $2}')

        # Update the Etag value in the JSON file
        if ! sed -i "s|\"$url\":\s*\"[^\"]*\"|\"$url\": \"$new_etag\"|" Etag.json; then
            echo "Failed to update Etag value in Etag.json"
            return 1
        fi
        printf "Etag updated in Etag.json to: %s\n" "$new_etag"

        # Extract the file path from the URL
        file_path=$(echo "$url" | sed 's|https://cfg.gog.com/||')

        # Create directories if they don't exist
        mkdir -p "$(dirname "$file_path")"

        # Download the file
        if ! curl -s -o "$file_path" "$url"; then
            printf "Failed to download %s\n" "$url"
            return 1
        fi

        # Calculate SHA-1 hash
        sha1=$(calculate_sha1 "$file_path")

        # Append to README.md
        printf "%s | %s\n\n" "$file_path" "$sha1" >> README.md
    else
        printf "No update available for %s\n" "$url"
    fi
}

# Function to update Etag value in the JSON file using a temporary file
update_etag() {
    local url=$1
    local new_etag=$2

    awk -v url="$url" -v new_etag="$new_etag" '{
        if ($1 == "\""url"\":") {
            print "\""url"\": \""new_etag"\""
        } else {
            print $0
        }
    }' Etag.json > Etag.json.tmp && mv Etag.json.tmp Etag.json
}

# Function to calculate SHA-1 hash of a file in the latest commit
calculate_sha1() {
    local file=$1
    local sha1_hash=$(git log -n 1 --pretty=format:"%H" -- "$file" | xargs -I{} git cat-file -p {}:"$file" | sha1sum | awk '{ print $1 }')
    echo "$sha1_hash"
}

# List of files/directories to exclude
excluded_files=("Etag.json" "README.md" ".git" ".github" ".github/workflows" ".github/workflows/etags.yml" "Archive.sh")

# Create an empty Etag.json file if it doesn't exist
if [[ ! -f "Etag.json" ]]; then
    echo "{}" > Etag.json
fi

# Clear the existing content of README.md and add header information to README.md
echo "GOG config archive" > README.md
echo "" >> README.md
echo "Archiving https://cfg.gog.com contents" >> README.md
echo "" >> README.md
echo "GOG Config Files and SHA1 Hashes:" >> README.md
echo "" >> README.md

# List of URLs to download
urls=(
    "https://cfg.gog.com/desktop-galaxy-client/config.json"
    "https://cfg.gog.com/desktop-galaxy-client/2/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/3/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/4/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/5/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/6/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/7/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/2/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/3/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/4/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/5/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/6/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/7/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/2/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/3/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/4/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/5/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/6/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/7/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/2/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/3/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/4/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/5/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/6/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/7/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/2/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/3/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/4/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/5/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/6/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/7/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/2/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/3/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/4/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/5/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/6/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/7/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/2/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/3/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/4/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/5/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/6/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/7/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/2/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/3/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/4/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/5/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/6/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-peer/7/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/2/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/3/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/4/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/5/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/6/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/7/master/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/2/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/3/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/4/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/5/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/6/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-updater/7/preview/files-windows.json"
    "https://cfg.gog.com/desktop-galaxy-client/2/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/3/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/4/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/5/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/6/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/7/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/2/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/3/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/4/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/5/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/6/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-client/7/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/2/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/3/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/4/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/5/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/6/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/7/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/2/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/3/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/4/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/5/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/6/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-commservice/7/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/2/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/3/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/4/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/5/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/6/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/7/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/2/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/3/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/4/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/5/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/6/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-overlay/7/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/2/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/3/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/4/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/5/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/6/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/7/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/2/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/3/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/4/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/5/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/6/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-peer/7/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/2/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/3/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/4/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/5/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/6/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/7/master/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/2/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/3/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/4/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/5/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/6/preview/files-osx.json"
    "https://cfg.gog.com/desktop-galaxy-updater/7/preview/files-osx.json"
)

# Iterate through the URLs
for url in "${urls[@]}"; do
    etag=$(curl -sI "$url" | grep -i "Etag" | awk -F'"' '{print $2}')
    compare_etag "$url" "$etag"
done

# Iterate through the files in the repository and append to README.md
for file in $(git ls-files); do
    # Check if the file is not in the excluded list
    if ! [[ " ${excluded_files[@]} " =~ " $file " ]]; then
        sha1=$(calculate_sha1 "$file")
        printf "%s | %s\n\n" "$file" "$sha1" >> README.md
    fi
done