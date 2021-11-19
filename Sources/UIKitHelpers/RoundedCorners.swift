#if canImport(UIKit)

import UIKit

/// 自动为视图添加圆角，圆角弧径保持为短边长度的一半。
///
/// **使用方法**
///
/// 设计自定义视图时，声明遵循此协议并重载 `layoutSubviews()` 方法，然后在重载实现最后调用 `autoRoundCorners()`。
///
/// **代码示例**
///
/// ```swift
/// public class UIRoundButton: UIButton, RoundedCorners {
///     // 在此处添加自定义属性和方法
///
///     // MARK: RoundedCorners
///
///     override public func layoutSubviews() {
///         super.layoutSubviews()
///
///         // 在此处添加其他重载逻辑
///
///         self.autoRoundCorners()
///     }
/// }
/// ```
public protocol RoundedCorners: UIView {
    func autoRoundCorners()
}

public extension RoundedCorners {
    func autoRoundCorners() {
        let size = self.bounds.size
        if size.width > size.height {
            self.layer.cornerRadius = size.height / 2
        } else {
            self.layer.cornerRadius = size.width / 2
        }
        self.clipsToBounds = true
    }
}

#endif
