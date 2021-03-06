import UIKit

/// 自动管理子 `UIViewController` 的轮播组件。
///
/// 使用此组件时不能修改 ``LooperViewController/dataSource``，请通过 ``setViewControllers(_:startIndex:)``
/// 提供每页的 `UIViewController`。
open class ViewControllersLooper: LooperViewController, LooperDataSource {
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
    }

    // MARK: Data Source

    public private(set) var subviewControllers = [UIViewController]()

    public private(set) var startIndex = 0

    public var numberOfItems: Int {
        self.subviewControllers.count
    }

    public func viewController(at index: Int) -> UIViewController? {
        guard self.subviewControllers.indices.contains(index) else {
            return nil
        }
        return self.subviewControllers[index]
    }

    public func indexOf(_ viewController: UIViewController) -> Int? {
        self.subviewControllers.firstIndex(of: viewController)
    }

    public func setViewControllers(_ viewControllers: [UIViewController], startIndex: Int = 0) {
        self.subviewControllers = viewControllers
        self.startIndex = startIndex

        guard !viewControllers.isEmpty else {
            self.pager.setViewControllers(nil, direction: .forward, animated: false)
            return
        }

        if let startViewController = self.viewController(at: startIndex) {
            self.setViewController(startViewController, animated: true)
        } else if let startViewController = self.viewController(at: 0) {
            self.setViewController(startViewController, animated: true)
        } else {
            self.setViewController(nil, animated: true)
        }
    }

    // MARK: Transition

    public var autoTransitionInterval: TimeInterval = 3

    override open func delayBeforeAutoTransition(at index: Int) -> TimeInterval {
        if let delegate = self.delegate {
            return delegate.delayBeforeAutoTransition(at: index)
        }
        return self.autoTransitionInterval
    }
}
