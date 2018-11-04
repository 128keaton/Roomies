//
//  UserSearchViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CodableFirebase

class UserSearchViewController: UITableViewController {
    let searchController = UISearchController(searchResultsController: nil)
    var filteredUsers: [[String: String]] = []
    var delegate: UserSearchViewControllerDelegate? = nil
    var currentUserIDs: [String] = []

    func presentSelfIn(viewController: UIViewController) {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.definesPresentationContext = true

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Roommates"
        self.tableView.tableHeaderView = searchController.searchBar

        navigationController.navigationItem.searchController = searchController
        navigationController.navigationBar.topItem?.title = "Add a Roommate"

        addDismissButton(navigationController: navigationController)

        viewController.present(navigationController, animated: true, completion: nil)
    }

    func addDismissButton(navigationController: UINavigationController) {
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(UserSearchViewController.dismissSelf))
        navigationController.navigationBar.topItem!.setRightBarButton(dismissButton, animated: true)
    }

    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        definesPresentationContext = true
    }

    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }

    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        Firestore.firestore().collection("users").whereField("fullName", isGreaterThanOrEqualTo: searchText).getDocuments { (snapshot, error) in
            self.filteredUsers = []
            if let snapshot = snapshot {

                for document in snapshot.documents {
                    let data = document.data()
                    let userID = data["userID"]! as! String

                    if(!self.currentUserIDs.contains(userID)) {
                        let searchQuery = data["fullName"] ?? data["emailAddress"]
                        let baseSearchUser = ["query": searchQuery, "userID": userID]
                        self.filteredUsers.append(baseSearchUser as! [String: String])
                    }
                }

                self.tableView.reloadData()
            }
        }
    }

    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() && filteredUsers.count > 0{
            self.tableView.backgroundView = nil
            return filteredUsers.count
        }else if filteredUsers.count == 0 && isFiltering(){
            TableViewHelper.emptyMessage(message: "No users found", viewController: self)
            return 0
        }
        
        TableViewHelper.emptyMessage(message: "Please start typing to search", viewController: self)
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        if isFiltering() {
            cell.textLabel!.text = filteredUsers[indexPath.row]["query"]
        }

        return cell
    }

    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFiltering() {
            self.dismiss(animated: true, completion: nil)
            self.delegate?.didSelectUser(userID: filteredUsers[indexPath.row]["userID"]!, fullName: filteredUsers[indexPath.row]["query"]!)
            self.dismiss(animated: true, completion: nil)
        }
    }


}

extension UserSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if(searchController.isActive) {
            filterContentForSearchText(searchController.searchBar.text!)
        }
    }
}

protocol UserSearchViewControllerDelegate {
    func didSelectUser(userID: String, fullName: String)
}
