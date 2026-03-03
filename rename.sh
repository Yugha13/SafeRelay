#!/bin/bash
set -e

DIR="/Users/Developer/sample/bitchat"
cd "$DIR"

echo "Replacing contents..."
find . -type f \
    -not -path "*/.git/*" \
    -not -path "*/build_output*" \
    -not -path "*/.swiftpm/*" \
    -not -name "*.jpg" -not -name "*.png" -not -name "*.ttf" \
    -not -name "*.xcworkspace*" \
    -not -name "*.xcresult*" \
    -not -name "rename.sh" \
    -exec perl -pi -e 's/CrisisMesh/SafeRelay/g' {} +

find . -type f \
    -not -path "*/.git/*" \
    -not -path "*/build_output*" \
    -not -path "*/.swiftpm/*" \
    -not -name "*.jpg" -not -name "*.png" -not -name "*.ttf" \
    -not -name "*.xcworkspace*" \
    -not -name "*.xcresult*" \
    -not -name "rename.sh" \
    -exec perl -pi -e 's/bitchat/SafeRelay/g' {} +

find . -type f \
    -not -path "*/.git/*" \
    -not -path "*/build_output*" \
    -not -path "*/.swiftpm/*" \
    -not -name "*.jpg" -not -name "*.png" -not -name "*.ttf" \
    -not -name "*.xcworkspace*" \
    -not -name "*.xcresult*" \
    -not -name "rename.sh" \
    -exec perl -pi -e 's/Bitchat/SafeRelay/g' {} +

echo "Renaming directories and files..."
# Rename directories and files containing CrisisMesh
find . -depth -name "*CrisisMesh*" | while read file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    new_base=${base//CrisisMesh/SafeRelay}
    mv "$file" "$dir/$new_base"
done

# Rename directories and files containing bitchat
find . -depth -name "*bitchat*" | while read file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    new_base=${base//bitchat/SafeRelay}
    mv "$file" "$dir/$new_base"
done

# Rename directories and files containing Bitchat
find . -depth -name "*Bitchat*" | while read file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    new_base=${base//Bitchat/SafeRelay}
    mv "$file" "$dir/$new_base"
done

echo "Done."
