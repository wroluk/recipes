//
// Created by Lukasz Wroczynski on 14.04.2017.
// Copyright (c) 2017 wroluk. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class RecipesProvider {
    //TODO escaping
    func fetch(completion: @escaping ([Recipe]) -> Void) {
        print("Starting fetch...")

        let url = URL(string: "http://www.godt.no/api/getRecipesListDetailed?tags=&size=thumbnail-medium&ratio=1&limit=50&from=0")!
        let task = URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            print("Fetch completion called")

            // TODO get MOC from somewhere
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("Can't access AppDelegate.")
                return
            }
            let container = appDelegate.persistentContainer
//            container.performBackgroundTask() { (context) in

            let context = container.viewContext
            context.performAndWait {
                let recipeArray = self.createRecipes(from: data, in: context)
                // TODO error?
                // TODO weak self?
                // TODO _ for unsused parameters

                // save main MOC
//                container.viewContext.performAndWait {
//                    do {
//                        print("SAVE MAIN")
//                        try container.viewContext.save()
//                    } catch {
//                        // TODO error handling
//                        print("Error saving main MOC")
//                    }
//                }

                // trigger image fetching
                if recipeArray != nil {
                    completion(recipeArray!)
                    self.fetchImages(for: recipeArray!)
                }
            }

        }
        task.resume()

    }

    private func createRecipes(from jsonData: Data?, in managedContext: NSManagedObjectContext) -> [Recipe]? {
        guard let data = jsonData,
              let jsonRoot = try? JSONSerialization.jsonObject(with: data, options: []),
              let recipeListJson = jsonRoot as? [Any] else {
            print("Can't deserialize root JSON.")
            return nil // TODO error handling
        }

        // delete all existing
        let fetchAllRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe") // TODO get name from somewhere
//        let deleteAllRequest = NSBatchDeleteRequest(fetchRequest: fetchAllRequest)
        do {
            print("DELETE fetch MOC")
//            let result = try managedContext.execute(deleteAllRequest)
            let tmpRes = try managedContext.fetch(fetchAllRequest)
            let tmpRecipes = tmpRes as! [Recipe]
            for tmpR in tmpRecipes {
                managedContext.delete(tmpR)
            }
            print("DELETE fetch MOC... done")
        } catch {
            // TODO error handling
            print("Error deleting all recipies")
            return nil
        }
        //TODO should we save?
//        do {
//            print("SAVE fetch MOC")
//            try managedContext.save()
//        } catch {
//            fatalError("Failure to save context: \(error)")
//        }

        var recipeArray = [Recipe]()

        var recipeNo: Int16 = 0

        //TODO take 50 only
        for recipeJson in recipeListJson {
            guard let recipeDict = recipeJson as? [String: Any],
                  let title = recipeDict["title"] as? String,
                  let description = recipeDict["description"] as? String,
                  let imageArray = recipeDict["images"] as? [Any],
                  let ingredientsArray = recipeDict["ingredients"] as? [Any]
                    else {
                print("Can't parse recipe JSON.")
                continue // TODO error handling
            }

            // image
            guard let imageJson = imageArray.first,
                  let imageDict = imageJson as? [String: Any],
                  let imageUrl = imageDict["url"] as? String
                    else {
                print("Can't parse image JSON.")
                continue // TODO error handling
            }

            // ingredients
            var ingredients = [String]()
            for ingredientJson in ingredientsArray {
                guard let ingredientDict = ingredientJson as? [String: Any],
                      let ingredientElementsArray = ingredientDict["elements"] as? [Any]
                        else {
                    print("Can't parse ingredients JSON.")
                    continue // TODO error handling
                }

                for ingredientElementJson in ingredientElementsArray {
                    guard let ingredientElementDict = ingredientElementJson as? [String: Any],
                          let ingredientName = ingredientElementDict["name"] as? String
                            else {
                        print("Can't parse ingredient element JSON.")
                        continue // TODO error handling
                    }
                    ingredients.append(ingredientName)
                }
            }

            print("Got recipe: #\(recipeNo): '\(title)'") //, \n '\(description)', \n '\(imageUrl)', \n '\(ingredients)'")

            let recipe = Recipe.create(inContext: managedContext, title, description, imageUrl, ingredients, recipeNo)
            recipeArray.append(recipe)

            recipeNo += 1
        }

        // all recipes processed - save the managed context
        // TODO if has changes
        do {
            print("SAVE fetch MOC")
            try managedContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }

        print("Created \(recipeArray.count) recipes.")
        return recipeArray
    }

    private func fetchImages(for recipeArray: [Recipe]) {

        for recipe in recipeArray {
            guard let urlString = recipe.imageUrl,
                  let url = URL(string: urlString) else {
                print("Invalid image url for recipe \(recipe.title)")
                continue
            }
            

            let recipeNumber = recipe.order
            print("Starting download for recipe \(recipeNumber)")
            //TODO get moc
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("Can't access AppDelegate.")
                return
            }
            let container = appDelegate.persistentContainer

            let task = URLSession.shared.downloadTask(with: url) { (location: URL?, response: URLResponse?, error: Error?) -> Void in

                print("Download completion called for #: \(recipeNumber)")

                // copy the temp file
                guard let downloadLocation = location else {
                    print("Download failed (no location)")
                    return
                }

                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let fileName = "Recipe-\(recipeNumber).png"
                let imagePathUrl = URL(fileURLWithPath: documentsPath).appendingPathComponent(fileName)
                do {
                    try FileManager.default.moveItem(at: downloadLocation, to: imagePathUrl)
                } catch {

                }

//                container.performBackgroundTask() { (managedContext) in
                let managedContext = container.viewContext
                container.viewContext.performAndWait {

                    let fetchRecipeRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe") // TODO get name from somewhere
                    fetchRecipeRequest.predicate = NSPredicate(format: "imageUrl == %@", urlString)
                    guard let result = try? managedContext.fetch(fetchRecipeRequest),
                          let loadedRecipesArray = result as? [Recipe] else {
                        // TODO error handling
                        print("Error loading recipes after download")
                        return
                    }

                    for loadedRecipe in loadedRecipesArray {
                        print("Download completion for recipe \(loadedRecipe.order) '\(loadedRecipe.title)' called with location \(location)")

                        loadedRecipe.imagePath = fileName
                        print("Saved to \(loadedRecipe.imagePath)")
                    }

                    do {
                        print("SAVE download MOC")
                        try managedContext.save()
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
//                    // save main MOC
//                    container.viewContext.performAndWait {
//                        do {
//                            print("SAVE MAIN")
//                            try container.viewContext.save()
//                        } catch {
//                            // TODO error handling
//                            print("Error saving main MOC")
//                        }
//                    }

                }


            }
            task.resume()
        }
    }


}
