import UIKit

final class HomeViewController: UIViewController {

    // MARK: - IBOutlets (connect in Main.storyboard)

    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var profileImageView: UIImageView!

    /// Banner CTA button. When claimed, we convert it into a disabled “Already claimed” state.
    @IBOutlet private weak var bannerButton: UIButton!

    @IBOutlet private var playNowButtons: [UIButton]!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        bannerButton?.layer.cornerRadius = 12
        bannerButton?.clipsToBounds = true

        profileImageView?.layer.cornerRadius = (profileImageView?.bounds.height ?? 0) / 2
        profileImageView?.clipsToBounds = true

        render()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserManagerUpdate(_:)),
            name: UserManager.didUpdateNotification,
            object: UserManager.shared
        )

        playNowButtons?.forEach { $0.addTarget(self, action: #selector(playNowTapped(_:)), for: .touchUpInside) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Rendering

    private func render() {
        let user = UserManager.shared
        balanceLabel?.text = formatCredits(user.balance)

        updateBannerUI(isClaimed: user.isHomeBannerClaimed, animated: false)
    }

    private func formatCredits(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return formatted
    }

    private func updateBannerUI(isClaimed: Bool, animated: Bool) {
        guard let bannerButton else { return }

        let apply = {
            if isClaimed {
                bannerButton.isEnabled = false
                bannerButton.alpha = 0.75

                // A nicer text than just “Already claimed”.
                bannerButton.setTitle("Already claimed · Come back tomorrow", for: .normal)

                if #available(iOS 15.0, *) {
                    var config = bannerButton.configuration
                    config?.title = "Already claimed · Come back tomorrow"
                    config?.image = UIImage(systemName: "checkmark.seal.fill")
                    config?.baseForegroundColor = .white
                    bannerButton.configuration = config
                } else {
                    bannerButton.setImage(UIImage(systemName: "checkmark.seal.fill"), for: .normal)
                    bannerButton.tintColor = .white
                }
            } else {
                bannerButton.isEnabled = true
                bannerButton.alpha = 1

                bannerButton.setTitle("Claim Now", for: .normal)

                if #available(iOS 15.0, *) {
                    var config = bannerButton.configuration
                    config?.title = "Claim Now"
                    config?.image = UIImage(systemName: "gift.fill")
                    config?.baseForegroundColor = .white
                    bannerButton.configuration = config
                } else {
                    bannerButton.setImage(UIImage(systemName: "gift.fill"), for: .normal)
                    bannerButton.tintColor = .white
                }
            }
        }

        if animated {
            UIView.transition(with: bannerButton, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction], animations: apply)
        } else {
            apply()
        }
    }

    // MARK: - Actions

    @IBAction private func bannerButtonTapped(_ sender: UIButton) {
        sender.animatePress()

        let oldBalance = UserManager.shared.balance
        let didClaim = UserManager.shared.claimHomeBannerBonus(amount: 15_000)
        let newBalance = UserManager.shared.balance

        guard didClaim else {
            updateBannerUI(isClaimed: true, animated: true)
            return
        }

        updateBannerUI(isClaimed: true, animated: true)
        animateBalanceChange(from: oldBalance, to: newBalance)
    }

    /// - Set `button.tag` in Interface Builder: 0=Blackjack, 1=Aviator, 2=Roulette, etc.
    /// - Or connect all buttons to `playNowButtons` outlet collection.
    @IBAction private func playNowTapped(_ sender: UIButton) {
        sender.animatePress()

        let gameName = gameName(forTag: sender.tag)
        presentGame(gameName: gameName)
    }

    private func presentGame(gameName: String) {
        let vc = GameViewController(gameName: gameName)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    private func gameName(forTag tag: Int) -> String {
        switch tag {
        case 0: return "Blackjack"
        case 1: return "Aviator"
        case 2: return "Roulette"
        default: return "Game"
        }
    }

    // MARK: - Animations

    private func animateBalanceChange(from oldValue: Int, to newValue: Int) {
        let duration: TimeInterval = 0.6
        let steps = max(10, Int(duration * 60))
        let delta = Double(newValue - oldValue) / Double(steps)

        var currentStep = 0
        let start = Double(oldValue)

        balanceLabel?.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)

        Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            currentStep += 1
            let value = Int(round(start + (Double(currentStep) * delta)))
            self.balanceLabel?.text = self.formatCredits(value)

            if currentStep >= steps {
                timer.invalidate()
                UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
                    self.balanceLabel?.transform = .identity
                }
            }
        }
    }

    // MARK: - Notifications

    @objc private func handleUserManagerUpdate(_ notification: Notification) {
        render()
    }
}

// MARK: - Placeholder GameViewController

final class GameViewController: UIViewController {
    private let gameName: String

    init(gameName: String) {
        self.gameName = gameName
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = gameName
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
