//
//  ViewController.swift
//  WheelNeon
//
//  Created by Айжан Жунусова on 17.12.2025.
//

import UIKit

// --- 1. РАСШИРЕНИЕ ДЛЯ НЕОНОВЫХ ЦВЕТОВ ---
extension UIColor {
    static let neonBlue = UIColor(red: 0/255, green: 247/255, blue: 255/255, alpha: 1)
    static let neonRed = UIColor(red: 255/255, green: 50/255, blue: 120/255, alpha: 1)
    static let neonGreen = UIColor(red: 57/255, green: 255/255, blue: 20/255, alpha: 1)
    static let neonYellow = UIColor(red: 255/255, green: 253/255, blue: 130/255, alpha: 1)
    static let darkBG = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1)
}

class RouletteViewController: UIViewController {
    
    // --- 2. OUTLETS (Связи с экраном) ---
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var rouletteContainer: UIView!
    @IBOutlet weak var rouletteCollection: UICollectionView!
    @IBOutlet weak var selectionFrame: UIView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var betAmountTextField: UITextField!
    @IBOutlet weak var chipsStackView: UIStackView!
    @IBOutlet weak var bettingStackView: UIStackView!
    @IBOutlet weak var spinButton: UIButton!
    
    // --- 3. ПЕРЕМЕННЫЕ ИГРЫ ---
    let numbers = Array(0...36)
    let redNumbers: Set<Int> = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
    let totalItems = 10_000
    var currentIndex = 5_000
    var balance = 1000
    
    enum BetType {
        case number(Int)
        case color(IsRed: Bool)
    }
    var currentBet: BetType?
    var selectedBetButton: UIButton?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // --- 4. ЖИЗНЕННЫЙ ЦИКЛ ---
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ВАЖНО: Сначала настраиваем констрейнты
        setupConstraints()
        
        // Затем наводим красоту
        setupNeonStyle()
        
        // Остальная настройка
        rouletteCollection.dataSource = self
        rouletteCollection.delegate = self
        setupChips()
        setupBettingTable()
        updateBalance()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        DispatchQueue.main.async {
            self.scrollToIndex(self.currentIndex, animated: false)
        }
    }
    
    // --- 6. ПРОГРАММНЫЕ КОНСТРЕЙНТЫ ---
    func setupConstraints() {
        // Получаем ScrollView по tag
        guard let scrollView = view.viewWithTag(1000) as? UIScrollView else { return }
        
        // Отключаем автоматические констрейнты
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        rouletteContainer.translatesAutoresizingMaskIntoConstraints = false
        rouletteCollection.translatesAutoresizingMaskIntoConstraints = false
        selectionFrame.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        betAmountTextField.translatesAutoresizingMaskIntoConstraints = false
        chipsStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        bettingStackView.translatesAutoresizingMaskIntoConstraints = false
        spinButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // 1. Balance Label (Верх экрана)
            balanceLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            balanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            balanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            balanceLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // 2. Roulette Container (Под балансом)
            rouletteContainer.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 20),
            rouletteContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rouletteContainer.widthAnchor.constraint(equalToConstant: 320),
            rouletteContainer.heightAnchor.constraint(equalToConstant: 160),
            
            // 2a. Roulette Collection (внутри контейнера)
            rouletteCollection.topAnchor.constraint(equalTo: rouletteContainer.topAnchor),
            rouletteCollection.leadingAnchor.constraint(equalTo: rouletteContainer.leadingAnchor),
            rouletteCollection.trailingAnchor.constraint(equalTo: rouletteContainer.trailingAnchor),
            rouletteCollection.bottomAnchor.constraint(equalTo: rouletteContainer.bottomAnchor),
            
            // 2b. Selection Frame (внутри контейнера, по центру)
            selectionFrame.centerXAnchor.constraint(equalTo: rouletteContainer.centerXAnchor),
            selectionFrame.centerYAnchor.constraint(equalTo: rouletteContainer.centerYAnchor),
            selectionFrame.widthAnchor.constraint(equalToConstant: 280),
            selectionFrame.heightAnchor.constraint(equalToConstant: 60),
            
            // 3. Result Label (Под рулеткой)
            resultLabel.topAnchor.constraint(equalTo: rouletteContainer.bottomAnchor, constant: 15),
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // 4. Bet Amount Field (Под результатом)
            betAmountTextField.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 15),
            betAmountTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            betAmountTextField.widthAnchor.constraint(equalToConstant: 140),
            betAmountTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // 5. Chips Stack View (Под полем ввода)
            chipsStackView.topAnchor.constraint(equalTo: betAmountTextField.bottomAnchor, constant: 15),
            chipsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chipsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            chipsStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            chipsStackView.heightAnchor.constraint(equalToConstant: 40),
            
            // 6. Spin Button (Самый низ)
            spinButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            spinButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            spinButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            spinButton.heightAnchor.constraint(equalToConstant: 60),
            
            // 7. Scroll View (Между фишками и кнопкой)
            scrollView.topAnchor.constraint(equalTo: chipsStackView.bottomAnchor, constant: 15),
            scrollView.bottomAnchor.constraint(equalTo: spinButton.topAnchor, constant: -15),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            
            // 8. Betting Stack View (ВНУТРИ Скролла)
            bettingStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            bettingStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            bettingStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            bettingStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            bettingStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    // --- 7. ДИЗАЙН (NEON GLOW) ---
    func setupNeonStyle() {
        view.backgroundColor = .darkBG
        
        balanceLabel.textColor = .neonBlue
        addGlow(to: balanceLabel, color: .neonBlue)
        
        rouletteContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        rouletteContainer.layer.cornerRadius = 20
        rouletteContainer.layer.borderWidth = 2
        rouletteContainer.layer.borderColor = UIColor.neonBlue.cgColor
        addGlow(to: rouletteContainer, color: .neonBlue)
        
        selectionFrame.layer.borderWidth = 4
        selectionFrame.layer.borderColor = UIColor.neonYellow.cgColor
        selectionFrame.layer.cornerRadius = 12
        addGlow(to: selectionFrame, color: .neonYellow)
        
        betAmountTextField.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        betAmountTextField.textColor = .neonYellow
        betAmountTextField.layer.cornerRadius = 10
        betAmountTextField.layer.borderWidth = 1
        betAmountTextField.layer.borderColor = UIColor.neonYellow.cgColor
        betAmountTextField.attributedPlaceholder = NSAttributedString(string: "Amount", attributes: [.foregroundColor: UIColor.gray])
        
        spinButton.backgroundColor = .black
        spinButton.layer.cornerRadius = 15
        spinButton.layer.borderWidth = 2
        spinButton.layer.borderColor = UIColor.neonBlue.cgColor
        spinButton.setTitleColor(.neonBlue, for: .normal)
        spinButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        addGlow(to: spinButton, color: .neonBlue)
    }
    
    func addGlow(to view: UIView, color: UIColor) {
        view.layer.shadowColor = color.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 0.8
        view.layer.masksToBounds = false
    }

    // --- 7. ГЕНЕРАЦИЯ КНОПОК ---
    func setupChips() {
        let amounts = [10, 50, 100, 500]
        for amount in amounts {
            let btn = createButton(title: "$\(amount)", color: .neonGreen, isChip: true)
            btn.tag = amount
            btn.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chipsStackView.addArrangedSubview(btn)
        }
        let maxBtn = createButton(title: "MAX", color: .neonRed, isChip: true)
        maxBtn.addTarget(self, action: #selector(maxTapped), for: .touchUpInside)
        chipsStackView.addArrangedSubview(maxBtn)
    }
    
    func setupBettingTable() {
        let zero = createButton(title: "0", color: .neonGreen)
        zero.tag = 0
        zero.addTarget(self, action: #selector(betNumberTapped(_:)), for: .touchUpInside)
        bettingStackView.addArrangedSubview(zero)
        
        for i in stride(from: 1, through: 36, by: 3) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 8
            
            for j in 0..<3 {
                let num = i + j
                let color: UIColor = redNumbers.contains(num) ? .neonRed : .neonBlue
                let btn = createButton(title: "\(num)", color: color)
                btn.tag = num
                btn.addTarget(self, action: #selector(betNumberTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
            }
            bettingStackView.addArrangedSubview(rowStack)
        }
        
        let colorRow = UIStackView()
        colorRow.axis = .horizontal
        colorRow.distribution = .fillEqually
        colorRow.spacing = 8
        
        let redBtn = createButton(title: "RED", color: .neonRed)
        redBtn.addTarget(self, action: #selector(betRedTapped(_:)), for: .touchUpInside)
        
        let blackBtn = createButton(title: "BLACK", color: .neonBlue)
        blackBtn.addTarget(self, action: #selector(betBlackTapped(_:)), for: .touchUpInside)
        
        colorRow.addArrangedSubview(redBtn)
        colorRow.addArrangedSubview(blackBtn)
        
        let spacer = UIView(); spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        bettingStackView.addArrangedSubview(spacer)
        bettingStackView.addArrangedSubview(colorRow)
        
        let bottomSpacer = UIView(); bottomSpacer.heightAnchor.constraint(equalToConstant: 50).isActive = true
        bettingStackView.addArrangedSubview(bottomSpacer)
    }
    
    func createButton(title: String, color: UIColor, isChip: Bool = false) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(color, for: .normal)
        btn.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: isChip ? 14 : 24, weight: .bold)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        btn.layer.borderWidth = 2
        btn.layer.borderColor = color.cgColor
        btn.layer.cornerRadius = isChip ? 20 : 10
        btn.layer.shadowColor = color.cgColor
        btn.layer.shadowOffset = .zero
        btn.layer.shadowRadius = 5
        btn.layer.shadowOpacity = 0.5
        if !isChip {
            btn.heightAnchor.constraint(equalToConstant: 70).isActive = true
        }
        return btn
    }

    // --- 7. ЛОГИКА (ACTIONS) ---
    @IBAction func spinButtonTapped(_ sender: UIButton) {
        dismissKeyboard()
        guard let bet = currentBet else {
            resultLabel.text = "Select a bet first!"
            resultLabel.textColor = .neonRed
            return
        }
        guard let text = betAmountTextField.text, let amount = Int(text), amount > 0 else {
            resultLabel.text = "Enter amount!"
            resultLabel.textColor = .neonYellow
            return
        }
        if balance < amount {
            resultLabel.text = "Insufficient funds!"
            resultLabel.textColor = .neonRed
            return
        }
        
        balance -= amount
        updateBalance()
        resultLabel.text = "Spinning..."
        resultLabel.textColor = .white
        
        let winningNumber = Int.random(in: 0...36)
        let offset = 60
        var targetIndex = currentIndex + offset
        while numbers[targetIndex % numbers.count] != winningNumber {
            targetIndex += 1
        }
        currentIndex = targetIndex
        scrollToIndex(targetIndex, animated: true)
        
        spinButton.isEnabled = false
        spinButton.alpha = 0.5
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.checkWin(bet: bet, result: winningNumber, amount: amount)
            self.spinButton.isEnabled = true
            self.spinButton.alpha = 1.0
        }
    }
    
    @objc func chipTapped(_ sender: UIButton) {
        animatePress(sender)
        betAmountTextField.text = "\(sender.tag)"
    }
    
    @objc func maxTapped(_ sender: UIButton) {
        animatePress(sender)
        betAmountTextField.text = "\(balance)"
    }
    
    @objc func betNumberTapped(_ sender: UIButton) {
        selectBetButton(sender)
        currentBet = .number(sender.tag)
        resultLabel.text = "Bet on: Number \(sender.tag)"
        resultLabel.textColor = sender.titleColor(for: .normal)
    }
    
    @objc func betRedTapped(_ sender: UIButton) {
        selectBetButton(sender)
        currentBet = .color(IsRed: true)
        resultLabel.text = "Bet on: RED"
        resultLabel.textColor = .neonRed
    }
    
    @objc func betBlackTapped(_ sender: UIButton) {
        selectBetButton(sender)
        currentBet = .color(IsRed: false)
        resultLabel.text = "Bet on: BLACK"
        resultLabel.textColor = .neonBlue
    }
    
    func selectBetButton(_ btn: UIButton) {
        if let old = selectedBetButton {
            let color = old.titleColor(for: .normal)?.cgColor
            old.layer.borderColor = color
            old.layer.shadowColor = color
            old.transform = .identity
        }
        selectedBetButton = btn
        btn.layer.borderColor = UIColor.neonYellow.cgColor
        btn.layer.shadowColor = UIColor.neonYellow.cgColor
        UIView.animate(withDuration: 0.1) {
            btn.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        dismissKeyboard()
    }
    
    func animatePress(_ btn: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            btn.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                btn.transform = .identity
            }
        }
    }
    
    func checkWin(bet: BetType, result: Int, amount: Int) {
        var didWin = false
        var prize = 0
        let isResultRed = redNumbers.contains(result)
        
        switch bet {
        case .number(let n):
            if n == result {
                didWin = true
                prize = amount * 35
            }
        case .color(let isBetRed):
            if result != 0 && isBetRed == isResultRed {
                didWin = true
                prize = amount * 2
            }
        }
        
        if didWin {
            balance += prize
            resultLabel.text = "WIN! \(result) (+\(prize)$)"
            resultLabel.textColor = .neonGreen
        } else {
            resultLabel.text = "Lost. Result: \(result)"
            resultLabel.textColor = .neonRed
        }
        updateBalance()
    }
    
    func scrollToIndex(_ idx: Int, animated: Bool) {
        rouletteCollection.scrollToItem(at: IndexPath(item: idx, section: 0), at: .centeredVertically, animated: animated)
    }
    
    func updateBalance() {
        balanceLabel.text = "BALANCE: \(balance)$"
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// --- 8. НАСТРОЙКА ЛЕНТЫ РУЛЕТКИ ---
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RouletteCell", for: indexPath)
        
        if let label = cell.viewWithTag(100) as? UILabel {
            let num = numbers[indexPath.item % numbers.count]
            label.text = "\(num)"
            
            if num == 0 {
                label.textColor = .neonGreen
            } else if redNumbers.contains(num) {
                label.textColor = .neonRed
            } else {
                label.textColor = .neonBlue
            }
            
            label.layer.shadowColor = label.textColor.cgColor
            label.layer.shadowRadius = 8
            label.layer.shadowOpacity = 1
            label.layer.shadowOffset = .zero
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 60)
    }
}

