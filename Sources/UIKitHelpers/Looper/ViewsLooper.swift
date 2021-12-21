import UIKit

/// 自动管理子 `UIView` 的轮播组件。
///
/// 使用此组件时不能修改 ``LooperViewController/dataSource``，请通过 ``setViews(_:respectsSafeAreaInsets:startIndex:)``
/// 提供每页的 `UIView`。
open class ViewsLooper: ViewControllersLooper {
    public func setViews(_ views: [UIView], respectsSafeAreaInsets: Bool = false, startIndex: Int = 0) {
        let viewControllers: [UIViewController] = views.map {
            WrapperViewController.wrap($0, respectsSafeAreaInsets: respectsSafeAreaInsets)
        }
        self.setViewControllers(viewControllers, startIndex: startIndex)
    }
}

// MARK: - Wrapper

private final class WrapperViewController: UIViewController {
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
}
