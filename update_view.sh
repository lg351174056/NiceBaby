#!/bin/bash
FILE="./火柴游戏/Games/ChinaGeographyView.swift"
# Find line number of MARK: - View
LINE=$(grep -n "// MARK: - View" "$FILE" | cut -d: -f1)
# Keep everything before that line
head -n $((LINE - 1)) "$FILE" > temp.swift
# Append the new View code
cat << 'INNER_EOF' >> temp.swift
// MARK: - View

struct ChinaGeographyView: View {
    @StateObject private var engine = ChinaMapEngine()
    @Environment(\.dismiss) private var dismiss
    
    // 交互状态 - 图鉴模式
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var finalOffset: CGSize = .zero
    @State private var selectedProvince: GeoFeature? = nil
    @State private var selectionId: UUID = UUID() // 用于取消之前的延迟任务
    
    // 拼图模式状态
    @State private var isPuzzleMode: Bool = false
    @State private var puzzleQueue: [GeoFeat#!/bin/bash
FILE="./火柴游戏/Games/ChinaGeograpetFILE="./?[# Find line number of MARK: - View
LINE=$(grep -n " nLINE=$(grep -n "// MARK: - View" : # Keep everything before that line
head -n $((LINE - 1vahead -n $((LINE - 1)) "$FILE" > t  # Append the new View code
cat << 'IN: cat << 'INNER_EOF'bl// MARK: - View