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
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        print("segmentChangedsegmentChanged")
        performSearch()
    }


    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    var dataTask: URLSessionDataTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        tableView.register(UINib(nibName: TableView.CellIdentifiers.searchResultCell, bundle: nil), forCellReuseIdentifier: TableView.CellIdentifiers.searchResultCell)
        tableView.register(UINib(nibName: TableView.CellIdentifiers.nothingFoundCell, bundle: nil), forCellReuseIdentifier: TableView.CellIdentifiers.nothingFoundCell)
        tableView.register(UINib(nibName: TableView.CellIdentifiers.loadingCell, bundle: nil), forCellReuseIdentifier: TableView.CellIdentifiers.loadingCell)
        searchBar.becomeFirstResponder()

        // Style segment control
        let segmentColor = UIColor(red: 10 / 255, green: 80 / 255, blue: 80 / 255, alpha: 1)
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let normalTextAttributes = [NSAttributedString.Key.foregroundColor: segmentColor]
        segmentedControl.selectedSegmentTintColor = segmentColor
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .highlighted)

    }

    // MARK:- Helper Methods
    func iTunesURL(searchText: String, category: Int) -> URL {
        let kind: String
        switch category {
        case 1: kind = "musicTrack"
        case 2: kind = "software"
        case 3: kind = "ebook"
        default: kind = ""
        }

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


    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...",
                                      message: "There was an error accessing the iTunes Store." +
                                          " Please try again.", preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default,
                                   handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    // MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destination
            as! DetailViewController
            let indexPath = sender as! IndexPath
            let searchResult = searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }


}

extension SearchViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    func performSearch() {
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()

            dataTask?.cancel()

            isLoading = true
            tableView.reloadData()

            hasSearched = true
            searchResults = []

            // 1
            let url = iTunesURL(searchText: searchBar.text!, category: segmentedControl.selectedSegmentIndex)
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
            cell.configure(for: searchResult)

            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            performSegue(withIdentifier: "ShowDetail", sender: indexPath)
        }

        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
            if searchResults.count == 0 || isLoading {
                return nil
            } else {
                return indexPath
            }
        }
}


