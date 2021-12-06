import UIKit

public protocol LooperViewControllerDelegate: AnyObject {
    func looper(_ viewController: LooperViewController, willBeginTransitionFrom index: Int, to nextIndex: Int)
    func looper(_ viewController: LooperViewController, didEndTransitionFrom previousIndex: Int, to index: Int)
}
