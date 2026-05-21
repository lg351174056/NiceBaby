#!/bin/bash
FILE="./火柴游戏/Games/PlayView.swift"

# Fix switch exhaustive error in PlayView
sed -i '' 's/case .sanzijing:/case .sanzijing:\
            SanzijingView()\
        case .idiomDictionary:\
            DictionaryView()/g' "$FILE"

