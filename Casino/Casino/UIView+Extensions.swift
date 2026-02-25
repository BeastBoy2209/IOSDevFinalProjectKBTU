import UIKit

extension UIView {

    func animatePress(scale: CGFloat = 0.96, duration: TimeInterval = 0.12) {
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        } completion: { _ in
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
                self.transform = .identity
            }
        }
    }
}
