import UIKit

public extension UITableView {
    func recalculateHeight() {
        self.performBatchUpdates(nil)
    }
}
