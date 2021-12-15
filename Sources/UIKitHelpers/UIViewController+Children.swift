import UIKit

public extension UIViewController {
    /// 管理新的子视图控制器，并将其视图作为子视图添加。
    ///
    /// 此方法会将子视图控制器添加为当前控制器的子控制器，在合适的时机调用需要手动触发的系统函数，添加并返回子控制器视图。
    ///
    /// > Important: 子控制器视图应该被添加到当前控制器管理的视图上。如果需要添加到其他控制器管理的视图上，请使用对应控制器调用添加方法。
    ///
    /// - Parameters:
    ///   - childViewController: 新的子视图控制器。
    ///   - superview: 将新控制器的视图添加到此视图。
    /// - Returns: 子控制器的视图，用于后续布局。
    func addChildView(from childViewController: UIViewController, to superview: UIView? = nil) -> UIView {
        let parentView: UIView = {
            if let view = superview {
#if DEBUG // 在 DEBUG 配置下，检查 superview 是否是 self 直接管理的视图，并警告可能引起问题的特殊用法。
                if let superviewController: UIViewController = {
                    var next = superview?.next
                    while let responder = next {
                        if let viewController = responder as? UIViewController {
                            return viewController
                        }
                        next = responder.next
                    }
                    return nil
                }() {
                    if superviewController != self {
                        // 参数 superview 归其他控制器（而非 self）管理，建议通过 superview 的控制器调用 addChildView(from:to:)
                        print("尝试管理新的子视图控制器、并将其视图添加到由其他控制器管理的父视图上。如此做可能出现非预期现象。")
                        // DEBUG 配置下会触发调试器断点。如果你保证本次调用会正常工作，恢复运行即可。
                        // RELEASE 配置下假设所有特殊用法是故意的，不会执行此类检查；如果系统不支持此用法可能出现运行问题。
                        raise(SIGINT)
                    }
                } else {
                    // 参数 superview 目前没有控制器管理。self 可以管理新的子控制器但不建议将子视图添加到 superview 上
                    print("尝试管理新的子视图控制器、并将其子视图添加到不受控制器管理的父视图上。如此做可能出现非预期现象。")
                    // DEBUG 配置下会触发调试器断点。如果你保证本次调用会正常工作，恢复运行即可。
                    // RELEASE 配置下假设所有特殊用法是故意的，不会执行此类检查；如果系统不支持此用法可能出现运行问题。
                    raise(SIGINT)
                }
#endif
                return view
            }
            return self.view
        }()

        self.addChild(childViewController)
        let childView = childViewController.view!

        // 特殊处理不能直接调用 addSubview() 的父视图
        if let stack = parentView as? UIStackView {
            stack.addArrangedSubview(childView)
        } else {
            parentView.addSubview(childView)
        }

        childViewController.didMove(toParent: self)
        return childView
    }

    /// 移除用于提供子视图的受管理控制器。
    ///
    /// 此方法会移除子控制器视图，在合适的时机调用需要手动触发的系统函数，并将子控制器与当前控制器解绑。
    ///
    /// > Important: 此方法只能移除当前控制器的直接子控制器。如果子控制器被视图层级内其他控制器管理，请使用对应父控制器调用移除方法。
    ///
    /// - Parameter childViewController: 子视图的控制器。
    func removeChildView(from childViewController: UIViewController) {
        // 尽管将子视图控制器移除不需要 parent 参与，此方法仍然不允许跨视图控制器层级调用，以免滥用。
        // DEBUG 配置下会触发调试器断点，并警告误用。RELEASE 配置下错误调用无效。
        guard self.children.contains(childViewController) else {
#if DEBUG
            print("正在移除不受管理的子视图控制器。本次调用无效。")
            raise(SIGINT)
#endif
            return
        }

        let childView = childViewController.view!
        // 检查是否需要先移除子控制器管理的视图
        if let superview = childView.superview {
            // 特殊处理需要额外工作才能移除的子视图
            if let stackView = superview as? UIStackView {
                stackView.removeArrangedSubview(childView)
            }
            childView.removeFromSuperview()
        }

        childViewController.willMove(toParent: nil)
        childViewController.removeFromParent()
    }
}
