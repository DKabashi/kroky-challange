import SwiftUI

/// The closed 8-point spacing scale used throughout Kroky.
enum KrokySpacing {
    static let x1: CGFloat = 8
    static let x2: CGFloat = 16
    static let x3: CGFloat = 24
    static let x4: CGFloat = 32
    static let x5: CGFloat = 40
    static let x6: CGFloat = 48
    static let x8: CGFloat = 64
    static let x10: CGFloat = 80
    static let x12: CGFloat = 96
    static let x14: CGFloat = 112
}

/// Use the radius that describes the component rather than an arbitrary value.
enum KrokyRadius {
    static let iconWell: CGFloat = 14
    static let tile: CGFloat = 16
    static let card: CGFloat = 20
    static let mediaCard: CGFloat = 24
    static let scoreCard: CGFloat = 26
    static let sheet: CGFloat = 28
    static let contentSheet: CGFloat = 30
    static let screen: CGFloat = 40

    /// A value large enough to make any standard Kroky control fully pill-shaped.
    static let pill: CGFloat = 9_999
}

enum KrokySize {
    static let minimumHitTarget: CGFloat = 44
    static let smallButtonHeight: CGFloat = 40
    static let mediumButtonHeight: CGFloat = 48
    static let largeButtonHeight: CGFloat = 52
    static let listRowHeight: CGFloat = 52
    static let wheelRowHeight: CGFloat = 44
}
