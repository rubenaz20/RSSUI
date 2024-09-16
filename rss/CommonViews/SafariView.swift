//
//  SafariView.swift
//  rss
//
//  Created by 谷雷雷 on 2020/6/24.
//  Copyright © 2020 acumen. All rights reserved.
//

import SwiftUI
import Combine
import SwiftHTMLtoMarkdown

class HTMLContentViewModel: ObservableObject {
    @Published var htmlContent: LocalizedStringKey = "Cargando..."
    private var url: URL
    
    init(url: URL) {
        self.url = url
        loadHTMLContent()
    }
    
    private func loadHTMLContent() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.htmlContent = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.htmlContent = "No data"
                }
                return
            }
            
            if let htmlString = String(data: data, encoding: .utf8) {
                
                DispatchQueue.main.async {
                    do {
                        var basicHTML = BasicHTML()
                        basicHTML.rawHTML = htmlString
                        try basicHTML.parse()
                        let markdown = try basicHTML.asMarkdown()
                        self.htmlContent = LocalizedStringKey(markdown)
                    } catch {
                        // Manejar el error aquí si es necesario
                        print("Error al convertir HTML a Markdown: \(error)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.htmlContent = "No se pudo convertir el contenido"
                }
            }
        }.resume()
    }
}

struct SafariView: View {
    @StateObject private var viewModel: HTMLContentViewModel
    
    init(url: URL) {
        _viewModel = StateObject(wrappedValue: HTMLContentViewModel(url: url))
    }

    var body: some View {
        ScrollViewWrapper {
            VStack {
                Text(viewModel.htmlContent)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(Color.white)
            }
            .padding()
        }
        .background(Color.black)
    }
}

struct ScrollViewWrapper<Content: View>: UIViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Remove old hosting view and add a new one to reflect the content update
        let newHostingController = UIHostingController(rootView: content)
        newHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove previous hosted view
        uiView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add the new hosted view
        uiView.addSubview(newHostingController.view)
        
        NSLayoutConstraint.activate([
            newHostingController.view.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
            newHostingController.view.trailingAnchor.constraint(equalTo: uiView.trailingAnchor),
            newHostingController.view.topAnchor.constraint(equalTo: uiView.topAnchor),
            newHostingController.view.bottomAnchor.constraint(equalTo: uiView.bottomAnchor),
            newHostingController.view.widthAnchor.constraint(equalTo: uiView.widthAnchor),
            newHostingController.view.heightAnchor.constraint(greaterThanOrEqualTo: uiView.heightAnchor) // Ensure height is greater
        ])
    }

}


#if DEBUG
struct SafariView_Previews: PreviewProvider {
    static var previews: some View {
        SafariView(url: URL(string: "https://www.github.com")!)
    }
}
#endif
