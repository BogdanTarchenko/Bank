import SwiftUI
import WebKit

public struct OAuthWebView: UIViewRepresentable {
    let url: URL
    let redirectScheme: String
    let onCallback: (URL) -> Void
    let onCancel: () -> Void

    public init(url: URL, redirectScheme: String, onCallback: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
        self.url = url
        self.redirectScheme = redirectScheme
        self.onCallback = onCallback
        self.onCancel = onCancel
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(redirectScheme: redirectScheme, onCallback: onCallback)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    public final class Coordinator: NSObject, WKNavigationDelegate {
        let redirectScheme: String
        let onCallback: (URL) -> Void
        private var callbackHandled = false

        init(redirectScheme: String, onCallback: @escaping (URL) -> Void) {
            self.redirectScheme = redirectScheme
            self.onCallback = onCallback
        }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if url.scheme == redirectScheme {
                    if !callbackHandled {
                        callbackHandled = true
                        onCallback(url)
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }

        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            if let failingURL = nsError.userInfo["NSErrorFailingURLKey"] as? URL {
                if failingURL.scheme == redirectScheme && !callbackHandled {
                    callbackHandled = true
                    onCallback(failingURL)
                }
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {}
    }
}
