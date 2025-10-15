#!/bin/bash

cd /Users/delatour007/Documents/PROJECTS/EBLOOD/APPS/eblood_bank_makila_app

# Find all files with any animate_do animation components
ANIMATION_FILES=$(grep -l -E "FadeIn|ZoomIn|FlipIn|SlideIn|Bounce|Pulse|Shake" lib/**/*.dart)

# Add the import to each file if it doesn't already have it
for file in $ANIMATION_FILES; do
  if ! grep -q "import 'package:animate_do/animate_do.dart';" "$file"; then
    sed -i '' '1s/^/import '"'"'package:animate_do\/animate_do.dart'"'"';\n/' "$file"
    echo "Added import to $file"
  fi
done

echo "Done adding imports!"