import SwiftUI
import UIKit
import UniformTypeIdentifiers
import ShelfKit

enum ShareInput {
    case text(String)
    case url(URL)
    case empty
}

/// Principal class of the Save to Shelf extension. Pulls the shared text or URL
/// off the extension context, then hosts the SwiftUI capture sheet.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.98, green: 0.976, blue: 0.968, alpha: 1)
        loadInput { [weak self] input in
            DispatchQueue.main.async { self?.presentCapture(with: input) }
        }
    }

    private func loadInput(completion: @escaping (ShareInput) -> Void) {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .flatMap { $0.attachments ?? [] } ?? []

        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { item, _ in
                if let text = item as? String {
                    completion(.text(text))
                } else if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                    completion(.text(text))
                } else {
                    completion(.empty)
                }
            }
        } else if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                if let url = item as? URL {
                    completion(.url(url))
                } else {
                    completion(.empty)
                }
            }
        } else {
            completion(.empty)
        }
    }

    private func presentCapture(with input: ShareInput) {
        let capture = ShareCaptureView(
            input: input,
            onDone: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(
                    withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
                )
            }
        )
        let hosting = UIHostingController(rootView: capture)
        addChild(hosting)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
    }
}
