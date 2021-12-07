import UIKit

/// 轮播页面切换回调
public protocol LooperTransitionDelegate: AnyObject {
    /// 轮播页面即将被触摸操作切换。
    ///
    /// - Parameters:
    ///   - index: 当前位置
    ///   - nextIndex: 新位置
    func looperWillTransition(from index: Int, to nextIndex: Int)

    /// 轮播页面被触摸操作切换。
    ///
    /// 如果切换被取消（例如滑动操作距离过短或被打断），切换前、后位置可能相同。
    ///
    /// - Parameters:
    ///   - previousIndex: 切换前位置
    ///   - index: 切换后位置
    func looperDidTransition(from previousIndex: Int, to index: Int)

    /// 轮播页面即将被代码（包括定时器、回调、异步执行等）切换。
    ///
    /// - Parameter index: 新位置
    func prepareForAutoTransition(to index: Int?)

    /// 轮播页面被代码（包括定时器、回调、异步执行等）自动切换。
    ///
    /// - Parameters:
    ///   - index: 切换后位置
    ///   - withAnimation: 自动切换是否使用了动画
    func postProcessAutoTransition(to index: Int?, withAnimation: Bool)

    /// 轮播在指定位置的停留时间。
    ///
    /// 返回 0 可在当前位置停止轮播。
    ///
    /// - Parameter index: 页面位置
    /// - Returns: 等待时间，单位：秒
    func delayBeforeAutoTransition(at index: Int) -> TimeInterval
}

public extension LooperTransitionDelegate {
    func delayBeforeAutoTransition(at index: Int) -> TimeInterval {
        3
    }
}
