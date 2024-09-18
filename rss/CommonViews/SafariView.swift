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
    @Published var htmlContent: String = "Cargando..."
    @Published var imageURL: String? = nil
    @Published var loading: Bool = true
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
                    self.loading = false
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.htmlContent = "No data"
                    self.loading = false
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
                        self.htmlContent = self.cleanMarkdownString(markdown)
                        self.loading = false
                    } catch {
                        // Manejar el error aquí si es necesario
                        print("Error al convertir HTML a Markdown: \(error)")
                        self.htmlContent = "No se pudo convertir el contenido"
                        self.loading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.htmlContent = "No se pudo convertir el contenido"
                    self.loading = false
                }
            }
        }.resume()
    }
    
    private func cleanMarkdownString(_ markdownString: String) -> String {
        // Expresión regular para encontrar [Texto](URL) y []() vacíos
        let linkPattern = "\\[([^\\]]*)\\]\\([^\\)]+\\)|\\[\\]\\([^\\)]+\\)"
        // Expresión regular para encontrar "por [fecha]escrito por [fecha]" o similares
        let datePattern = "por\\s+\\d{2}/\\d{2}/\\d{4}\\s*escrito\\s+por\\s+\\d{2}/\\d{2}/\\d{4}\\d*"

        do {
            // Crear el regex para eliminar los enlaces
            let linkRegex = try NSRegularExpression(pattern: linkPattern)
            var cleanedString = linkRegex.stringByReplacingMatches(in: markdownString, range: NSRange(markdownString.startIndex..., in: markdownString), withTemplate: "")
            
            // Crear el regex para eliminar fechas y textos similares
            let dateRegex = try NSRegularExpression(pattern: datePattern)
            cleanedString = dateRegex.stringByReplacingMatches(in: cleanedString, range: NSRange(cleanedString.startIndex..., in: cleanedString), withTemplate: "")
            
            // Buscar "Powered by:" y eliminar todo lo que venga después
            if let range = cleanedString.range(of: "Powered by:") {
                cleanedString = String(cleanedString[..<range.lowerBound])
            }
            
            return cleanedString
        } catch {
            print("Error al crear el regex: \(error)")
            return markdownString // Si hay un error, devolver la cadena original
        }
    }

}

struct SafariView: View {
    @StateObject private var viewModel: HTMLContentViewModel
    
    init(url: URL, imageURL: String?) {
        _viewModel = StateObject(wrappedValue: HTMLContentViewModel(url: url))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if viewModel.loading {
                    ProgressView("Cargando...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    List {
                        let lines = viewModel.htmlContent.split(separator: "\n")
                        ForEach(lines.indices, id: \.self) { index in
                            let line = String(lines[index])
                            let formattedLine = formatLine(line)
                            Text(formattedLine.text)
                              .font(formattedLine.font)
                              .fixedSize(horizontal: false, vertical: true)
                              .focusable()
                        }
                    } .padding(40)
                }
            }
        }
    }
    
    private func formatLine(_ line: String) -> (text: String, font: Font) {
        let lineFormatted = line.replacingOccurrences(of: "*", with: "")
        if lineFormatted.hasPrefix("# ") {
            var text = lineFormatted.replacingOccurrences(of: "# ", with: "")
            text = text.replacingOccurrences(of: "#", with: "")
            return (String(text), .title) // Títulos principales
        } else if lineFormatted.hasPrefix("## ") {
            var text = lineFormatted.replacingOccurrences(of: "## ", with: "")
            text = text.replacingOccurrences(of: "#", with: "")
            return (String(text), .headline) // Subtítulos
        } else {
            let text = lineFormatted.replacingOccurrences(of: "#", with: "")
            return (text, .body) // Texto normal
        }
    }
}


#if DEBUG
struct SafariView_Previews: PreviewProvider {
    static var previews: some View {
        SafariView(url: URL(string: "https://www.github.com")!)
    }
}
#endif
