import UIKit

public extension UIViewController {
    func addChildView(from childViewController: UIViewController, to superview: UIView? = nil) -> UIView {
        self.addChild(childViewController)
        let childView = childViewController.view!
        (superview ?? self.view)?.addSubview(childView)
        childViewController.didMove(toParent: self)
        return childView
    }

    func removeChildView(from childViewController: UIViewController) {
        childViewController.view.removeFromSuperview()
        childViewController.willMove(toParent: nil)
        childViewController.removeFromParent()
    }
}
