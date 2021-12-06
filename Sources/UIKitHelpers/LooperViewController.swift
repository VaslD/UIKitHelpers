import AutoLayout
import UIKit

public class LooperViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    // MARK: Lifecycle

    override public func loadView() {
        super.loadView()
        _ = self.pager
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

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

    // MARK: Looper

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

#if DEBUG
            assertionFailure("Current index > 0 but (index - 1) is out of range. Why?")
            return nil
#else
            return self.subviewControllers.first
#endif
        }
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.subviewControllers.firstIndex(of: viewController) else {
            return nil
        }

        switch index {
        case self.subviewControllers.endIndex - 1:
            return self.subviewControllers.first
        default:
            let nextIndex = index + 1
            if self.subviewControllers.indices.contains(nextIndex) {
                return self.subviewControllers[nextIndex]
            }

#if DEBUG
            assertionFailure("Current index < (count - 1) but (index + 1) is out of range. Why?")
            return nil
#else
            return self.subviewControllers.first
#endif
        }
    }

    // MARK: Contents

    /// 轮播布局方向。
    ///
    /// 默认为横向。此属性只能在视图加载前（例如构造 ``LooperViewController`` 后）设置，当系统或调用者首次访问此 View Controller
    /// 的视图 （`view`) 时，视图将根据布局方向创建并冻结布局方向，以后将不再参考此属性。
    public var orientation: UIPageViewController.NavigationOrientation = .horizontal

    /// 轮播初始位置。
    ///
    /// 使用 ``setViewControllers(_:startIndex:)`` 或 ``setViews(_:startIndex:respectsSafeAreaInsets:)`` 修改此属性。
    public private(set) var startIndex = 0

    /// 轮播数据源。
    ///
    /// 轮播通过 `UIPageViewController` 并结合此数据源实现。使用 ``setViewControllers(_:startIndex:)`` 或
    /// ``setViews(_:startIndex:respectsSafeAreaInsets:)`` 修改此属性。
    public private(set) var subviewControllers: [UIViewController] = []

    /// 设置一个或多个 `UIViewController` 作为数据源。
    ///
    /// - Parameters:
    ///   - controllers: 数据源，如果为空将清空当前轮播数据。
    ///   - startIndex: 刷新数据后的初始位置，如果越界将使用 0。
    public func setViewControllers(_ controllers: [UIViewController], startIndex: Int = 0) {
        #warning("Stop animation.")
        
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

    /// 设置一个或多个 `UIView` 作为数据源。
    ///
    /// - Parameters:
    ///   - views: 数据源，如果为空将清空当前轮播数据。
    ///   - startIndex: 刷新数据后的初始位置，如果越界将使用 0。
    ///   - respectsSafeAreaInsets: 布局 `UIView` 时参考安全边界，置否（默认）将尝试充满轮播区域。
    public func setViews(_ views: [UIView], startIndex: Int = 0, respectsSafeAreaInsets: Bool) {
        #warning("Stop animation.")

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
            $0.clipsToBounds = true
            let controller = UIViewController()
            controller.view.addSubview($0)
            if respectsSafeAreaInsets {
                $0.autoLayout(in: controller.view.safeAreaLayoutGuide, top: 0, bottom: 0, leading: 0, trailing: 0)
            } else {
                $0.autoLayout(in: controller.view, top: 0, bottom: 0, leading: 0, trailing: 0)
            }
            return controller
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
}
