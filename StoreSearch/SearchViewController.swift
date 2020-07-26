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

    private let search = Search()

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        print("segmentChangedsegmentChanged")
        performSearch()
    }

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
            if case .results(let list) = search.state {
                let detailViewController = segue.destination
                as! DetailViewController
                let indexPath = sender as! IndexPath
                let searchResult = list[indexPath.row]
                detailViewController.searchResult = searchResult
            }

        }
    }


}

extension SearchViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    func performSearch() {
        if let category = Search.Category(rawValue: segmentedControl.selectedSegmentIndex) {
            search.performSearch(for: searchBar.text!, category: category, completion: { success in
                if !success {
                    self.showNetworkError()
                }
                self.tableView.reloadData()
            })
        }

        tableView.reloadData()
        searchBar.resignFirstResponder()
    }

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }


}

extension SearchViewController: UITableViewDelegate,
    UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//            if search.isLoading {
//                return 1
//            } else if !search.hasSearched {
//                return 0
//            } else if search.searchResults.count == 0 {
//                return 1
//            } else {
//                return search.searchResults.count
//            }
//
            switch search.state {
            case .notSearchedYet:
                return 0
            case .loading:
                return 1
            case .noResults:
                return 1
            case .results(let list):
                return list.count
            }



        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            switch search.state {
            case .notSearchedYet:
                fatalError("Should never get here")

            case .loading:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: TableView.CellIdentifiers.loadingCell,
                    for: indexPath)

                let spinner = cell.viewWithTag(100) as!
                UIActivityIndicatorView
                spinner.startAnimating()
                return cell

            case .noResults:
                return tableView.dequeueReusableCell(
                    withIdentifier: TableView.CellIdentifiers.nothingFoundCell,
                    for: indexPath)

            case .results(let list):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: TableView.CellIdentifiers.searchResultCell,
                    for: indexPath) as! SearchResultCell

                let searchResult = list[indexPath.row]
                cell.configure(for: searchResult)
                return cell
            }

        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            performSegue(withIdentifier: "ShowDetail", sender: indexPath)
        }

        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
            switch search.state {
            case .notSearchedYet, .loading, .noResults:
                return nil
            case .results:
                return indexPath
            }


        }
}


