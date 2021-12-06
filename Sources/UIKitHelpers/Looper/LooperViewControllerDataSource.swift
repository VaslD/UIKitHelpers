import UIKit

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
