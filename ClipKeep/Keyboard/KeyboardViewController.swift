import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController {
    private let store = ClipStore()
    private let model = KeyboardModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        model.insertText = { [weak self] in self?.textDocumentProxy.insertText($0) }
        model.deleteBackward = { [weak self] in self?.textDocumentProxy.deleteBackward() }
        model.nextKeyboard = { [weak self] in self?.advanceToNextInputMode() }

        let host = UIHostingController(rootView: KeyboardView(store: store, model: model))
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(host)
        view.addSubview(host.view)
        let height = host.view.heightAnchor.constraint(equalToConstant: 290)
        // Below .required so it doesn't fight the system's temporary height constraint.
        height.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            height,
        ])
        host.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Pick up entries added in the app since the keyboard was last shown.
        store.reload()
        model.hasFullAccess = hasFullAccess
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if model.needsGlobe != needsInputModeSwitchKey {
            model.needsGlobe = needsInputModeSwitchKey
        }
    }
}
