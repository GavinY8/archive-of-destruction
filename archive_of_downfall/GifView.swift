import WebKit
import SwiftUI

struct GifView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        if let url = Bundle.main.url(forResource: name, withExtension: "gif") {
            let data = try! Data(contentsOf: url)
            webView.load(data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: url)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
