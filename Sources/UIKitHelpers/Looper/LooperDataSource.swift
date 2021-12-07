import UIKit

/// 轮播数据源
public protocol LooperDataSource: AnyObject {
    /// 轮播项目数量。
    var numberOfItems: Int { get }

    /// 轮播开始位置。
    var startIndex: Int { get }

    /// 获取指定位置的 `UIViewController`。允许但强烈不建议返回 `nil`。
    ///
    /// - Returns: 指定位置的 `UIViewController`
    func viewController(at index: Int) -> UIViewController?

    /// 获取指定 `UIViewController` 所在位置。允许但强烈不建议返回 `nil`。
    ///
    /// - Returns: `UIViewController` 所在位置
    func indexOf(_ viewController: UIViewController) -> Int?
}

public extension LooperDataSource {
    var startIndex: Int {
        0
    }
}
