import UIKit

open class ImageOnRightButton: UIButton {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadView()
    }

    open func loadView() {
        self.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
    }
}
