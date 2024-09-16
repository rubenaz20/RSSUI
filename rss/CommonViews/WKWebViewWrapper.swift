//
//  WebViewWrapper.swift
//  rss
//
//  Created by 谷雷雷 on 2020/7/21.
//  Copyright © 2020 acumen. All rights reserved.
//

import SwiftUI
import Combine

class WKWebViewModel: ObservableObject {
    
    private var dataSource: RSSItemDataSource
    
    private var cancellable: AnyCancellable? = nil
    
    var isFirst: Bool = true
    
    @Published var didFinishLoading: Bool = false
    @Published var link: String = ""
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var total: Double = 0.0 {
        didSet {
            progressHide = false
        }
    }
    @Published var progress: Double = 0.0 {
        didSet {
            if progress > 0 {
                progressHide = false
            }
        }
    }
    @Published var progressHide: Bool = true
    
    init (rssItem: RSSItem) {
        self.dataSource = DataSourceService.current.rssItem
        self.link = rssItem.url
        self.progress = rssItem.progress
        self.isFirst = true
        cancellable = AnyCancellable(
            $progress.removeDuplicates()
                .debounce(for: 0.1, scheduler: DispatchQueue.main)
                .sink { [weak self] p in
                    let item = self?.dataSource.readObject(rssItem)
                    item?.progress = p
                    self?.dataSource.setUpdateObject(item)
                    _ = self?.dataSource.saveUpdateObject()
        })
        
    }
    
    func apply(progress: Double) {
        guard total != 0 else {
            return
        }
        self.progress = min(max(progress / total, self.progress), 1.0)
    }
}

struct WKWebViewWrapper: View {
    
    @ObservedObject var viewModel: WKWebViewModel

    var body: some View {
        // Convertir el link en una URL
        if let url = URL(string: viewModel.link) {
            SafariView(url: url)
        } else {
            // Manejar el caso donde la URL es inválida
            Text("URL no válida")
                .foregroundColor(.red)
                .padding()
        }
    }
}

struct WebViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        let simple = DataSourceService.current.rssItem.simple()
        return WKWebViewWrapper(viewModel: WKWebViewModel(rssItem: simple!))
    }
}
