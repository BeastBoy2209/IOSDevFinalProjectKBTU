import UIKit
import Foundation

@IBDesignable
class CardView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 16 {
        didSet { layer.cornerRadius = cornerRadius }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet { layer.borderWidth = borderWidth }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet { layer.borderColor = borderColor?.cgColor }
    }
    
    // Градиент
    @IBInspectable var startColor: UIColor = .clear { didSet { updateGradient() } }
    @IBInspectable var endColor: UIColor = .clear { didSet { updateGradient() } }
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    func updateGradient() {
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        // Направление градиента: слева-направо (для кнопок) или сверху-вниз
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }
}
