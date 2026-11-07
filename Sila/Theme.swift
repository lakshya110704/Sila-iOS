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
