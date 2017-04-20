//
// Created by Lukasz Wroczynski on 14.04.2017.
// Copyright (c) 2017 wroluk. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension Recipe {
    class func create(inContext context: NSManagedObjectContext,
                      _ title: String, _ description: String, _ imageUrl: String, _ ingredients: [String],
                      _ order: Int16) -> Recipe {
        let recipe = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context) as! Recipe
        recipe.title = title
        recipe.fullDescription = description
        recipe.imageUrl = imageUrl
        recipe.setIngredients(from: ingredients)
        recipe.order = order

        return recipe
    }

    func setIngredients(from array: [String]) {
        // we store ingredients in a single string separated by newlines
        ingredients = array.flatMap({$0}).joined(separator: "\n")
    }

    // loads the image from file
    func image() -> UIImage? {
        var image: UIImage? = nil
        if let imagePathUrl = fullImagePath() {
            //print("LOADING IMAGE from \(imagePathUrl.path)")
            image = UIImage(contentsOfFile: imagePathUrl.path)
            if (image == nil) {
                print("Failed to load image!")
            }
        }
        return image
    }

    static let imageBasePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

    func fullImagePath() -> URL? {
        if let fileName = imagePath {
            return URL(fileURLWithPath: Recipe.imageBasePath).appendingPathComponent(fileName)
        }
        return nil
    }

    class func deleteAll(inContext context: NSManagedObjectContext) {
        let fetchAllRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
        do {
            let recipesToDelete = try context.fetch(fetchAllRequest) as! [Recipe]
            for recipe in recipesToDelete {
                // delete fetched image
                if let filePath = recipe.fullImagePath() {
                    try? FileManager.default.removeItem(at: filePath)
                }
                // delete managed object
                context.delete(recipe)
            }
        } catch {
            print("Error deleting all recipies: \(error)")
        }
    }
}
