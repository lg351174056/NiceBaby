#!/bin/bash
FILE="./火柴游戏/Games/PlayView.swift"

sed -i '' 's/DictionaryView()/IdiomDictionaryView(onExit: { presentedGame = nil })/g' "$FILE"
sed -i '' 's/SanzijingView()/SanzijingView(onExit: { presentedGame = nil })/g' "$FILE"

