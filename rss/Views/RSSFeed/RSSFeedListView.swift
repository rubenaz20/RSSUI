//
//  RSSItemListView.swift
//  rss
//
//  Created by 谷雷雷 on 2020/6/24.
//  Copyright © 2020 acumen. All rights reserved.
//

import SwiftUI
import FeedKit
import Combine

struct RSSFeedListView: View {
    
    var rssSource: RSS {
        return self.rssFeedViewModel.rss
    }
    
    @EnvironmentObject var rssDataSource: RSSDataSource
    
    @ObservedObject var rssFeedViewModel: RSSFeedViewModel
    
    @State private var selectedItem: RSSItem?
    @State private var start: Int = 0
    @State private var footer: String = "load more"
    @State var cancellables = Set<AnyCancellable>()
    
    init(viewModel: RSSFeedViewModel) {
        self.rssFeedViewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(self.rssFeedViewModel.items, id: \.self) { item in
                    NavigationLink(value: item) {
                        RSSItemRow(wrapper: item, menu: self.contextmenuAction(_:))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.selectedItem = item
                            }
                    }
                }
                VStack(alignment: .center) {
                    Button(action: self.rssFeedViewModel.loadMore) {
                        Text(self.footer)
                    }
                }
            }
            .navigationTitle(rssSource.title)
            .navigationDestination(for: RSSItem.self) { item in
                let imgURL = extractImageSrc(from: item.desc)
                SafariView(url: URL(string: item.url)!, imageURL: imgURL)
            }
            .onAppear {
                self.rssFeedViewModel.fecthResults()
                self.rssFeedViewModel.fetchRemoteRSSItems()
            }
        }
    }
    
    func contextmenuAction(_ item: RSSItem) {
        rssFeedViewModel.archiveOrCancel(item)
    }
    
    private func extractImageSrc(from desc: String) -> String? {
        let srcPattern = "src=\"([^\"]+)\""
        
        do {
            // Crear el regex para encontrar el atributo src
            let regex = try NSRegularExpression(pattern: srcPattern)
            let nsString = desc as NSString
            let results = regex.matches(in: desc, range: NSRange(location: 0, length: nsString.length))
            
            // Obtener el primer resultado del regex
            if let match = results.first {
                // El grupo 1 contiene el valor del atributo src
                let srcRange = match.range(at: 1)
                return nsString.substring(with: srcRange)
            }
            
            return nil
        } catch {
            print("Error al crear el regex: \(error)")
            return nil
        }
    }
}
