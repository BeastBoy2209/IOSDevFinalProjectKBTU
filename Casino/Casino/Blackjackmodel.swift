import Foundation

enum Suit: String, CaseIterable {
    case hearts = "♥", diamonds = "♦", clubs = "♣", spades = "♠"
}

enum Rank: Int, CaseIterable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen = 12, king = 13, ace = 14
    
    var value: Int {
        if self == .ace { return 11 }
        return min(self.rawValue, 10)
    }
    
    var title: String {
        switch self {
        case .jack: return "J"; case .queen: return "Q"; case .king: return "K"; case .ace: return "A"
        default: return "\(self.rawValue)"
        }
    }
}

struct Card {
    let suit: Suit
    let rank: Rank
}

class BlackjackGame {
    var deck: [Card] = []
    var playerHand: [Card] = []
    var dealerHand: [Card] = []
    // balance is now proxied to UserManager.shared to keep a single source of truth
    var balance: Int {
        get { UserManager.shared.balance }
        set { UserManager.shared.addCredits(amount: newValue - UserManager.shared.balance, source: "Blackjack") }
    }
    var currentBet: Int = 0 // Ставка теперь начинается с 0
    
    init() { createNewDeck() }
    
    func createNewDeck() {
        deck = []
        for suit in Suit.allCases {
            for rank in Rank.allCases { deck.append(Card(suit: suit, rank: rank)) }
        }
        deck.shuffle()
    }
    
    func addBet(_ amount: Int) {
        // Use UserManager for balance checks and deduction
        guard amount > 0 else { return }
        guard UserManager.shared.balance >= amount else { return }
        currentBet += amount
        UserManager.shared.addCredits(amount: -amount, source: "Blackjack Bet")
    }
    
    func dealInitialCards() {
        if deck.count < 10 { createNewDeck() }
        playerHand = [drawCard(), drawCard()]
        dealerHand = [drawCard(), drawCard()]
    }
    
    func drawCard() -> Card {
        if deck.isEmpty { createNewDeck() }
        return deck.removeLast()
    }
    
    func calculateScore(for hand: [Card]) -> Int {
        var score = hand.reduce(0) { $0 + $1.rank.value }
        var aces = hand.filter { $0.rank == .ace }.count
        while score > 21 && aces > 0 { score -= 10; aces -= 1 }
        return score
    }
    
    func dealerTurn() -> [Card] {
        var newCards: [Card] = []
        while calculateScore(for: dealerHand) < 17 {
            let card = drawCard()
            dealerHand.append(card)
            newCards.append(card)
        }
        return newCards
    }
    
    func determineWinner() -> String {
        let pScore = calculateScore(for: playerHand)
        let dScore = calculateScore(for: dealerHand)
        let winAmount = currentBet * 2
        
        if pScore > 21 {
            // player busts: already deducted bet when added
            UserManager.shared.recordGameResult(gameName: "Blackjack", didWin: false, delta: 0)
            currentBet = 0
            return "ПЕРЕБОР"
        }
        if dScore > 21 {
            // dealer busts -> player wins
            UserManager.shared.recordGameResult(gameName: "Blackjack", didWin: true, delta: winAmount)
            currentBet = 0
            return "ПОБЕДА!"
        }
        if pScore > dScore {
            UserManager.shared.recordGameResult(gameName: "Blackjack", didWin: true, delta: winAmount)
            currentBet = 0
            return "ПОБЕДА!"
        }
        if pScore < dScore {
            UserManager.shared.recordGameResult(gameName: "Blackjack", didWin: false, delta: 0)
            currentBet = 0
            return "ПРОИГРЫШ"
        }
        // tie -> return bet
        UserManager.shared.recordGameResult(gameName: "Blackjack", didWin: false, delta: currentBet)
        currentBet = 0
        return "НИЧЬЯ"
    }
    
    func resetBet() {
        currentBet = 0
    }
}
