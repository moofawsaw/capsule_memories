import UserNotifications
import UIKit

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                            withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Best-effort: make the "avatar"/image attachment circular.
        // NOTE: iOS notifications still lay out attachments as rounded rectangles
        // (true circular contact photos require Communication Notifications),
        // but this ensures the image itself is a circle (transparent corners).
        let userInfo = bestAttemptContent.userInfo

        func string(_ any: Any?) -> String? {
            if let s = any as? String, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return s
            }
            return nil
        }

        // Prefer explicit avatar keys; fall back to FCM image keys.
        var urlString: String? =
            string(userInfo["avatar_url"]) ??
            string(userInfo["avatar"]) ??
            string(userInfo["user_avatar"]) ??
            string(userInfo["profile_image"])

        if urlString == nil,
           let fcm = userInfo["fcm_options"] as? [String: Any] {
            urlString = string(fcm["image"])
        }
        if urlString == nil {
            urlString = string(userInfo["image"]) ?? string(userInfo["image_url"])
        }

        guard let raw = urlString, let url = URL(string: raw) else {
            contentHandler(bestAttemptContent)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                contentHandler(bestAttemptContent)
                return
            }

            let circled = self.circleImage(image)
            guard let png = circled.pngData() else {
                contentHandler(bestAttemptContent)
                return
            }

            let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("avatar_circle_\(UUID().uuidString).png")
            do {
                try png.write(to: tmp)
                let attachment = try UNNotificationAttachment(identifier: "avatar", url: tmp, options: nil)
                bestAttemptContent.attachments = [attachment]
            } catch {
                // ignore
            }

            contentHandler(bestAttemptContent)
        }
        task.resume()
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func circleImage(_ image: UIImage) -> UIImage {
        let size = min(image.size.width, image.size.height)
        let square = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: square)

        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: square)
            ctx.cgContext.clear(rect)
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.clip()

            // Center-crop
            let originX = (image.size.width - size) / 2.0
            let originY = (image.size.height - size) / 2.0
            let drawRect = CGRect(x: -originX, y: -originY, width: image.size.width, height: image.size.height)
            image.draw(in: drawRect)
        }
    }
}