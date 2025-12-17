import UIKit

final class ProfileViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var levelLabel: UILabel!

    @IBOutlet private weak var gamesPlayedLabel: UILabel!
    @IBOutlet private weak var winsLabel: UILabel!
    @IBOutlet private weak var winRateLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        avatarImageView?.layer.cornerRadius = (avatarImageView?.bounds.height ?? 0) / 2
        avatarImageView?.clipsToBounds = true

        render()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserManagerUpdate(_:)),
            name: UserManager.didUpdateNotification,
            object: UserManager.shared
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView?.layer.cornerRadius = (avatarImageView?.bounds.height ?? 0) / 2
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
        let user = UserManager.shared

        nameLabel?.text = user.userName
        levelLabel?.text = "Level \(user.level)"

        gamesPlayedLabel?.text = "\(user.stats.gamesPlayed)"
        winsLabel?.text = "\(user.stats.wins)"
        winRateLabel?.text = String(format: "%.0f%%", user.stats.winRate)
    }

    // MARK: - Notifications

    @objc private func handleUserManagerUpdate(_ notification: Notification) {
        render()
    }
}
