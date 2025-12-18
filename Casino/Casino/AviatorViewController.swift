import UIKit

// MARK: - Модель данных
struct GameRound {
    let multiplier: Double
    let isWin: Bool
}

class AviatorViewController: UIViewController {

    // MARK: - Outlets (ПЕРЕПРИВЯЖИ ИХ ЗАНОВО)
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var multiplierLabel: UILabel!
    
    // Это просто UIView-контейнер, внутри которого лежит UIImageView самолета
    @IBOutlet weak var gameContainer: UIView!
    @IBOutlet weak var planeImageView: UIImageView!
    
    @IBOutlet weak var betTextField: UITextField!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var historyTableView: UITableView!
    
    @IBOutlet var presetButtons: [UIButton]! // Outlet Collection
    @IBOutlet weak var betSlider: UISlider!
    @IBOutlet weak var sliderValueLabel: UILabel!
    @IBOutlet weak var quickBetSwitch: UISwitch!

    // MARK: - Свойства игры
    private var timer: Timer?
    private var currentMultiplier: Double = 1.0
    private var crashMultiplier: Double = 0.0
    private var currentBalance: Double = 1000.0
    private var history: [GameRound] = []
    
    private var trailEmitter: CAEmitterLayer?

    // MARK: - Цвета (Безопасная загрузка)
    private let accentBlue = UIColor(named: "AccentBlue") ?? .cyan
    private let appBg = UIColor(named: "AppBackground") ?? .black
    private let cardBg = UIColor(named: "CardBackground") ?? .darkGray

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Настройка интерфейса
    private func setupUI() {
        view.backgroundColor = appBg
        
        // Настройка таблицы
        historyTableView.dataSource = self
        historyTableView.backgroundColor = .clear
        
        // Неоновая стилизация (через слои)
        setupNeonView(gameContainer)
        setupNeonView(actionButton)
        setupNeonView(betTextField)
        
        actionButton.backgroundColor = accentBlue
        actionButton.setTitleColor(appBg, for: .normal)
        
        // Загрузка баланса
        currentBalance = UserDefaults.standard.double(forKey: "user_balance")
        if currentBalance <= 0 { currentBalance = 1000.0 }
        updateBalanceLabel()
        
        // Подготовка эффекта дыма
        setupTrail()
    }

    private func setupNeonView(_ target: UIView) {
        target.layer.borderWidth = 2
        target.layer.borderColor = accentBlue.cgColor
        target.layer.cornerRadius = 15
        target.layer.shadowColor = accentBlue.cgColor
        target.layer.shadowRadius = 8
        target.layer.shadowOpacity = 0.5
        target.layer.masksToBounds = false
    }

    // MARK: - Логика Ставок
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let val = Int(sender.value)
        sliderValueLabel.text = "Множитель: x\(val)"
        let base = [100, 200, 500]
        for (i, btn) in presetButtons.enumerated() {
            btn.setTitle("\(base[i] * val)", for: .normal)
        }
    }

    @IBAction func presetButtonTapped(_ sender: UIButton) {
        betTextField.text = sender.titleLabel?.text
    }

    // MARK: - Игровой процесс
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        timer == nil ? startGame() : cashOut()
    }

    private func startGame() {
        guard let betText = betTextField.text, let bet = Double(betText), bet <= currentBalance else { return }
        
        // Сброс состояния
        currentMultiplier = 1.0
        crashMultiplier = Double.random(in: 1.1...4.5)
        currentBalance -= bet
        updateBalanceLabel()
        
        actionButton.setTitle("CASH OUT", for: .normal)
        actionButton.backgroundColor = .systemRed
        multiplierLabel.textColor = accentBlue
        
        // Анимация полета
        trailEmitter?.birthRate = 25
        UIView.animate(withDuration: 5.0, delay: 0, options: [.curveEaseIn]) {
            self.planeImageView.center = CGPoint(x: self.gameContainer.bounds.width - 40, y: 40)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateMultiplier()
        }
    }

    private func updateMultiplier() {
        currentMultiplier += 0.05
        multiplierLabel.text = String(format: "%.2fx", currentMultiplier)
        if currentMultiplier >= crashMultiplier { finishGame(isWin: false) }
    }

    private func cashOut() {
        let bet = Double(betTextField.text ?? "0") ?? 0
        currentBalance += bet * currentMultiplier
        finishGame(isWin: true)
    }

    private func finishGame(isWin: Bool) {
        timer?.invalidate()
        timer = nil
        trailEmitter?.birthRate = 0
        
        if isWin {
            resetPlanePosition()
        } else {
            createExplosion()
            multiplierLabel.text = "CRASHED"
            multiplierLabel.textColor = .systemRed
            planeImageView.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.resetPlanePosition()
                self.planeImageView.isHidden = false
            }
        }
        
        history.insert(GameRound(multiplier: currentMultiplier, isWin: isWin), at: 0)
        historyTableView.reloadData()
        UserDefaults.standard.set(currentBalance, forKey: "user_balance")
        
        updateBalanceLabel()
        actionButton.setTitle("START", for: .normal)
        actionButton.backgroundColor = accentBlue
    }

    private func resetPlanePosition() {
        planeImageView.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.3) {
            self.planeImageView.frame.origin = CGPoint(x: 10, y: self.gameContainer.bounds.height - 50)
        }
    }

    private func updateBalanceLabel() {
        balanceLabel.text = "Wallet: $\(Int(currentBalance))"
    }
}

// MARK: - UITableViewDataSource
extension AviatorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        let round = history[indexPath.row]
        cell.textLabel?.text = "Результат: \(String(format: "%.2fx", round.multiplier))"
        cell.textLabel?.textColor = round.isWin ? accentBlue : .systemRed
        cell.backgroundColor = .clear
        return cell
    }
}

// MARK: - Эффекты (Дым и Взрыв)
extension AviatorViewController {
    private func setupTrail() {
        let emitter = CAEmitterLayer()
        planeImageView.layer.addSublayer(emitter)
        emitter.emitterPosition = CGPoint(x: 0, y: 20)
        let cell = CAEmitterCell()
        cell.contents = makeParticleImage()
        cell.birthRate = 0
        cell.lifetime = 0.6
        cell.velocity = -40
        cell.scale = 0.15
        cell.alphaSpeed = -0.5
        cell.color = UIColor.white.withAlphaComponent(0.3).cgColor
        emitter.emitterCells = [cell]
        trailEmitter = emitter
    }

    private func createExplosion() {
        let explosion = CAEmitterLayer()
        explosion.position = planeImageView.layer.presentation()?.position ?? planeImageView.center
        gameContainer.layer.addSublayer(explosion)
        let cell = CAEmitterCell()
        cell.contents = makeParticleImage()
        cell.birthRate = 500
        cell.lifetime = 0.4
        cell.velocity = 80
        cell.emissionRange = .pi * 2
        cell.color = UIColor.orange.cgColor
        explosion.emitterCells = [cell]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { explosion.birthRate = 0 }
    }

    private func makeParticleImage() -> CGImage? {
        let rect = CGRect(origin: .zero, size: CGSize(width: 10, height: 10))
        UIGraphicsBeginImageContext(rect.size)
        UIColor.white.setFill()
        UIBezierPath(ovalIn: rect).fill()
        let img = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        return img
    }
}
