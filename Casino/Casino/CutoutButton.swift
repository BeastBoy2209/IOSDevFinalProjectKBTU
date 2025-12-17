import UIKit
import Foundation

class CutoutButton: UIButton {

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        tintColor.setFill()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
        path.fill()
        context.setBlendMode(.destinationOut)
        
        let text = self.title(for: .normal) ?? ""
        let font = self.titleLabel?.font ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        (text as NSString).draw(in: textRect, withAttributes: attributes)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .clear
    }
}
