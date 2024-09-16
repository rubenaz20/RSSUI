//
//  SafariView.swift
//  rss
//
//  Created by 谷雷雷 on 2020/6/24.
//  Copyright © 2020 acumen. All rights reserved.
//

import SwiftUI

struct SafariView: View {
    let url: URL
    @State private var htmlContent: String = "Cargando..."

    var body: some View {
        ScrollView {
            Text(htmlContent)
                .padding()
                .background(Color.black)
                .foregroundColor(Color.white)
        }
        .onAppear {
            loadHTMLContent()
        }
    }

    private func loadHTMLContent() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil {
                // Convertir el HTML en una cadena
                if let htmlString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        htmlContent = htmlString
                    }
                } else {
                    DispatchQueue.main.async {
                        htmlContent = "No se pudo convertir el contenido"
                    }
                }
            } else {
                DispatchQueue.main.async {
                    htmlContent = "Error al cargar el contenido"
                }
            }
        }.resume()
    }
}

#if DEBUG
struct SafariView_Previews: PreviewProvider {
    static var previews: some View {
        SafariView(url: URL(string: "https://www.github.com")!)
    }
}
#endif
