import SwiftUI
import MessageUI

public struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String?
    let subject: String
    let body: String
    let attachmentData: Data
    let attachmentMimeType: String
    let attachmentFilename: String
    let completion: (Result<MFMailComposeResult, Error>) -> Void

    public init(
        recipient: String? = nil,
        subject: String,
        body: String,
        attachmentData: Data,
        attachmentMimeType: String = "application/octet-stream",
        attachmentFilename: String,
        completion: @escaping (Result<MFMailComposeResult, Error>) -> Void
    ) {
        self.recipient = recipient
        self.subject = subject
        self.body = body
        self.attachmentData = attachmentData
        self.attachmentMimeType = attachmentMimeType
        self.attachmentFilename = attachmentFilename
        self.completion = completion
    }

    public func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        if let recipient = recipient {
            vc.setToRecipients([recipient])
        }
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.addAttachmentData(attachmentData, mimeType: attachmentMimeType, fileName: attachmentFilename)
        return vc
    }

    public func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    public class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let completion: (Result<MFMailComposeResult, Error>) -> Void

        init(completion: @escaping (Result<MFMailComposeResult, Error>) -> Void) {
            self.completion = completion
        }

        public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(result))
            }
            controller.dismiss(animated: true)
        }
    }
}

public struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    public init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
