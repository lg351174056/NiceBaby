//
//  SWAnimatedMeshGradient.swift
//  ShipSwift — copied for 火柴游戏 (MIT)
//

import SwiftUI

struct SWAnimatedMeshGradient: View {
    var paletteA: [Color] = [
        .indigo.opacity(0.9), .blue.opacity(0.85), .cyan.opacity(0.8),
        .blue.opacity(0.85), .indigo.opacity(0.9), .blue.opacity(0.85),
        .cyan.opacity(0.8), .blue.opacity(0.85), .indigo.opacity(0.9)
    ]

    var paletteB: [Color] = [
        .cyan.opacity(0.8), .indigo.opacity(0.9), .blue.opacity(0.85),
        .indigo.opacity(0.85), .blue.opacity(0.9), .cyan.opacity(0.85),
        .blue.opacity(0.85), .cyan.opacity(0.8), .indigo.opacity(0.9)
    ]

    var duration: Double = 5.0

    @State private var appear = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ],
            colors: appear ? paletteA : paletteB
        )
        .drawingGroup()
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                appear = true
            }
        }
    }
}
