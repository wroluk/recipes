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

    private var managedContext: NSManagedObjectContext!
    private var dataProvider: RecipesProvider!

    override func viewDidLoad() {
        super.viewDidLoad()

        // get the managed object context from the AppDelegate
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Can't access AppDelegate.") // should not happen
        }
        managedContext = appDelegate.persistentContainer.viewContext

        dataProvider = RecipesProvider(context: managedContext)

        initializeFetchedResultsController()

        initializeSearchController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if fetchedResultsController.sections?.first?.numberOfObjects == 0 {
            fetchRecipes()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Fetching of recipes

    @IBAction func fetchPressed(_ sender: UIBarButtonItem) {
        fetchRecipes()
    }

    private func fetchRecipes() {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        let activityBarItem = UIBarButtonItem(customView: activityIndicator);
        let currentBarItem = navigationItem.rightBarButtonItem
        navigationItem.rightBarButtonItem = activityBarItem;
        activityIndicator.startAnimating()

        dataProvider.fetch { result in
            self.navigationItem.rightBarButtonItem = currentBarItem;
        }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeTableViewCell", for: indexPath) as! RecipeTableViewCell

        // Set up the cell
        guard let fetchedObject = self.fetchedResultsController?.object(at: indexPath),
                let recipe = fetchedObject as? Recipe else {
            fatalError("Failed to obtain managed object!")
        }

        cell.titleLabel.text = recipe.title
        cell.shortDescriptionLabel.text = recipe.fullDescription
        cell.thumbnailImageView?.image = recipe.image()

        return cell
    }


    // MARK: - Navigation

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
            // print("Search: \(searchString)")
            initializeFetchedResultsController()
            tableView.reloadData()
        }
    }


    // MARK: - FetchResultsController Delegate

    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!

    func initializeFetchedResultsController() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
        if !searchString.isEmpty {
            let predicate = NSPredicate(format: "title CONTAINS[cd] %@ || ingredients CONTAINS[cd] %@", searchString, searchString)
            request.predicate = predicate
        }
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to initialize FetchedResultsController: \(error)")
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
