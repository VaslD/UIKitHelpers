import AutoLayout
import Foundation
import UIKit

/// 基于 ``LooperDataSource`` 的轮播 `UIViewController`。
open class LooperViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    /// 轮播回调监听者
    public weak var delegate: LooperTransitionDelegate?

    // MARK: UIViewController

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        self.stopAutoTransition()
    }

    override open func loadView() {
        super.loadView()
        _ = self.pager
    }

    // MARK: UIPageViewController

    /// 轮播布局方向。
    ///
    /// 默认为横向。此属性只能在视图加载前（例如构造后）设置，当系统或调用者首次访问 ``LooperViewController``
    /// 的视图 （`view`) 时，视图将根据布局方向创建并冻结，以后将不再参考此属性。
    public private(set) var orientation: UIPageViewController.NavigationOrientation = .horizontal

    /// 自定义布局方向并创建 ``LooperViewController``。
    /// - Parameter orientation: 新的布局方向
    public init(orientation: UIPageViewController.NavigationOrientation) {
        self.orientation = orientation
        super.init(nibName: nil, bundle: nil)
    }

    lazy var pager: UIPageViewController = {
        $0.delegate = self
        $1.addChild($0)
        $1.view.addSubview($0.view)
        $0.view.autoLayout(in: $1.view, top: 0, bottom: 0, leading: 0, trailing: 0)
        return $0
    }(UIPageViewController(transitionStyle: .scroll, navigationOrientation: self.orientation, options: nil), self)

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let dataSource = self.dataSource else {
            breakpoint("Data source has been disposed.")
            return nil
        }

        guard let index = dataSource.indexOf(viewController) else {
            return nil
        }
        return self.viewController(before: index)
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let dataSource = self.dataSource else {
            breakpoint("Data source has been disposed.")
            return nil
        }

        guard let index = dataSource.indexOf(viewController) else {
            return nil
        }
        return self.viewController(after: index)
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   willTransitionTo pendingViewControllers: [UIViewController]) {
        self.pendingTransition = nil

        guard let viewController = pendingViewControllers.first,
              let currentIndex = self.currentIndex,
              let nextIndex = self.dataSource?.indexOf(viewController) else {
            return
        }
        self.delegate?.looperWillTransition(from: currentIndex, to: nextIndex)
    }

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                                   previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = previousViewControllers.first,
              let previousIndex = self.dataSource?.indexOf(viewController),
              let currentIndex = self.currentIndex else {
            return
        }
        self.delegate?.looperDidTransition(from: previousIndex, to: currentIndex)

        if let nextIndex = self.index(after: currentIndex) {
            self.scheduleTransition(to: nextIndex, after: self.delayBeforeAutoTransition(at: currentIndex))
        }
    }

    // MARK: Data Source

    /// 轮播数据源。仅直接使用 ``LooperViewController`` 时（而非派生类型时）支持修改。
    public weak var dataSource: LooperDataSource?

    /// 轮播当前位置。
    public var currentIndex: Int? {
        guard let dataSource = self.dataSource else {
            breakpoint("Data source has been disposed.")
            return nil
        }
        guard let viewController = self.pager.viewControllers?.first else {
            breakpoint("UIPageViewController has no current view controller.")
            return nil
        }

        return dataSource.indexOf(viewController)
    }

    /// 检查索引是否存在或可用。
    ///
    /// 默认实现检查索引是否在 0 至 ``LooperDataSource/numberOfItems`` 之间。
    ///
    /// - Parameter index: 待查询索引
    /// - Returns: 索引是否有效。
    open func indexIsValid(_ index: Int) -> Bool {
        guard let dataSource = self.dataSource else {
            breakpoint("Data source has been disposed.")
            return false
        }
        return (0..<dataSource.numberOfItems).contains(index)
    }

    /// 根据当前索引，获取需要显示的上一页索引。
    ///
    /// 默认实现非 0 位置索引 - 1，否则返回 ``LooperDataSource/numberOfItems`` - 1。
    ///
    /// - Parameter index: 待查询索引
    /// - Returns: 上一页索引，可能为 `nil`。
    open func index(before index: Int) -> Int? {
        guard let dataSource = self.dataSource else {
            breakpoint("Data source has been disposed.")
            return nil
        }

        let count = dataSource.numberOfItems
        guard count > 0 else {
            breakpoint("Data source is empty.")
            return nil
        }

        switch index {
        case ..<0, count...:
            breakpoint("Current index out of range.")
            return nil
        case 0:
            return count - 1
        default:
            return index - 1
        }
    }

    /// 根据当前索引，获取需要显示的下一页索引。
    ///
    /// 默认实现当索引为 ``LooperDataSource/numberOfItems`` - 1 时返回 0，否则将索引 + 1。
    ///
    /// - Parameter index: 待查询索引
    /// - Returns: 下一页索引，可能为 `nil`。
    open func index(after index: Int) -> Int? {
        guard let dataSource = self.dataSource else {
            breakpoint("Data source has been disposed.")
            return nil
        }

        let count = dataSource.numberOfItems
        guard count > 0 else {
            breakpoint("Data source is empty.")
            return nil
        }

        switch index {
        case ..<0, count...:
            breakpoint("Current index out of range.")
            return nil
        case count - 1:
            return 0
        default:
            return index + 1
        }
    }

    /// 根据当前索引，获取需要显示的上一个 `UIViewController`。
    ///
    /// - Parameter index: 待查询索引
    /// - Returns: 上一页的 `UIViewController`，可能为 `nil`。
    open func viewController(before index: Int) -> UIViewController? {
        return self.index(before: index).flatMap { self.dataSource?.viewController(at: $0) }
    }

    /// 根据当前索引，获取需要显示的下一个 `UIViewController`。
    ///
    /// - Parameter index: 待查询索引
    /// - Returns: 下一页的 `UIViewController`，可能为 `nil`。
    open func viewController(after index: Int) -> UIViewController? {
        return self.index(after: index).flatMap { self.dataSource?.viewController(at: $0) }
    }

    // MARK: Transition

    /// 轮播在指定位置的停留时间。``LooperTransitionDelegate`` 提供的值优先于此方法返回值。
    ///
    /// 返回 0 可在当前位置停止轮播。
    ///
    /// - Parameter index: 页面位置
    /// - Returns: 等待时间，单位：秒
    open func delayBeforeAutoTransition(at index: Int) -> TimeInterval {
        if let delegate = self.delegate {
            return delegate.delayBeforeAutoTransition(at: index)
        }
        return 3
    }

    /// 重置或刷新当前显示的 `UIViewController`。将重新触发定时器和数据源请求。
    ///
    /// - Parameters:
    ///   - viewController: 新的 `UIViewController`
    ///   - animated: 是否使用动画
    func setViewController(_ viewController: UIViewController?, animated: Bool) {
        self.delegate?.prepareForAutoTransition(to: viewController.flatMap { self.dataSource?.indexOf($0) })

        self.pager.setViewControllers(
            viewController.flatMap { [$0] }, direction: .forward, animated: animated
        ) { [weak self] completed in
            guard let self = self else { return }
            if let viewController = viewController, let index = self.dataSource?.indexOf(viewController) {
                self.delegate?.postProcessAutoTransition(to: index, withAnimation: completed)

                if let nextIndex = self.index(after: index) {
                    self.scheduleTransition(to: nextIndex, after: self.delayBeforeAutoTransition(at: index))
                }
            } else {
                self.delegate?.postProcessAutoTransition(to: nil, withAnimation: completed)
            }
        }

        if (self.dataSource?.numberOfItems ?? 0) > 1 {
            self.setScrollingEnabled(true)
        } else {
            self.setScrollingEnabled(false)
        }
    }

    /// 滚动到指定位置。
    ///
    /// 通过此方法滚动页面将触发 ``LooperTransitionDelegate/prepareForAutoTransition(to:)`` 和
    /// ``LooperTransitionDelegate/postProcessAutoTransition(to:withAnimation:)``。
    ///
    /// - Parameter index: 新位置
    /// - Returns: 是否成功滚动。
    @discardableResult
    public func scrollTo(index: Int) -> Bool {
        guard self.indexIsValid(index), let dataSource = self.dataSource,
              let viewController = self.dataSource?.viewController(at: index) else {
            return false
        }

        self.setViewController(viewController, animated: true)
        if dataSource.numberOfItems > 1 {
            self.setScrollingEnabled(true)
        } else {
            self.setScrollingEnabled(false)
        }
        return true
    }

    /// 设置滚动是否开启。
    ///
    /// 页面不支持「轮播」时（例如只有一页），请勿开启滚动，否则将导致页面错位。
    ///
    /// - Parameter enabled: 允许滚动
    public func setScrollingEnabled(_ enabled: Bool) {
        if enabled {
            self.pager.dataSource = self
        } else {
            self.pager.dataSource = nil
        }
    }

    // MARK: Timer

    /// 已提交的页面切换计划。
    ///
    /// 在 `DispatchQueue` 上提交新的切换计划后必须在此赋值，赋值将取消先前保存的计划。
    ///
    /// 如果要停止自动切换页面，赋值 `nil`。
    private var pendingTransition: DispatchWorkItem? {
        willSet {
            self.pendingTransition?.cancel()
        }
    }

    /// 计划并提交下次自动页面切换。
    ///
    /// - Parameters:
    ///   - index: 新位置
    ///   - delay: 切换前等待时间
    public func scheduleTransition(to index: Int, after delay: TimeInterval) {
        guard delay > 0 else {
            self.pendingTransition = nil
            return
        }

        let transition = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.scrollTo(index: index)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: transition)
        self.pendingTransition = transition
    }

    /// 取消所有自动切换。
    public func stopAutoTransition() {
        self.pendingTransition = nil
    }
}

// MARK: - Debugging

private func breakpoint(_ message: String) {
    print(message)
#if DEBUG
    raise(SIGINT)
#endif
}
