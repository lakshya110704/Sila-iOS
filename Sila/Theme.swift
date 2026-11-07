//
//  Theme.swift
//  Sila
//

import SwiftUI

extension Font {
    static func serif(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif, weight: weight)
    }
}

extension DynamicTypeSize {
    /// Side by side normally, one above the other at accessibility text sizes, where side by side text breaks mid-word.
    func stack(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil) -> AnyLayout {
        isAccessibilitySize ? AnyLayout(VStackLayout(alignment: alignment, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: .top, spacing: spacing))
    }
}

/// Each screen draws its own title in the layout, so nothing can sit on top of it.
struct ScreenTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.serif(.largeTitle, weight: .bold))
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.serif(.subheadline))
            .foregroundStyle(Color.accentColor)
            .textCase(nil)
    }
}
