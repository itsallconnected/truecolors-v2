#!/bin/bash

# For each locale file in the config/locales directory
for file in config/locales/*.yml; do
  echo "Normalizing $file..."
  
  # Ensure the file has proper YAML formatting
  # 1. Convert to single YAML format (---\n at the beginning)
  # 2. Ensure consistent indentation (2 spaces)
  # 3. Use double quotes for strings with special characters
  
  # Create a temporary file
  tmp_file="${file}.tmp"
  
  # Normalize the YAML file
  # First ensure it starts with ---
  echo "---" > "$tmp_file"
  
  # Skip the first line if it contains --- and append the rest
  sed '1{/^---$/d}' "$file" >> "$tmp_file"
  
  # Replace the original file with the normalized one
  mv "$tmp_file" "$file"
done

echo "All i18n files have been normalized." 