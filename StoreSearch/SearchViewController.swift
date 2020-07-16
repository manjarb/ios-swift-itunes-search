//
//  ViewController.swift
//  StoreSearch
//
//  Created by Varis Darasirikul on 12/7/20.
//  Copyright © 2020 Amusexd. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {

    struct TableView {
        struct CellIdentifiers {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
            static let loadingCell = "LoadingCell"
        }
    }


    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    var dataTask: URLSessionDataTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        tableView.register(UINib(nibName: TableView.CellIdentifiers.searchResultCell, bundle: nil), forCellReuseIdentifier: TableView.CellIdentifiers.searchResultCell)
        tableView.register(UINib(nibName: TableView.CellIdentifiers.nothingFoundCell, bundle: nil), forCellReuseIdentifier: TableView.CellIdentifiers.nothingFoundCell)
        tableView.register(UINib(nibName: TableView.CellIdentifiers.loadingCell, bundle: nil), forCellReuseIdentifier: TableView.CellIdentifiers.loadingCell)
        searchBar.becomeFirstResponder()
    }

    // MARK:- Helper Methods
    func iTunesURL(searchText: String) -> URL {
        let encodedText = searchText.addingPercentEncoding(
            withAllowedCharacters: CharacterSet.urlQueryAllowed)!

        let urlString = String(format:
            "https://itunes.apple.com/search?term=%@", encodedText)
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


    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...",
                                      message: "There was an error accessing the iTunes Store." +
                                          " Please try again.", preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default,
                                   handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }


}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        searchResults = []
//        for i in 0...2 {
//            let searchResult = SearchResult()
//            searchResult.name = String(format:
//                "Fake Result %d for", i)
//            searchResult.artistName = searchBar.text!
//            searchResults.append(searchResult)
//        }
//
//        searchBar.resignFirstResponder()
//
//        hasSearched = true
//        tableView.reloadData()

        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()

            dataTask?.cancel()

            isLoading = true
            tableView.reloadData()

            hasSearched = true
            searchResults = []

            // 1
            let url = iTunesURL(searchText: searchBar.text!)
            // 2
            let session = URLSession.shared
            // 3
            dataTask = session.dataTask(with: url, completionHandler: { data, response, error in
                // 4
                if let error = error as NSError?, error.code == -999 {
                    print("Failure! \(error.localizedDescription)")
                    return
                } else if let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 {
                    if let data = data {
                        self.searchResults = self.parse(data: data)
                        self.searchResults.sort(by: <)
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.tableView.reloadData()
                        }
                        return
                    }

                } else {
                    print("Failure! \(response!)")
                }

                DispatchQueue.main.async {
                    self.hasSearched = false
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.showNetworkError()
                }

            })
            // 5
            dataTask?.resume()

        }

    }

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }


}

extension SearchViewController: UITableViewDelegate,
    UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if isLoading {
                return 1
            } else if !hasSearched {
                return 0
            } else if searchResults.count == 0 {
                return 1
            } else {
                return searchResults.count
            }

        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            if isLoading {
                let cell = tableView.dequeueReusableCell(withIdentifier:
                    TableView.CellIdentifiers.loadingCell, for: indexPath)

                let spinner = cell.viewWithTag(100) as!
                UIActivityIndicatorView
                spinner.startAnimating()
                return cell
            } else if searchResults.count == 0 {

                return tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.nothingFoundCell, for: indexPath)
            }

            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableView.CellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell

            let searchResult = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            if searchResult.artist.isEmpty {
                cell.artistNameLabel.text = "Unknown"
            } else {
                cell.artistNameLabel.text = String(format: "%@ (%@)",
                                                   searchResult.artist, searchResult.type)
            }

            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
            if searchResults.count == 0 || isLoading {
                return nil
            } else {
                return indexPath
            }
        }
}


