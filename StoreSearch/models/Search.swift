//
//  Search.swift
//  StoreSearch
//
//  Created by Varis Darasirikul on 26/7/20.
//  Copyright © 2020 Amusexd. All rights reserved.
//

import Foundation

typealias SearchComplete = (Bool) -> Void

class Search {

    enum Category: Int {
        case all = 0
        case music = 1
        case software = 2
        case ebooks = 3

        var type: String {
            switch self {
            case .all: return ""
            case .music: return "musicTrack"
            case .software: return "software"
            case .ebooks: return "ebook"
            }
        }

    }


    // Old state
//    var searchResults: [SearchResult] = []
//    var hasSearched = false
//    var isLoading = false
    enum State {
        case notSearchedYet
        case loading
        case noResults
        case results([SearchResult])
    }

    private(set) var state: State = .notSearchedYet

    private var dataTask: URLSessionDataTask? = nil

    func performSearch(for text: String, category: Category, completion: @escaping SearchComplete) {
        print("Searching...")

        if !text.isEmpty {
            // searchBar.resignFirstResponder()

            dataTask?.cancel()
//            Old state
//            isLoading = true
//            hasSearched = true
//            searchResults = []
            state = .loading

            // 1
            let url = iTunesURL(searchText: text, category: category)
            // 2
            let session = URLSession.shared
            // 3
            dataTask = session.dataTask(with: url, completionHandler: {
                data, response, error in
                // 4
                var newState = State.notSearchedYet
                var success = false
                if let error = error as NSError?, error.code == -999 {
                    print("Failure! \(error.localizedDescription)")
                    return
                } else if let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 {
                    if let data = data {
//                        self.searchResults = self.parse(data: data)
//                        self.searchResults.sort(by: <)
//                        self.isLoading = false
//                        success = true

                        var searchResults = self.parse(data: data)
                        if searchResults.isEmpty {
                            newState = .noResults
                        } else {
                            searchResults.sort(by: <)
                            newState = .results(searchResults)
                        }
                        success = true

                    }

//                    if !success {
//                        self.hasSearched = false
//                        self.isLoading = false
//                    }

                }

                DispatchQueue.main.async {
                    self.state = newState
                    completion(success)
                }
            })
            // 5
            dataTask?.resume()

        }
    }

    // MARK:- Helper Methods
    func iTunesURL(searchText: String, category: Category) -> URL {
        let kind = category.type

        let encodedText = searchText.addingPercentEncoding(
            withAllowedCharacters: CharacterSet.urlQueryAllowed)!

        let urlString = "https://itunes.apple.com/search?" +
            "term=\(encodedText)&limit=200&entity=\(kind)"

        let url = URL(string: urlString)
        return url!
    }

    func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            return result.results
        } catch {
            print("JSON Error: \(error)")
            return []
        }
    }
}
