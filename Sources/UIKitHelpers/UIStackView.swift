import Foundation
import UIKit

public protocol Stackable: NSObjectProtocol {
    var view: UIView! { get }
}

extension UIView: Stackable {
    public var view: UIView! {
        self
    }
}

extension UIViewController: Stackable {}

public extension Collection where Element: Stackable {
    func stacked(managedBy parent: UIViewController, _ builder: (UIStackView) -> Void) -> UIStackView {
        let stack = UIStackView()
        for item in self {
            switch item {
            case let view as UIView:
                stack.addArrangedSubview(view)
            case let controller as UIViewController:
                parent.addChild(controller)
                stack.addArrangedSubview(controller.view)
                controller.didMove(toParent: parent)
            default:
                continue
            }
        }
        builder(stack)
        return stack
    }
}
