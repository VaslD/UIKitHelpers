import UIKit

open class AnimatedLooper: UIViewController, LooperTransitionDelegate {
    // MARK: Looper

    var looper: ViewsLooper!

    public private(set) lazy var carouselView: UIView = {
        self.looper = ViewsLooper()
        self.looper.delegate = self
        self.addChild(self.looper)
        self.view.addSubview(looper.view)
        looper.view.autoLayout(in: self.view, top: 0, bottom: 0, leading: 0, trailing: 0)
        looper.didMove(toParent: self)
        return looper.view
    }()

    override open func loadView() {
        super.loadView()
        _ = self.carouselView
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.overlayView != nil, self.overlayLeadingConstraint == nil {
            print("[AnimatedLooper] Warning:",
                  "Overlay is assigned but overlay constraint is nil. Animations may not perform as expected.",
                  "Check if you have given AnimatedLooper your overlay's leading constraint.")
#if LOOPER_BREAK_ON_WARNING
            raise(SIGINT)
#endif
        }
    }

    // MARK: Animations

    /// 重载或赋值此属性以提供需要随页面切换执行动画的浮层。
    public var overlayView: UIView?

    /// 重载或赋值此属性以提供需要随页面切换执行动画的浮层的左边距约束。
    public var overlayLeadingConstraint: NSLayoutConstraint?

    /// 准备隐藏浮层。默认实现为空，重载此方法以准备 ``overlayView`` 位移和隐藏动画。
    ///
    /// > Important: 此方法只能用于更改当前显示的数据和位置，在执行动画前这些修改会被预先应用到界面上。在此方法中调用
    /// `UIView.animate()` 可能导致非预期结果。
    ///
    /// - Parameters:
    ///   - index: 当前页面位置
    ///   - nextIndex: 新页面位置
    ///   - automatic: 是否通过代码切换页面触发，而不是用户通过手势切换
    open func prepareHidingAnimations(from index: Int, to nextIndex: Int, automatic: Bool) {}

    /// 附加隐藏动画。默认实现为空，重载此方法以在 ``overlayView`` 位移和隐藏动画过程中附加其他 UI 动画。
    ///
    /// > Important: 此方法只能用于更改界面上其他元素。当 ``overlayView`` 动画执行时，这些更改会一同按进度应用。在此方法中调用
    /// `UIView.animate()` 或操作 ``overlayView`` 可能导致非预期结果。
    ///
    /// - Parameters:
    ///   - index: 动画前页面位置
    ///   - nextIndex: 动画后页面位置
    ///   - automatic: 是否通过代码切换页面触发，而不是用户通过手势切换
    ///   - direction: 页面切换方向
    open func performAdditionalHidingAnimations(from index: Int, to nextIndex: Int, automatic: Bool,
                                                direction: UIPageViewController.NavigationDirection) {}

    /// 准备显示浮层。默认实现为空，重载此方法以准备 ``overlayView`` 位移和显示动画。通常需要在此方法中设置浮层上的新数据。
    ///
    /// > Important: 此方法只能用于更改当前显示的数据和位置，在执行动画前这些修改会被预先应用到界面上。在此方法中调用
    /// `UIView.animate()` 可能导致非预期结果。
    ///
    /// - Parameters:
    ///   - previousIndex: 旧页面位置
    ///   - index: 当前页面位置
    ///   - automatic: 是否通过代码切换页面触发，而不是用户通过手势切换
    open func prepareShowingAnimations(from previousIndex: Int?, to index: Int, automatic: Bool) {}

    /// 附加显示动画。默认实现为空，重载此方法以在 ``overlayView`` 位移和显示动画过程中附加其他 UI 动画。
    ///
    /// > Important: 此方法只能用于更改界面上其他元素。当 ``overlayView`` 动画执行时，这些更改会一同按进度应用。在此方法中调用
    /// `UIView.animate()` 或操作 ``overlayView`` 可能导致非预期结果。
    ///
    /// - Parameters:
    ///   - previousIndex: 动画前页面位置
    ///   - index: 动画后页面位置
    ///   - automatic: 是否通过代码切换页面触发，而不是用户通过手势切换
    ///   - direction: 页面切换方向
    open func performAdditionalShowingAnimations(from previousIndex: Int, to index: Int, automatic: Bool,
                                                 direction: UIPageViewController.NavigationDirection) {}

    /// 附加无动画显示逻辑。默认实现为空，重载此方法以在 ``overlayView`` 不能使用动画时立即显示其他 UI 元素。
    ///
    /// > Important: 此方法只能用于更改界面上其他元素。当 ``overlayView`` 需要从隐藏状态显示但当前 UI
    /// 状态不允许执行动画时，这些更改会被直接应用。在此方法中调用 `UIView.animate()` 或操作 ``overlayView`` 可能导致非预期结果。
    ///
    /// - Parameters:
    ///   - previousIndex: 计划的动画前页面位置
    ///   - index: 计划的动画后页面位置
    open func prepareShowingWithoutAnimations(from previousIndex: Int?, to index: Int) {}

    // MARK: LooperTransitionDelegate

    private var previousIndex: Int?

    open func looperWillTransition(from index: Int, to nextIndex: Int) {
        self.previousIndex = nil
        self.prepareHidingAnimations(from: index, to: nextIndex, automatic: false)
        self.animateHiding(from: index, to: nextIndex, automatic: false)
    }

    open func looperDidTransition(from previousIndex: Int, to index: Int) {
        self.previousIndex = nil
        self.prepareShowingAnimations(from: previousIndex, to: index, automatic: false)
        self.animateShowing(from: previousIndex, to: index, automatic: false)
    }

    open func prepareForAutoTransition(to index: Int?) {
        guard let from = self.looper.currentIndex else {
            return
        }
        self.previousIndex = from
        guard let to = index else {
            return
        }
        self.prepareHidingAnimations(from: from, to: to, automatic: true)
        self.animateHiding(from: from, to: to, automatic: true)
    }

    open func postProcessAutoTransition(to index: Int?, animated: Bool) {
        guard let to = index else {
            return
        }
        self.prepareShowingAnimations(from: self.previousIndex, to: to, automatic: true)
        if let from = self.previousIndex, animated {
            self.animateShowing(from: from, to: to, automatic: true)
        } else {
            self.prepareShowingWithoutAnimations(from: self.previousIndex, to: to)
            self.overlayView?.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    open func delayBeforeAutoTransition(at index: Int) -> TimeInterval {
        0
    }

    private func transitionDirection(from: Int, to: Int) -> UIPageViewController.NavigationDirection {
        if from == to {
            return .forward
        }
        if to == from + 1 {
            return .forward
        }
        if to == from - 1 {
            return .reverse
        }
        return from == 0 ? .reverse : .forward
    }

    private func animateHiding(from index: Int, to nextIndex: Int, automatic: Bool) {
        self.view.layoutIfNeeded()

        let direction = self.transitionDirection(from: index, to: nextIndex)
        switch direction {
        case .forward:
            UIView.animate(withDuration: 0.3) {
                self.overlayLeadingConstraint?.constant = -10
                self.overlayView?.alpha = 0
                self.performAdditionalHidingAnimations(from: index, to: nextIndex,
                                                       automatic: automatic, direction: direction)
                self.view.layoutIfNeeded()
            }
        case .reverse:
            UIView.animate(withDuration: 0.3) {
                self.overlayLeadingConstraint?.constant = 10
                self.overlayView?.alpha = 0
                self.performAdditionalHidingAnimations(from: index, to: nextIndex,
                                                       automatic: automatic, direction: direction)
                self.view.layoutIfNeeded()
            }
        @unknown default:
            UIView.animate(withDuration: 0.3) {
                self.overlayView?.alpha = 0
                self.performAdditionalHidingAnimations(from: index, to: nextIndex,
                                                       automatic: automatic, direction: direction)
                self.view.layoutIfNeeded()
            }
        }
    }

    private func animateShowing(from previousIndex: Int, to index: Int, automatic: Bool) {
        self.view.layoutIfNeeded()

        let direction = self.transitionDirection(from: previousIndex, to: index)
        switch direction {
        case .forward:
            self.overlayLeadingConstraint?.constant = 10
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.3) {
                self.overlayLeadingConstraint?.constant = 0
                self.overlayView?.alpha = 1
                self.performAdditionalShowingAnimations(from: previousIndex, to: index,
                                                        automatic: automatic, direction: direction)
                self.view.layoutIfNeeded()
            }
        case .reverse:
            self.overlayLeadingConstraint?.constant = -10
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.3) {
                self.overlayLeadingConstraint?.constant = 0
                self.overlayView?.alpha = 1
                self.performAdditionalShowingAnimations(from: previousIndex, to: index,
                                                        automatic: automatic, direction: direction)
                self.view.layoutIfNeeded()
            }
        @unknown default:
            self.overlayLeadingConstraint?.constant = 0
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.3) {
                self.overlayView?.alpha = 1
                self.performAdditionalShowingAnimations(from: previousIndex, to: index,
                                                        automatic: automatic, direction: direction)
                self.view.layoutIfNeeded()
            }
        }
    }
}
