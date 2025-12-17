import UIKit

final class WalletViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var transactionContainerStackView: UIStackView!

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        render()
        refreshTransactions()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserManagerUpdate(_:)),
            name: UserManager.didUpdateNotification,
            object: UserManager.shared
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
        refreshTransactions()
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

    func refreshTransactions() {
        guard transactionContainerStackView != nil else { return }

        // 1) Clear existing views
        transactionContainerStackView.arrangedSubviews.forEach { subview in
            transactionContainerStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        // 2) Loop transactions
        let transactions = UserManager.shared.transactions

        if transactions.isEmpty {
            transactionContainerStackView.addArrangedSubview(makeEmptyStateRow())
            return
        }

        // 3) Create rows programmatically and add to stack
        for tx in transactions {
            transactionContainerStackView.addArrangedSubview(makeTransactionRow(transaction: tx))
        }
    }

    private func makeEmptyStateRow() -> UIView {
        let label = UILabel()
        label.text = "No transactions yet"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }

    private func makeTransactionRow(transaction: UserManager.Transaction) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.secondarySystemBackground
        container.layer.cornerRadius = 14
        container.clipsToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = transaction.gameName
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        let dateLabel = UILabel()
        dateLabel.text = dateFormatter.string(from: transaction.date)
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .secondaryLabel

        let amountLabel = UILabel()
        amountLabel.font = .systemFont(ofSize: 16, weight: .bold)
        amountLabel.textAlignment = .right
        amountLabel.textColor = transaction.isCredit ? .systemGreen : .systemRed
        amountLabel.text = (transaction.isCredit ? "+" : "") + formatCredits(transaction.amount)

        let leftStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [leftStack, amountLabel])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        return container
    }

    // MARK: - Actions

    @IBAction private func addCreditsTapped(_ sender: UIButton) {
        sender.animatePress()

        let alert = UIAlertController(title: "Add Credits", message: "Enter amount to deposit", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "15000"
            tf.keyboardType = .numberPad
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Deposit", style: .default, handler: { _ in
            let text = alert.textFields?.first?.text ?? ""
            let amount = Int(text.filter { $0.isNumber }) ?? 0
            guard amount > 0 else { return }
            UserManager.shared.addCredits(amount: amount, source: "Deposit")
        }))

        present(alert, animated: true)
    }

    // MARK: - Notifications

    @objc private func handleUserManagerUpdate(_ notification: Notification) {
        render()
        refreshTransactions()
    }
}
