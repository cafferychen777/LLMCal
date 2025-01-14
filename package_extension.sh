#!/bin/bash

# Navigate to the project directory
cd "$(dirname "$0")"

# Create a zip file of the .popclipext directory
zip -r LLMCal.popclipextz LLMCal.popclipext/

echo "Extension has been packaged as LLMCal.popclipextz"
