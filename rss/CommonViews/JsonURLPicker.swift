//
//  DocumentPicker.swift
//  rss
//
//  Created by 谷雷雷 on 2020/8/6.
//  Copyright © 2020 acumen. All rights reserved.
//

import SwiftUI

class JsonURLPickerViewModel: ObservableObject {
    @Published var jsonURL: URL?
    @Published var inputURL: String = ""
    @Published var showingAlert: Bool = false
    
    func submitURL() {
        if let url = URL(string: inputURL), UIApplication.shared.canOpenURL(url) {
            jsonURL = url
        } else {
            showingAlert = true
        }
    }
}


struct JsonURLPicker: View {
    @ObservedObject var viewModel: JsonURLPickerViewModel
    
    var body: some View {
        VStack {
            Text("Enter URL:")
                .font(.title)
                .padding()
            
            TextField("https://www.example.com", text: $viewModel.inputURL)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            
            Button(action: {
                viewModel.submitURL()
            }) {
                Text("Submit")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
            
            if viewModel.jsonURL != nil {
                Text("URL entered: \(viewModel.jsonURL!)")
                    .padding()
            }
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text("Invalid URL"), message: Text("The URL you entered is not valid. Please try again."), dismissButton: .default(Text("OK")))
        }
        .padding()
    }
}

struct DocumentPicker_Previews: PreviewProvider {
    static var previews: some View {
        JsonURLPicker(viewModel: JsonURLPickerViewModel())
    }
}
