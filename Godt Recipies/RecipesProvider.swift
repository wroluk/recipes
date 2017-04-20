//
// Created by Lukasz Wroczynski on 14.04.2017.
// Copyright (c) 2017 wroluk. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class RecipesProvider {

    init(context: NSManagedObjectContext) {
        managedContext = context
    }

    private var managedContext: NSManagedObjectContext!

    private var fetchCompletion: (([Recipe]?) -> Void)? = nil

    private var fetchedRecipes = [Recipe]()


    // MARK: Fetching of recipes

    func fetch(completion: @escaping ([Recipe]?) -> Void) {
        print("Starting fetch...")

        fetchCompletion = completion

        let url = URL(string: "http://www.godt.no/api/getRecipesListDetailed?tags=&size=thumbnail-medium&ratio=1&limit=50&from=0")!
        let task = URLSession.shared.dataTask(with: url) { [unowned self] (jsonData: Data?, response: URLResponse?, error: Error?) -> Void in
            print("JSON download completion called")

            if jsonData == nil {
                print("JSON download failed: \(error)")
                self.finish(results: nil)
                return
            }

            // process JSON and create Core Data objects
            let recipesData = self.processRecipes(from: jsonData)
            if recipesData == nil {
                // processing downloaded JSON failed
                self.finish(results: nil)
            }

            // store all processed recipes in Core Data
            let result = self.storeRecipes(from: recipesData!)
            if result {
                // trigger image fetching
                if self.fetchedRecipes.isEmpty {
                    self.finish(results: self.fetchedRecipes)
                } else {
                    self.fetchImages()
                }
            } else {
                // storing in Core Data failed
                self.finish(results: nil)
            }

        }
        task.resume()

    }

    private func finish(results: [Recipe]?) {
        // call completion on main thread
        if (fetchCompletion != nil) {
            if Thread.isMainThread {
                print("Calling fetch completion")
                fetchCompletion!(results)
            } else {
                DispatchQueue.main.sync {
                    finish(results: results)
                }
            }
        }
    }

    // MARK: Processing of JSON data

    struct RecipeData {
        let title: String
        let fullDescription: String
        let imageUrl: String
        let ingredients: [String]
        let order: Int16
    }

    func processRecipes(from jsonData: Data?) -> [RecipeData]? {
        guard let data = jsonData,
              let jsonRoot = try? JSONSerialization.jsonObject(with: data, options: []),
              let recipeListJson = jsonRoot as? [Any] else {
            print("Can't deserialize root JSON.")
            return nil
        }

        var processedRecipes = [RecipeData]()

        var recipeNo: Int16 = 0

        for recipeJson in recipeListJson {
            guard let recipeDict = recipeJson as? [String: Any],
                  let title = recipeDict["title"] as? String,
                  let description = recipeDict["description"] as? String,
                  let imageArray = recipeDict["images"] as? [Any],
                  let ingredientsArray = recipeDict["ingredients"] as? [Any]
                    else {
                print("Can't parse recipe JSON.")
                continue // just skip this one
            }

            // image
            guard let imageJson = imageArray.first,
                  let imageDict = imageJson as? [String: Any],
                  let imageUrl = imageDict["url"] as? String
                    else {
                print("Can't parse image JSON.")
                continue // just skip this one
            }

            // ingredients
            var ingredients = [String]()
            for ingredientJson in ingredientsArray {
                guard let ingredientDict = ingredientJson as? [String: Any],
                      let ingredientElementsArray = ingredientDict["elements"] as? [Any]
                        else {
                    print("Can't parse ingredients JSON.")
                    continue // just skip this one
                }

                for ingredientElementJson in ingredientElementsArray {
                    guard let ingredientElementDict = ingredientElementJson as? [String: Any],
                          let ingredientName = ingredientElementDict["name"] as? String
                            else {
                        print("Can't parse ingredient element JSON.")
                        continue // just skip this one
                    }
                    ingredients.append(ingredientName)
                }
            }

            //print("Got recipe: #\(recipeNo): '\(title)'") //, \n '\(description)', \n '\(imageUrl)', \n '\(ingredients)'")

            // convert simple HTML tags from description (like <br>) into text
            let descriptionData = description.data(using: String.Encoding.unicode, allowLossyConversion: true)!
            let attributedDescription = try! NSAttributedString(data: descriptionData,
                    options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
            let processedDescription = attributedDescription.string

            // store recipe
            let recipeData = RecipeData(title: title, fullDescription: processedDescription, imageUrl: imageUrl, ingredients: ingredients, order: recipeNo)
            processedRecipes.append(recipeData)

            recipeNo += 1
            if recipeNo == 50 {
                break; // take 50 only
            }
        }

        print("Processed \(processedRecipes.count) recipes.")
        return processedRecipes
    }

     private func storeRecipes(from dataToStore: [RecipesProvider.RecipeData]) -> Bool {
        var result = true
        self.managedContext.performAndWait { [unowned self] in

            // delete all existing
            Recipe.deleteAll(inContext: self.managedContext)

            self.fetchedRecipes = [Recipe]()
            for recipeData in dataToStore {
                let recipe = Recipe.create(inContext: self.managedContext,
                        recipeData.title, recipeData.fullDescription, recipeData.imageUrl, recipeData.ingredients, recipeData.order)
                self.fetchedRecipes.append(recipe)
            }

            // all recipes processed - save the managed context
            do {
                try self.managedContext.save()
            } catch {
                print("Failed to save context: \(error)")
                result = false
            }
        }
        return result
    }


    // MARK: Fetching of images

    private func fetchImages() {

        imageFetchingStarted()

        for recipe in fetchedRecipes {
            guard let urlString = recipe.imageUrl,
                  let url = URL(string: urlString) else {
                print("Invalid image url for recipe \(recipe.title)")
                imageFetchFinished()
                continue
            }

            let recipeNumber = recipe.order
            //print("Starting download for recipe \(recipeNumber)")

            // download the image
            let task = URLSession.shared.downloadTask(with: url) { [unowned self] (location: URL?, response: URLResponse?, error: Error?) -> Void in
                //print("Download completion called for #: \(recipeNumber)")

                // copy the temp file
                guard let downloadLocation = location else {
                    print("Download failed (no location)")
                    self.imageFetchFinished()
                    return
                }

                let documentsPath = Recipe.imageBasePath
                let fileName = "Recipe-\(recipeNumber).png"
                let imagePathUrl = URL(fileURLWithPath: documentsPath).appendingPathComponent(fileName)
                do {
                    try FileManager.default.moveItem(at: downloadLocation, to: imagePathUrl)
                } catch {
                    print("Moving of image file failed: \(error)")
                    self.imageFetchFinished()
                    return
                }

                // set path to downloaded image in the relevant Recipe object
                self.managedContext.performAndWait { [unowned self] in
                    let fetchRecipeRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
                    fetchRecipeRequest.predicate = NSPredicate(format: "imageUrl == %@", urlString)
                    guard let result = try? self.managedContext.fetch(fetchRecipeRequest),
                          let loadedRecipesArray = result as? [Recipe] else {
                        print("Error loading recipes after image download")
                        self.imageFetchFinished()
                        return
                    }

                    // set local path to image in the recipe
                    for loadedRecipe in loadedRecipesArray {
                        loadedRecipe.imagePath = fileName
                    }

                    do {
                        try self.managedContext.save()
                    } catch {
                        print("Failed to save context: \(error)")
                        self.imageFetchFinished()
                        return
                    }

                    // finished!
                    self.imageFetchFinished()
                }
            }
            task.resume()
        }
    }

    private var leftToFetch = 0

    private func imageFetchingStarted() {
        // sync on the main thread
        if Thread.isMainThread {
            leftToFetch = fetchedRecipes.count
        } else {
            DispatchQueue.main.sync {
                imageFetchingStarted()
            }
        }
    }

    private func imageFetchFinished() {
        // sync on the main thread
        if Thread.isMainThread {
            leftToFetch -= 1
            if leftToFetch == 0 {
                // this was the last one - call overall completion
                finish(results: fetchedRecipes)
            }
        } else {
            DispatchQueue.main.sync {
                imageFetchFinished()
            }
        }
    }

}
