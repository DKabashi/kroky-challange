import SwiftUI

/// Named type styles from the Kroky component library.
enum KrokyTextStyle: CaseIterable {
    case score
    case displayXL
    case screenTitle
    case displayL
    case title
    case blockTitle
    case headline
    case body
    case bodyStrong
    case subheadline
    case caption
    case overline

    fileprivate var size: CGFloat {
        switch self {
        case .score: 60
        case .displayXL: 34
        case .screenTitle: 28
        case .displayL: 23
        case .title: 20
        case .blockTitle: 18
        case .headline: 17
        case .body: 15
        case .bodyStrong: 14
        case .subheadline: 13
        case .caption: 11.5
        case .overline: 11
        }
    }

    fileprivate var weight: Font.Weight {
        switch self {
        case .body: .regular
        case .bodyStrong, .subheadline, .caption: .semibold
        default: .bold
        }
    }

    fileprivate var relativeTo: Font.TextStyle {
        switch self {
        case .score, .displayXL: .largeTitle
        case .screenTitle, .displayL: .title
        case .title, .blockTitle: .title3
        case .headline: .headline
        case .body, .bodyStrong: .body
        case .subheadline: .subheadline
        case .caption, .overline: .caption
        }
    }

    fileprivate var tracking: CGFloat {
        switch self {
        case .score: -0.04
        case .displayXL, .screenTitle: -0.03
        case .displayL, .title, .blockTitle: -0.02
        case .overline: 0.09
        default: 0
        }
    }

    fileprivate var isUppercase: Bool { self == .overline }
}

private struct KrokyTextStyleModifier: ViewModifier {
    let style: KrokyTextStyle
    @ScaledMetric private var scaledSize: CGFloat

    init(_ style: KrokyTextStyle) {
        self.style = style
        _scaledSize = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize, weight: style.weight, design: .default))
            .tracking(style.tracking * scaledSize)
            .textCase(style.isUppercase ? .uppercase : nil)
    }
}

extension View {
    /// Applies a Kroky type token while preserving Dynamic Type scaling.
    func krokyTextStyle(_ style: KrokyTextStyle) -> some View {
        modifier(KrokyTextStyleModifier(style))
    }
}
