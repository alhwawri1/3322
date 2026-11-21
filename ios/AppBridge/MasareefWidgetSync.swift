import Foundation
import WebKit
import WidgetKit

final class MasareefWidgetSyncHelper: NSObject, WKScriptMessageHandler {
    static let shared = MasareefWidgetSyncHelper()
    static let appGroupId = "group.com.alhawari.masareef"
    static let snapshotKey = "masareef_widget_snapshot_v1"

    func attach(to webView: WKWebView) {
        let controller = webView.configuration.userContentController
        controller.removeScriptMessageHandler(forName: "masareefWidgetSync")
        controller.add(self, name: "masareefWidgetSync")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "masareefWidgetSync",
              let body = message.body as? [String: Any],
              let payload = body["payload"] as? String else { return }

        let suite = (body["suite"] as? String) ?? Self.appGroupId
        if let defaults = UserDefaults(suiteName: suite) {
            defaults.set(payload, forKey: Self.snapshotKey)
            defaults.synchronize()
        }
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
