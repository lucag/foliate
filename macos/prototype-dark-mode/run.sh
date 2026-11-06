#!/bin/sh
# PROTOTYPE: serve the repo and open the dark-mode pages prototype in a WKWebView. Throwaway.
# usage: macos/prototype-dark-mode/run.sh ['?query'] [snapshot.png]
cd "$(dirname "$0")/../.."
PORT=8765
python3 -m http.server $PORT --bind 127.0.0.1 >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER' EXIT
sleep 0.5
swift macos/prototype-dark-mode/viewer.swift "http://127.0.0.1:$PORT/macos/prototype-dark-mode/index.html$1" $2 $3
