import UIKit

class BlackJackViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var dealerStackView: UIStackView!
    @IBOutlet weak var playerStackView: UIStackView!
    @IBOutlet weak var dealerScoreLabel: UILabel!
    @IBOutlet weak var playerScoreLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    
    @IBOutlet weak var dealButton: UIButton!
    @IBOutlet weak var hitButton: UIButton!
    @IBOutlet weak var standButton: UIButton!
    @IBOutlet weak var doubleButton: UIButton!
    @IBOutlet weak var splitButton: UIButton!
    
    @IBOutlet weak var chip100Button: UIButton!
    @IBOutlet weak var chip200Button: UIButton!
    @IBOutlet weak var chip500Button: UIButton!
    
    // Exit button created programmatically (similar behavior to RouletteViewController)
    var exitButton: UIButton!
    
    var game = BlackjackGame()
    var isDealerCardRevealed = false

    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Create exit button and observe user data changes
        setupExitButton()
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserManagerUpdate(_:)), name: UserManager.didUpdateNotification, object: nil)
        
        setupNeonUI()
        updateUIState(isPlaying: false)
        updateLabels()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupNeonUI() {
        let actionButtons = [dealButton, hitButton, standButton, doubleButton, splitButton]
        let chips = [chip100Button, chip200Button, chip500Button]
        
        actionButtons.forEach { btn in
            btn?.layer.cornerRadius = 8
            btn?.layer.borderWidth = 1.5
            btn?.layer.borderColor = UIColor.cyan.cgColor
            btn?.setTitleColor(.cyan, for: .normal)
            btn?.setTitleColor(UIColor.cyan.withAlphaComponent(0.3), for: .disabled)
            btn?.layer.shadowColor = UIColor.cyan.cgColor
            btn?.layer.shadowRadius = 5
            btn?.layer.shadowOpacity = 0.6
        }
        
        chips.forEach { btn in
            btn?.layer.cornerRadius = btn!.frame.height / 2
            btn?.layer.borderWidth = 2
            btn?.layer.borderColor = UIColor.systemPink.cgColor
            
        }
        
        balanceLabel.layer.borderColor = UIColor.systemGreen.cgColor
        balanceLabel.layer.borderWidth = 1.5
        balanceLabel.layer.cornerRadius = 10
    }

    // MARK: - Exit button
    func setupExitButton() {
        exitButton = UIButton(type: .system)
        exitButton.setTitle("✕", for: .normal)
        exitButton.setTitleColor(.systemPink, for: .normal)
        exitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 28)
        exitButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        exitButton.layer.cornerRadius = 20
        exitButton.layer.borderWidth = 2
        exitButton.layer.borderColor = UIColor.systemPink.cgColor
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.addTarget(self, action: #selector(exitButtonTapped), for: .touchUpInside)
        
        view.addSubview(exitButton)
        
        NSLayoutConstraint.activate([
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            exitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            exitButton.widthAnchor.constraint(equalToConstant: 40),
            exitButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Glow
        exitButton.layer.shadowColor = UIColor.systemPink.cgColor
        exitButton.layer.shadowOffset = .zero
        exitButton.layer.shadowRadius = 8
        exitButton.layer.shadowOpacity = 0.8
        exitButton.layer.masksToBounds = false
    }
    
    @objc func exitButtonTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.exitButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.exitButton.transform = .identity
            }
        }
        dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: true)
    }

    @objc func handleUserManagerUpdate(_ notification: Notification) {
        // Update balance display when UserManager posts changes
        updateLabels()
    }

    @IBAction func chipTapped(_ sender: UIButton) {
        game.addBet(sender.tag)
        updateLabels()
    }

    @IBAction func dealTapped(_ sender: UIButton) {
        guard game.currentBet > 0 else { return }
        isDealerCardRevealed = false
        clearTable()
        game.dealInitialCards()
        updateUIState(isPlaying: true)
        
        addCardToStack(card: game.playerHand[0], stack: playerStackView, delay: 0.1)
        addCardToStack(card: game.dealerHand[0], stack: dealerStackView, delay: 0.2)
        addCardToStack(card: game.playerHand[1], stack: playerStackView, delay: 0.3)
        
        let hiddenCard = Cards(card: game.dealerHand[1], frame: CGRect(x: 0, y: 0, width: 65, height: 90), isFaceUp: false)
        hiddenCard.tag = 999
        dealerStackView.addArrangedSubview(hiddenCard)
        updateLabels()
    }
    
    @IBAction func hitTapped(_ sender: UIButton) {
        let card = game.drawCard()
        game.playerHand.append(card)
        addCardToStack(card: card, stack: playerStackView, delay: 0)
        
        doubleButton.isEnabled = false
        splitButton.isEnabled = false
        
        updateLabels()
        if game.calculateScore(for: game.playerHand) > 21 { endGame() }
    }
    
    @IBAction func doubleTapped(_ sender: UIButton) {
        // Double uses UserManager-backed balance via game.addBet logic
        // We already deducted original bet when placing it; doubling requires paying extra equal to currentBet
        if UserManager.shared.balance >= game.currentBet {
            UserManager.shared.addCredits(amount: -game.currentBet, source: "Blackjack Bet")
            game.currentBet *= 2
        }
        updateLabels()
        
        let card = game.drawCard()
        game.playerHand.append(card)
        addCardToStack(card: card, stack: playerStackView, delay: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.standTapped(self.standButton)
        }
    }
    
    @IBAction func splitTapped(_ sender: UIButton) {
        if game.playerHand.count == 2 {
            // Split: pay an extra bet equal to current bet
            if UserManager.shared.balance >= game.currentBet {
                UserManager.shared.addCredits(amount: -game.currentBet, source: "Blackjack Bet")
                _ = game.playerHand.removeLast()
                playerStackView.arrangedSubviews.last?.removeFromSuperview()
                
                game.playerHand.append(game.drawCard())
                addCardToStack(card: game.playerHand.last!, stack: playerStackView, delay: 0.2)
                
                showFancyResult(message: "SPLIT!")
                updateLabels()
                splitButton.isEnabled = false
            }
        }
    }
    
    @IBAction func standTapped(_ sender: UIButton) {
        isDealerCardRevealed = true
        revealDealerCard()
        
        let newCards = game.dealerTurn()
        var delay = 0.4
        for card in newCards {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.addCardToStack(card: card, stack: self.dealerStackView, delay: 0)
                self.updateLabels()
            }
            delay += 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.3) { self.endGame() }
    }

    
    func updateUIState(isPlaying: Bool) {
        dealButton.isHidden = isPlaying
        hitButton.isHidden = !isPlaying
        standButton.isHidden = !isPlaying
        doubleButton.isHidden = !isPlaying
        splitButton.isHidden = !isPlaying
        
        chip100Button.isHidden = isPlaying
        chip200Button.isHidden = isPlaying
        chip500Button.isHidden = isPlaying
        
        if isPlaying {
            doubleButton.isEnabled = UserManager.shared.balance >= game.currentBet
            let canSplit = game.playerHand.count == 2 && game.playerHand[0].rank == game.playerHand[1].rank
            splitButton.isEnabled = canSplit && UserManager.shared.balance >= game.currentBet
        }
    }
    
    func revealDealerCard() {
        if let hidden = dealerStackView.viewWithTag(999) {
            hidden.removeFromSuperview()
            let realCard = Cards(card: game.dealerHand[1], frame: CGRect(x: 0, y: 0, width: 65, height: 90))
            dealerStackView.addArrangedSubview(realCard)
        }
    }

    func addCardToStack(card: Card, stack: UIStackView, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let cardView = Cards(card: card, frame: CGRect(x: 0, y: 0, width: 65, height: 90))
            cardView.alpha = 0
            stack.addArrangedSubview(cardView)
            UIView.animate(withDuration: 0.3) { cardView.alpha = 1 }
            self.updateLabels()
        }
    }
    
    func updateLabels() {
        balanceLabel.text = " BALANCE: $\(UserManager.shared.balance) | BET: $\(game.currentBet) "
        playerScoreLabel.text = "YOU: \(game.calculateScore(for: game.playerHand))"
        let dScore = isDealerCardRevealed ? game.calculateScore(for: game.dealerHand) : (game.dealerHand.first?.rank.value ?? 0)
        dealerScoreLabel.text = "DEALER: \(dScore)"
    }
    
    func clearTable() {
        dealerStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        playerStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    func endGame() {
        isDealerCardRevealed = true
        revealDealerCard()
        let result = game.determineWinner()
        updateLabels()
        updateUIState(isPlaying: false)
        showFancyResult(message: result)
    }

    func showFancyResult(message: String) {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = .black
        overlay.alpha = 0
        view.addSubview(overlay)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 150))
        label.center = view.center
        label.text = message
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 50, weight: .black)
        label.textColor = (message == "ПОБЕДА!" || message == "НИЧЬЯ" || message == "SPLIT!") ? .systemGreen : .systemPink
        label.layer.shadowColor = label.textColor.cgColor
        label.layer.shadowRadius = 15
        label.layer.shadowOpacity = 1
        overlay.addSubview(label)
        
        UIView.animate(withDuration: 0.4) {
            overlay.alpha = 0.85
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.4, animations: { overlay.alpha = 0 }) { _ in
                overlay.removeFromSuperview()
                if message != "SPLIT!" { self.game.resetBet() }
                self.updateLabels()
            }
        }
    }
}
