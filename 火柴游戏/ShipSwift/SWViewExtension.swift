//
//  SWViewExtension.swift
//  ShipSwift
//
//  SwiftUI view extensions including SWButtonStyle (primary/secondary button styles) and
//  the swCardStyle card modifier. Button styles are full-width rounded rectangles with
//  automatic pressed/disabled state handling; card style features a gradient stroke.
//
//  Usage:
//    // Primary button (accent background + white text, for confirm/save main actions):
//    Button("Save") { save() }
//        .buttonStyle(.swPrimary)
//
//    // Secondary button (light background, for cancel/close secondary actions):
//    Button("Cancel") { dismiss() }
//        .buttonStyle(.swSecondary)
//
//    // Custom border and corner radius:
//    Button("Submit") { submit() }
//        .buttonStyle(.swPrimary(showBorder: true, cornerRadius: 12))
//
//    // Card style modifier (gradient stroke + translucent background):
//    VStack { content }
//        .swCardStyle()
//
//    // Custom card parameters:
//    VStack { content }
//        .swCardStyle(strokeColor: .cyan, cornerRadius: 24, padding: 24, strokeWidth: 1.0)
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - Button Style

struct SWButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
    }

    @Environment(\.isEnabled) private var isEnabled

    let variant: Variant
    var showBorder: Bool = false
    var cornerRadius: CGFloat = 16

    private var backgroundColor: Color {
        switch variant {
        case .primary: Color.accentColor
        case .secondary: Color.accentColor.opacity(0.1)
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: .white
        case .secondary: .primary.opacity(0.8)
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary: .primary
        case .secondary: .secondary.opacity(0.8)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .foregroundStyle(foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        showBorder ? borderColor : .clear,
                        lineWidth: 1.5
                    )
            )
            .overlay(
                // 底部投影，制造 3D 厚度感 (黏土风)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.15), lineWidth: 4)
                    .offset(y: 4)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0), value: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

extension ButtonStyle where Self == SWButtonStyle {
    /// Primary button style (confirm / save, etc.)
    static var swPrimary: SWButtonStyle { .init(variant: .primary) }
    /// Secondary button style (cancel / close, etc.)
    static var swSecondary: SWButtonStyle { .init(variant: .secondary) }

    static func swPrimary(showBorder: Bool = true, cornerRadius: CGFloat = 12) -> SWButtonStyle {
        .init(variant: .primary, showBorder: showBorder, cornerRadius: cornerRadius)
    }

    static func swSecondary(showBorder: Bool = true, cornerRadius: CGFloat = 12) -> SWButtonStyle {
        .init(variant: .secondary, showBorder: showBorder, cornerRadius: cornerRadius)
    }
}

// MARK: - Card Style
// Usage:
//   Text("Content").swCardStyle()
//   Text("Content").swCardStyle(strokeColor: .cyan, cornerRadius: 20)

extension View {
    /// Card style modifier
    /// - Parameters:
    ///   - strokeColor: Starting color for the border gradient
    ///   - background: Background color
    ///   - cornerRadius: Corner radius
    ///   - padding: Inner padding
    ///   - strokeWidth: Border width
    func swCardStyle(
        strokeColor: Color = .accentColor,
        background: Color = .white,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        strokeWidth: CGFloat = 2.0 // 加粗边框，符合黏土风
    ) -> some View {
        self
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor.opacity(0.3), lineWidth: strokeWidth)
            )
            .shadow(color: strokeColor.opacity(0.15), radius: 0, x: 0, y: 6) // 硬阴影（3D感）
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4) // 软阴影
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: 20) {
        Button("Primary Button") { }
            .buttonStyle(.swPrimary)

        Button("Secondary Button") { }
            .buttonStyle(.swSecondary)

        Button("Disabled") { }
            .buttonStyle(.swPrimary)
            .disabled(true)
    }
    .padding()
}

#Preview("Card Styles") {
    VStack(spacing: 20) {
        VStack {
            ForEach(0..<3, id: \.self) { _ in
                Text("Default Card")
            }
        }
        .frame(maxWidth: .infinity)
        .swCardStyle()

        VStack {
            ForEach(0..<3, id: \.self) { _ in
                Text("Custom Card")
            }
        }
        .frame(maxWidth: .infinity)
        .swCardStyle(strokeColor: .cyan, cornerRadius: 24, padding: 24)
    }
    .padding()
}
