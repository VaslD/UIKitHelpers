import AutoLayout
import Foundation
import UIKit

// MARK: - LooperViewControllerDataSource

public protocol LooperViewControllerDataSource: AnyObject {
    func numberOfItems(inLooper viewController: LooperViewController) -> Int
    func startIndex(ofLooper viewController: LooperViewController) -> Int
    func looper(_ viewController: LooperViewController, itemAt index: Int) -> LooperViewController.Item
    func looper(_ viewController: LooperViewController, indexOf item: LooperViewController.Item) -> Int
}

public extension LooperViewControllerDataSource {
    func startIndex(ofLooper viewController: LooperViewController) -> Int {
        0
    }
}

// MARK: - LooperViewControllerDelegate

public protocol LooperViewControllerDelegate: AnyObject {
    func looper(_ viewController: LooperViewController, willBeginTransitionFrom index: Int, to nextIndex: Int)
    func looper(_ viewController: LooperViewController, didEndTransitionFrom previousIndex: Int, to index: Int)
    func looper(_ viewController: LooperViewController, autoTransitionedTo index: Int)
}

public extension LooperViewControllerDelegate {
    func looper(_ viewController: LooperViewController, autoTransitionedTo index: Int) {}
}

// MARK: - LooperViewController

/// 轮播视图控制器，支持横、纵布局。
///
/// 支持 3 种（互斥）视图提供方式：
/// - 使用 ``setViewControllers(_:startIndex:)`` 提供需要轮播的子视图控制器，控制器将由 ``LooperViewController`` 管理。
/// - 使用 ``setViews(_:startIndex:respectsSafeAreaInsets:)`` 提供需要轮播的视图，视图将由 ``LooperViewController`` 管理。
/// - 使用 ``setDataSource(_:)`` 设置 ``LooperViewControllerDataSource`` 作为数据源，轮播过程中所有页面和索引处理都将请求数据源。
///
/// 同时支持 2 个事件回调：
/// - 通过 ``LooperViewControllerDelegate/looper(_:willBeginTransitionFrom:to:)`` 回调页面切换前的当前和下一个页面索引。
/// - 通过 ``LooperViewControllerDelegate/looper(_:didEndTransitionFrom:to:)`` 回调页面切换后的上一个和当前页面索引。
public class LooperViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    // MARK: Lifecycle

    deinit {
        self.pendingTransition = nil
    }

    override public func loadView() {
        super.loadView()
        _ = self.pager
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if let dataSource = self.dataSource {
            let controller = dataSource.looper(self, itemAt: dataSource.startIndex(ofLooper: self)).asViewController()
            self.pager.setViewControllers([controller], direction: .forward, animated: false)
        } else {
            let controllers: [UIViewController]? = {
                if self.subviewControllers.indices.contains(self.startIndex) {
                    return [self.subviewControllers[self.startIndex]]
                } else if let first = self.subviewControllers.first {
                    return [first]
                } else {
                    return nil
                }
            }()
            self.pager.setViewControllers(controllers, direction: .forward, animated: false)
        }
    }

    override public func removeFromParent() {
        self.cancelAutoScroll()
        super.removeFromParent()
    }

    // MARK: Looper

    /// 轮播布局方向。
    ///
    /// 默认为横向。此属性只能在视图加载前（例如构造 ``LooperViewController`` 后）设置，当系统或调用者首次访问此 View Controller
    /// 的视图 （`view`) 时，视图将根据布局方向创建并冻结布局方向，以后将不再参考此属性。
    public var orientation: UIPageViewController.NavigationOrientation = .horizontal

    private lazy var pager: UIPageViewController = {
        $0.dataSource = self
        $0.delegate = self
        $1.addChild($0)
        $1.view.addSubview($0.view)
        $0.view.autoLayout(in: $1.view, top: 0, bottom: 0, leading: 0, trailing: 0)
        return $0
    }(UIPageViewController(transitionStyle: .scroll, navigationOrientation: self.orientation, options: nil), self)

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let dataSource = self.dataSource {
            let count = dataSource.numberOfItems(inLooper: self)
            let index = self.currentIndex
            let item: Item? = {
                switch index {
                case -1:
                    return nil
                case 0:
                    return dataSource.looper(self, itemAt: count - 1)
                default:
                    return dataSource.looper(self, itemAt: index - 1)
                }
            }()

            return item?.asViewController()
        }

        guard let index = self.subviewControllers.firstIndex(of: viewController) else {
            return nil
        }

        switch index {
        case self.subviewControllers.startIndex:
            return self.subviewControllers.last
        default:
            let previousIndex = index - 1
            if self.subviewControllers.indices.contains(previousIndex) {
                return self.subviewControllers[previousIndex]
            }

            breakpoint("Current index > 0 but (index - 1) is out of range. Why?")
            return nil
        }
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if self.dataSource != nil {
            let index = self.currentIndex
            return self.viewController(after: index)
        }

        guard let index = self.subviewControllers.firstIndex(of: viewController) else {
            return nil
        }
        return self.viewController(after: index)
    }

    // MARK: Indexing

    private var shouldDetectRecursion = false

    public var currentIndex: Int {
        guard let current = self.pager.viewControllers?.first else {
            breakpoint("UIPageViewController has no current view controller. Is this an error?")
            return -1
        }

        if let dataSource = self.dataSource {
            guard !self.shouldDetectRecursion else {
                breakpoint("Recursion detected when using data source!")
                return 0
            }
            self.shouldDetectRecursion = true
            defer {
                self.shouldDetectRecursion = false
            }
            return dataSource.looper(self, indexOf: WrapperViewController.unwrap(current))
        }

        guard let first = self.subviewControllers.firstIndex(of: current) else {
            breakpoint("Currently displayed view controller not in data source?!")
            return -1
        }
        return first
    }

    public var count: Int {
        if let dataSource = self.dataSource {
            guard !self.shouldDetectRecursion else {
                breakpoint("Recursion detected when using data source!")
                return 0
            }
            self.shouldDetectRecursion = true
            defer {
                self.shouldDetectRecursion = false
            }
            return dataSource.numberOfItems(inLooper: self)
        }

        return self.subviewControllers.count
    }

    private func indexIsValid(_ index: Int) -> Bool {
        if let dataSource = self.dataSource {
            return (0..<dataSource.numberOfItems(inLooper: self)).contains(index)
        }
        return self.subviewControllers.indices.contains(index)
    }

    private func index(after index: Int) -> Int {
        let max = max({
            if let dataSource = self.dataSource {
                return dataSource.numberOfItems(inLooper: self)
            }
            return self.subviewControllers.count
        }() - 1, 1)

        switch index {
        case ..<0:
            return 0
        case 0..<max:
            return index + 1
        case max...:
            return 0
        default:
            breakpoint("Impossible! Switch already covered all cases.")
            return 0
        }
    }

    // MARK: Transition

    public weak var delegate: LooperViewControllerDelegate?

    private var pendingTransition: DispatchWorkItem? {
        willSet {
            self.pendingTransition?.cancel()
        }
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   willTransitionTo pendingViewControllers: [UIViewController]) {
        self.pendingTransition = nil

        guard let next = pendingViewControllers.first else {
            return
        }

        if let dataSource = self.dataSource {
            let nextIndex = dataSource.looper(self, indexOf: WrapperViewController.unwrap(next))
            self.preTransitionHook(from: self.currentIndex, to: nextIndex)
            return
        }

        let currentIndex = self.currentIndex
        guard let nextIndex = self.subviewControllers.firstIndex(of: next), currentIndex != -1 else {
            return
        }
        self.preTransitionHook(from: currentIndex, to: nextIndex)
    }

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                                   previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let previous = previousViewControllers.first else { return }

        if let dataSource = self.dataSource {
            let previousIndex = dataSource.looper(self, indexOf: WrapperViewController.unwrap(previous))
            self.postTransitionHook(from: previousIndex, to: self.currentIndex)
            return
        }

        let currentIndex = self.currentIndex
        guard let previousIndex = self.subviewControllers.firstIndex(of: previous), currentIndex != -1 else {
            return
        }
        self.postTransitionHook(from: previousIndex, to: currentIndex)
    }

    private func preTransitionHook(from index: Int, to nextIndex: Int) {
        self.delegate?.looper(self, willBeginTransitionFrom: index, to: nextIndex)
    }

    private func setViewController(_ viewController: UIViewController, animated: Bool = true,
                                   completion: ((Bool) -> Void)? = nil) {
        // TODO: Delegate code transition.
        self.pager.setViewControllers([viewController], direction: .forward,
                                      animated: animated, completion: completion)
    }

    /// 翻到指定页面。
    ///
    /// - Parameter index: 新页面索引
    /// - Returns: 是否存在指定页面
    @discardableResult public func scrollTo(index: Int) -> Bool {
        guard let nextViewController = self.viewController(after: index - 1) else {
            return false
        }
        self.pager.setViewControllers([nextViewController], direction: .forward, animated: true) { _ in
            // TODO: Delegate auto transition.
            self.scheduleAutoScroll(to: self.index(after: index), after: 5)
        }
        return true
    }

    private func postTransitionHook(from previousIndex: Int, to index: Int) {
        self.delegate?.looper(self, didEndTransitionFrom: previousIndex, to: index)

        // TODO: Callback.
        self.scheduleAutoScroll(to: self.index(after: index), after: 5)
    }

    /// 计划自动翻页。调用此方法将取消先前所有计划翻页。
    ///
    /// - Parameters:
    ///   - index: 请求翻页到此索引。翻页前将重复检查索引有效性，无效索引将被丢弃。
    ///   - delay: 等待时间，自现在开始计时。
    public func scheduleAutoScroll(to index: Int, after delay: TimeInterval) {
        let nextTransition = DispatchWorkItem { [weak self] in
            guard let self = self, self.indexIsValid(index) else { return }
            self.scrollTo(index: index)
            self.delegate?.looper(self, autoTransitionedTo: index)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: nextTransition)
        self.pendingTransition = nextTransition
    }

    /// 取消所有自动翻页。
    public func cancelAutoScroll() {
        self.pendingTransition = nil
    }

    // MARK: Data Source

    /// 轮播初始位置。
    ///
    /// 使用 ``setViewControllers(_:startIndex:)`` 或 ``setViews(_:startIndex:respectsSafeAreaInsets:)`` 修改此属性。
    public private(set) var startIndex = 0

    /// 轮播数据源。
    ///
    /// 轮播通过 `UIPageViewController` 并结合此数据源实现。使用 ``setViewControllers(_:startIndex:)`` 或
    /// ``setViews(_:startIndex:respectsSafeAreaInsets:)`` 修改此属性。
    public private(set) var subviewControllers: [UIViewController] = []

    /// 轮播数据源。
    ///
    ///
    public private(set) weak var dataSource: LooperViewControllerDataSource?

    private func viewController(after index: Int) -> UIViewController? {
        // 询问数据源
        if let dataSource = self.dataSource {
            let count = dataSource.numberOfItems(inLooper: self)
            let item: Item? = {
                switch index {
                case count - 1:
                    return dataSource.looper(self, itemAt: 0)
                default:
                    return dataSource.looper(self, itemAt: index + 1)
                }
            }()

            return item?.asViewController()
        }

        // 取静态数据
        switch index {
        case self.subviewControllers.endIndex - 1:
            return self.subviewControllers.first
        default:
            let nextIndex = index + 1
            if self.subviewControllers.indices.contains(nextIndex) {
                return self.subviewControllers[nextIndex]
            }

            assertionFailure("Current index < (count - 1) but (index + 1) is out of range. Why?")
            return nil
        }
    }

    /// 设置一个或多个 `UIViewController` 作为数据源。如果通过此方法设置静态数据，基于回调的数据源将被舍弃。
    ///
    /// - Parameters:
    ///   - controllers: 数据源，如果为空将清空当前轮播数据。
    ///   - startIndex: 刷新数据后的初始位置，如果越界将使用 0。
    public func setViewControllers(_ controllers: [UIViewController], startIndex: Int = 0) {
        #warning("Stop animation.")

        self.dataSource = nil

        guard !controllers.isEmpty else {
            if self.isViewLoaded {
                self.pager.setViewControllers(nil, direction: .forward, animated: true) { _ in
                    self.subviewControllers = []
                    self.startIndex = 0
                }
            } else {
                self.subviewControllers = []
                self.startIndex = 0
            }
            return
        }

        if self.isViewLoaded {
            let newControllers: [UIViewController]? = {
                if controllers.indices.contains(startIndex) {
                    return [controllers[startIndex]]
                } else if let first = controllers.first {
                    return [first]
                } else {
                    return nil
                }
            }()
            self.pager.setViewControllers(newControllers, direction: .forward, animated: false) { _ in
                self.subviewControllers = controllers
                self.startIndex = startIndex
            }
        } else {
            self.subviewControllers = controllers
            self.startIndex = startIndex
        }
    }

    /// 设置一个或多个 `UIView` 作为数据源。如果通过此方法设置静态数据，基于回调的数据源将被舍弃。
    ///
    /// - Parameters:
    ///   - views: 数据源，如果为空将清空当前轮播数据。
    ///   - startIndex: 刷新数据后的初始位置，如果越界将使用 0。
    ///   - respectsSafeAreaInsets: 布局 `UIView` 时参考安全边界，置否（默认）将尝试充满轮播区域。
    public func setViews(_ views: [UIView], startIndex: Int = 0, respectsSafeAreaInsets: Bool) {
        #warning("Stop animation.")

        self.dataSource = nil

        guard !views.isEmpty else {
            if self.isViewLoaded {
                self.pager.setViewControllers(nil, direction: .forward, animated: true) { _ in
                    self.subviewControllers = []
                    self.startIndex = 0
                }
            } else {
                self.subviewControllers = []
                self.startIndex = 0
            }
            return
        }

        let viewControllers: [UIViewController] = views.map {
            WrapperViewController.wrap($0, respectsSafeAreaInsets: respectsSafeAreaInsets)
        }
        if self.isViewLoaded {
            let newControllers: [UIViewController]? = {
                if viewControllers.indices.contains(startIndex) {
                    return [viewControllers[startIndex]]
                } else if let first = viewControllers.first {
                    return [first]
                } else {
                    return nil
                }
            }()
            self.pager.setViewControllers(newControllers, direction: .forward, animated: false) { _ in
                self.subviewControllers = viewControllers
                self.startIndex = startIndex
            }
        } else {
            self.subviewControllers = viewControllers
            self.startIndex = startIndex
        }
    }

    /// 设置轮播数据源。如果通过此方法设置基于回调的数据源，静态数据将被舍弃。
    ///
    /// - Parameter dataSource: 实现 ``LooperViewControllerDataSource`` 的数据源。
    public func setDataSource(_ dataSource: LooperViewControllerDataSource) {
        #warning("Stop animation.")

        let startIndex = dataSource.startIndex(ofLooper: self)
        if self.isViewLoaded {
            let controller = dataSource.looper(self, itemAt: startIndex).asViewController()
            self.pager.setViewControllers([controller], direction: .forward, animated: false)
        }
        self.dataSource = dataSource
    }
}

// MARK: - LooperViewController.Item

public extension LooperViewController {
    enum Item {
        case view(UIView, respectsSafeAreaInsets: Bool?)
        case viewController(UIViewController)

        func asViewController() -> UIViewController {
            switch self {
            case let .view(view, respectsSafeAreaInsets):
                return WrapperViewController.wrap(view, respectsSafeAreaInsets: respectsSafeAreaInsets == true)
            case let .viewController(viewController):
                return viewController
            }
        }
    }
}

// MARK: - View Wrapper

final class WrapperViewController: UIViewController {
    private var content: UIView!

    static func wrap(_ view: UIView, respectsSafeAreaInsets: Bool) -> Self {
        let wrapper = Self()
        wrapper.content = view
        view.clipsToBounds = true
        wrapper.view.addSubview(view)
        if respectsSafeAreaInsets {
            view.autoLayout(in: wrapper.view.safeAreaLayoutGuide,
                            top: 0, bottom: 0, leading: 0, trailing: 0)
        } else {
            view.autoLayout(in: wrapper.view, top: 0, bottom: 0, leading: 0, trailing: 0)
        }
        return wrapper
    }

    static func unwrap(_ viewController: UIViewController) -> LooperViewController.Item {
        switch viewController {
        case let wrapper as Self:
            return .view(wrapper.content, respectsSafeAreaInsets: nil)
        default:
            return .viewController(viewController)
        }
    }
}

// MARK: - Debugging

private func breakpoint(_ message: String) {
    print(message)
#if DEBUG
    raise(SIGINT)
#endif
}
