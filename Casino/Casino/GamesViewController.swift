import UIKit

final class GamesViewController: UIViewController {

    // MARK: - IBOutlets (connect in Main.storyboard)

    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private var playNowButtons: [UIButton]!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

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

    // MARK: - UI

    private func render() {
        balanceLabel?.text = formatCredits(UserManager.shared.balance)
    }

    private func formatCredits(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Actions

    /// Connect all "Play Now" buttons on the Games tab to this IBAction.
    /// Mapping suggestion:
    /// - Use `tag` in Interface Builder: 0=Blackjack, 1=Aviator, 2=Roulette ...
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

    // MARK: - Notifications

    @objc private func handleUserManagerUpdate(_ notification: Notification) {
        render()
    }
}
