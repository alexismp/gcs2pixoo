#!/usr/bin/env zsh
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -e

ACCOUNT="${1:-$(gcloud config get-value account 2>/dev/null)}"
SCRIPT_DIR="${0:a:h}"

echo "Waiting for Android device over ADB..."
adb wait-for-device

echo "Installing latest debug APK..."
adb install -r "${SCRIPT_DIR}/app/build/outputs/apk/debug/app-debug.apk"

ADC_FILE="${HOME}/.config/gcloud/legacy_credentials/${ACCOUNT}/adc.json"
if [[ -f "$ADC_FILE" ]]; then
    echo "Pushing ADC refresh credentials for ${ACCOUNT}..."
    adb shell "run-as io.github.glaforge.jixoo.controller mkdir -p files"
    cat "$ADC_FILE" | adb shell "run-as io.github.glaforge.jixoo.controller sh -c 'cat > files/adc.json'"
fi

echo "Fetching OAuth2 access token from gcloud for ${ACCOUNT}..."
TOKEN=$(gcloud auth print-access-token --account="$ACCOUNT" 2>/dev/null)

echo "Injecting token & launching Pixoo Slideshow Controller..."
adb shell am start -n io.github.glaforge.jixoo.controller/.MainActivity \
    --es gcs_account "$ACCOUNT" \
    --es gcs_token "$TOKEN" \
    --ez auto_sync true

echo "Done! Token injected and GCS cache sync triggered."
