import UIKit

class Cards: UIView {
    init(card: Card, frame: CGRect, isFaceUp: Bool = true) {
        super.init(frame: frame)
        setup(card: card, isFaceUp: isFaceUp)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup(card: Card, isFaceUp: Bool) {
        self.backgroundColor = isFaceUp ? .white : UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 2
        self.layer.borderColor = isFaceUp ? UIColor.cyan.cgColor : UIColor.systemPink.cgColor
        
        // Свечение (Glow)
        self.layer.shadowColor = isFaceUp ? UIColor.cyan.cgColor : UIColor.systemPink.cgColor
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 6
        self.layer.shadowOffset = .zero
        
        if isFaceUp {
            let color: UIColor = (card.suit == .hearts || card.suit == .diamonds) ? .systemPink : .black
            
            let rankLbl = UILabel(frame: CGRect(x: 5, y: 2, width: 30, height: 20))
            rankLbl.text = card.rank.title
            rankLbl.font = .systemFont(ofSize: 16, weight: .bold)
            rankLbl.textColor = color
            
            let centerLbl = UILabel(frame: self.bounds)
            centerLbl.text = card.suit.rawValue
            centerLbl.font = .systemFont(ofSize: 32)
            centerLbl.textAlignment = .center
            centerLbl.textColor = color.withAlphaComponent(0.6)
            
            [rankLbl, centerLbl].forEach { addSubview($0) }
        }
    }
}
