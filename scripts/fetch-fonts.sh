#!/usr/bin/env bash
# Re-resolve and download the self-hosted font subsets.
#
# Google's Fonts CSS API serves version-hashed woff2 URLs (v22, v24, ...), so this
# script must fetch and parse the CSS rather than hardcode download links.
# A browser User-Agent is required — Google serves TTF to unknown agents.
#
# Usage: bash scripts/fetch-fonts.sh
set -euo pipefail
cd "$(dirname "$0")/.."

UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'

fetch_family () {
  local slug="$1" query="$2"
  local css
  css="$(curl -sS -A "$UA" "https://fonts.googleapis.com/css2?family=${query}&display=swap")"
  python3 -c "
import re, subprocess, sys
slug = sys.argv[1]
css = sys.argv[2]
# One @font-face block per unicode subset. Pick the two we ship.
wanted = {'U+0000-00FF': 'latin', 'U+0100-02BA': 'latin-ext'}
found = {}
for block in re.findall(r'@font-face\s*\{(.*?)\}', css, re.S):
    rng = re.search(r'unicode-range:\s*([^;]+);', block)
    url = re.search(r'url\((https://[^)]+\.woff2)\)', block)
    if not rng or not url:
        continue
    first = rng.group(1).split(',')[0].strip()
    if first in wanted:
        found[wanted[first]] = url.group(1)
for subset, url in sorted(found.items()):
    out = f'assets/fonts/{slug}-{subset}.woff2'
    subprocess.run(['curl', '-sS', '-o', out, url], check=True)
    print(f'  {out}  <-  {url}')
missing = set(wanted.values()) - set(found)
if missing:
    sys.exit(f'ERROR: subsets not found for {slug}: {sorted(missing)}')
" "$slug" "$css"
}

echo "Space Grotesk:"
fetch_family space-grotesk 'Space+Grotesk:wght@300..700'
echo "JetBrains Mono:"
fetch_family jetbrains-mono 'JetBrains+Mono:wght@400..700'

echo "Licences:"
curl -sS -o assets/fonts/OFL-Space-Grotesk.txt \
  https://raw.githubusercontent.com/floriankarsten/space-grotesk/master/OFL.txt
curl -sS -o assets/fonts/OFL-JetBrains-Mono.txt \
  https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/OFL.txt
echo "  assets/fonts/OFL-Space-Grotesk.txt"
echo "  assets/fonts/OFL-JetBrains-Mono.txt"
