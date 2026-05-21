#!/bin/bash
FILE="./火柴游戏/Games/DictionaryView.swift"

# 1. 确保顶部有 import Combine (如果第一行没有就添加)
if ! grep -q "import Combine" "$FILE"; then
    sed -i '' '1i\
import Combine\
' "$FILE"
fi

# 2. GameTopBar 参数名修正
sed -i '' 's/subtitle:/progressText:/g' "$FILE"

