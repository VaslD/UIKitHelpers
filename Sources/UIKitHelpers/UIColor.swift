import CoreGraphics
import UIKit

// MARK: Hex

public extension UIColor {
    /// 通过 RGB 色值创建 `UIColor`。代码中以十六进制字面量（例如 0x00BEBE）表示颜色时不需要引号。
    ///
    /// ```swift
    /// let color = UIColor(rgb: 0x00BEBE)
    /// ```
    ///
    /// > Note: 此方法将创建 sRGB 色域的 `UIColor`。
    ///
    /// - Parameter value: 24 位 RGB (8/8/8) 排列的 Int，支持十进制和十六进制等格式。
    convenience init(rgb value: UInt64) {
        let red = value >> 16 & 0xFF
        let green = value >> 8 & 0xFF
        let blue = value & 0xFF
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }

    /// 通过 RGBA 色值创建 `UIColor`。代码中以十六进制字面量（例如 0x00BEBEFF）表示颜色时不需要引号。
    ///
    /// 透明度 (Alpha) 取值范围与 R/G/B 元素相同，为 0 至 255，而非 0.0 (0%) 至 1.0 (100%)。
    ///
    /// ```swift
    /// let color = UIColor(rgba: 0x00BEBEFF)
    /// ```
    ///
    /// > Note: 此方法将创建 sRGB 色域的 `UIColor`。
    ///
    /// - Parameter value: 32 位 RGBA (8/8/8/8) 排列的 Int，支持十进制和十六进制等格式。
    convenience init(rgba value: UInt64) {
        let red = value >> 24 & 0xFF
        let green = value >> 16 & 0xFF
        let blue = value >> 8 & 0xFF
        let alpha = value & 0xFF
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255,
                  alpha: CGFloat(alpha) / 255)
    }

    /// 通过十六进制 RGB 或 RGBA 字符串创建 `UIColor`。
    ///
    /// 如果指定透明度 (Alpha)，取值范围必须与 R/G/B 元素相同，为 0 至 255，而非 0.0 (0%) 至 1.0 (100%)。
    ///
    ///
    /// ```swift
    /// let color = UIColor(hex: "0x00BEBE")
    /// ```
    ///
    /// > Note: 此方法将创建 sRGB 色域的 `UIColor`。
    ///
    /// 通常使用此构造方法读取 `String` 类型的变量构造 `UIColor`。如果需要在代码中通过十六进制色值创建
    /// `UIColor`，考虑使用 `init(rgb:)` 和 `init(rgba:)` 增加可读性并减少运行时消耗。
    ///
    /// > Important:
    /// 调用者需要保证传入参数是 6 (RGB) 或 8 (RGBA) 字符长度的有效十六进制表示。无效输入将构造
    /// `UIPlaceholderColor` 特殊类型，不能用于用户界面和绘图，否则将导致崩溃。
    ///
    /// - Parameter value: RGB 或 RGBA 排列的十进制字符串，允许使用 `#` 和 `0x` 前缀。
    convenience init(hex string: String) {
        let uppercased = string.trimmingCharacters(in: .alphanumerics.inverted).uppercased()
        var value: UInt64 = 0
        Scanner(string: uppercased).scanHexInt64(&value)
        switch (uppercased.count, uppercased.starts(with: "0X")) {
        case (6, false), (8, true):
            self.init(rgb: value)
        case (8, false), (10, true):
            self.init(rgba: value)
        default:
            self.init()
        }
    }
}

// MARK: Safety

public extension UIColor {
    /// 检查此实例是否是 `UIPlaceholderColor`。`UIPlaceholderColor` 不能用于用户界面和绘图，否则将导致崩溃。
    var isPlaceholder: Bool {
        self.isKind(of: type(of: UIColor()))
    }
}
