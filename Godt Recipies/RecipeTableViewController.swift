//
//  RecipeTableViewController.swift
//  Godt Recipies
//
//  Created by Lukasz Wroczynski on 13.04.2017.
//  Copyright © 2017 wroluk. All rights reserved.
//

import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {

    private let dataProvider = RecipesProvider()

    @IBAction func fetchPressed(_ sender: UIBarButtonItem) {
        //let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        dataProvider.fetch { result in
            print("DONE!")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        initializeFetchedResultsController()

        //TODO test if this works
        if fetchedResultsController.sections?.first?.numberOfObjects == 0 {
            print("FETCHING!")
            dataProvider.fetch { result in
                print("DONE!")
            }
        }

        initializeSearchController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
            // TODO error handling
        }
        return sections[section].numberOfObjects
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeTableViewCell", for: indexPath) as! RecipeTableViewCell

        // Set up the cell
        guard let fetchedObject = self.fetchedResultsController?.object(at: indexPath),
                let recipe = fetchedObject as? Recipe else {
            fatalError("Attempt to configure cell without a managed object")
            // TODO error handling
        }

        cell.titleLabel.text = recipe.title
        cell.shortDescriptionLabel.text = recipe.fullDescription // TODO cut it?

        cell.thumbnailImageView?.image = recipe.image()

        return cell
    }

    //TODO remove this
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//
//        performSegue(withIdentifier: "ShowRecipeDetail", sender: self)
//
//    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowRecipeDetail") {
            // get recipe detail VC
            guard let detailVC = segue.destination as? RecipeDetailViewController else {
                return;
            }

            // get selected recipe
            guard let indexPath = tableView.indexPathForSelectedRow,
                let fetchedObject = self.fetchedResultsController?.object(at: indexPath),
                let recipe = fetchedObject as? Recipe else {
                print("Can't configure detail VC")
                // TODO error handling
                return
            }

            detailVC.recipe = recipe
        }
    }

    // MARK: - Search

    var searchController: UISearchController!
    private var searchString = ""

    private func initializeSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        tableView.tableHeaderView = searchController.searchBar
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        self.definesPresentationContext = true
    }

    public func updateSearchResults(for searchController: UISearchController) {
        let newString = searchController.searchBar.text != nil ? searchController.searchBar.text! : ""
        if (newString != searchString) {
            searchString = newString
            print("Search: \(searchString)")
            initializeFetchedResultsController()
            tableView.reloadData()
        }
    }



    // MARK: - FetchResultsController Delegate

    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!

    func initializeFetchedResultsController() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe") // TODO get name from somewhere
        if !searchString.isEmpty {
            let predicate = NSPredicate(format: "title CONTAINS[cd] %@ || ingredients CONTAINS[cd] %@", searchString, searchString)
            request.predicate = predicate
        }
        let departmentSort = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [departmentSort]

        // TODO get MOC from somewhere
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Can't access AppDelegate.")
            fatalError("Cant access AppDelegate")
        }
        let managedContext = appDelegate.persistentContainer.viewContext

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }

    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}
