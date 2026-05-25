//
//  PrivacyView.swift
//  E-Presensi
//
//  Setara PrivacyActivity + activity_privacy.xml (HtmlCompat.fromHtml)
//

import SwiftUI
import WebKit
import Combine

enum PrivacyContent {
    /// HTML identik dengan `PrivacyActivity.kt` (setelah trimIndent)
    static let htmlFragment = """
<p style="text-indent: 45px;">Aplikasi E-Presensi dimiliki oleh Pemerintah Daerah Kabupaten Pringsewu, yang merupakan pengontrol data data pribadi Anda.</p>
<p style="text-indent: 45px;">Kami telah mengadopsi Kebijakan Privasi ini, yang menentukan bagaimana kami memproses informasi yang dikumpulkan oleh Aplikasi, yang juga memberikan alasan mengapa kami harus mengumpulkan data pribadi tertentu tentang Anda. Oleh karena itu, Anda harus membaca Kebijakan Privasi ini sebelum menggunakan Aplikasi E-Presensi.</p>
<p style="text-indent: 45px;">Kami menjaga data pribadi Anda dan berjanji untuk menjamin kerahasiaan dan keamanannya.</p>

<b>Informasi pribadi yang kami kumpulkan:</b>
<p style="text-indent: 45px;">Saat Anda mengunjungi Aplikasi, kami secara otomatis mengumpulkan informasi tertentu tentang perangkat Anda. Kami menyebut informasi yang dikumpulkan secara otomatis ini sebagai “Informasi Perangkat.” Selain itu, kami mungkin mengumpulkan data pribadi yang Anda berikan kepada kami (termasuk namun tidak terbatas pada Nama, Nama Keluarga, Alamat, dll.) pada saat pendaftaran untuk dapat memenuhi perjanjian.</p>

<b>Mengapa kami memproses data Anda?</b>
<p style="text-indent: 45px;">Prioritas utama kami adalah keamanan data pelanggan, dan, dengan demikian, kami hanya dapat memproses data pengguna minimal, hanya sebanyak yang benar-benar diperlukan untuk memelihara Aplikasi. Informasi yang dikumpulkan secara otomatis hanya digunakan untuk mengidentifikasi potensi kasus penyalahgunaan dan menetapkan informasi statistik terkait penggunaan Aplikasi. Informasi statistik ini tidak dikumpulkan sedemikian rupa sehingga akan mengidentifikasi pengguna tertentu dari sistem.</p>
<p style="text-indent: 45px;">Anda dapat mengunjungi Aplikasi tanpa memberi tahu kami siapa Anda atau mengungkapkan informasi apa pun, yang dengannya seseorang dapat mengidentifikasi Anda sebagai individu tertentu yang dapat diidentifikasi. Namun, jika Anda ingin menggunakan beberapa fitur Aplikasi, Anda dapat memberikan data pribadi kepada kami, seperti email Anda, nama depan, nama belakang, kota tempat tinggal, organisasi, nomor telepon. Anda dapat memilih untuk tidak memberikan data pribadi Anda kepada kami, tetapi kemudian Anda mungkin tidak dapat memanfaatkan beberapa fitur Aplikasi. Misalnya, Anda tidak akan dapat menerima Buletin kami atau menghubungi kami langsung dari Aplikasi. Pengguna yang tidak yakin tentang informasi apa yang wajib dipersilakan untuk menghubungi kami melalui diskominfokabupaten@gmail.com.</p>

<b>Informasi keamanan:</b>
<p style="text-indent: 45px;">Kami mengamankan informasi yang Anda berikan di server komputer dalam lingkungan yang terkendali dan aman, terlindung dari akses, penggunaan, atau pengungkapan yang tidak sah. Kami menjaga pengamanan administratif, teknis, dan fisik yang wajar untuk melindungi dari akses, penggunaan, modifikasi, dan pengungkapan data pribadi yang tidak sah dalam kendali dan penyimpanannya. Namun, tidak ada transmisi data melalui Internet atau jaringan nirkabel yang dapat dijamin.</p>

<b>Pengungkapan hukum:</b>
<p style="text-indent: 45px;">Kami akan mengungkapkan informasi apa pun yang kami kumpulkan, gunakan, atau terima jika diperlukan atau diizinkan oleh hukum, seperti untuk mematuhi panggilan pengadilan atau proses hukum serupa, dan ketika kami yakin dengan itikad baik bahwa pengungkapan diperlukan untuk melindungi hak kami, melindungi keselamatan Anda, atau keselamatan orang lain, menyelidiki penipuan, atau menanggapi permintaan pemerintah.</p>

<b>Kontak informasi:</b>
<p style="text-indent: 45px;">Jika Anda ingin menghubungi kami untuk memahami lebih lanjut tentang Kebijakan ini atau ingin menghubungi kami mengenai segala hal yang berkaitan dengan hak individu dan Informasi Pribadi Anda, Anda dapat mengirimkan email ke diskominfokabupaten@gmail.com.</p>
"""

    static var pageHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
          :root { color-scheme: light dark; }
          body {
            font-family: -apple-system, "Work Sans", Helvetica, Arial, sans-serif;
            font-size: 16px;
            line-height: 1.5;
            margin: 0;
            padding: 0;
            color: #1c1c1e;
            text-align: justify;
          }
          @media (prefers-color-scheme: dark) {
            body { color: #f2f2f7; }
          }
          p { margin: 0 0 14px 0; }
          b { font-weight: 600; display: block; margin: 8px 0 4px 0; }
          a { color: #0d175f; }
        </style>
        </head>
        <body>
        \(htmlFragment)
        </body>
        </html>
        """
    }
}

struct PrivacyView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var webHeight: CGFloat = 800

    private let primaryNavy = Color(red: 13/255, green: 23/255, blue: 95/255)

    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                headerBar
                PrivacyHTMLWebView(
                    html: PrivacyContent.pageHTML,
                    colorScheme: colorScheme,
                    contentHeight: $webHeight
                )
                .frame(height: webHeight)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
            }
            Text("Kebijakan Privasi")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(primaryNavy)
                .padding(.top, 48)
        }
    }
}

// MARK: - WKWebView (render HTML + text-indent seperti HtmlCompat)

private struct PrivacyHTMLWebView: UIViewRepresentable {
    let html: String
    let colorScheme: ColorScheme
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.loadedHTML == html,
           context.coordinator.loadedScheme == colorScheme {
            return
        }
        context.coordinator.loadedHTML = html
        context.coordinator.loadedScheme = colorScheme
        webView.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var contentHeight: CGFloat
        var loadedHTML: String?
        var loadedScheme: ColorScheme?

        init(contentHeight: Binding<CGFloat>) {
            _contentHeight = contentHeight
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                guard let self,
                      let number = result as? NSNumber,
                      number.doubleValue > 0 else { return }
                let height = CGFloat(number.doubleValue)
                DispatchQueue.main.async {
                    self.contentHeight = height + 8
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
