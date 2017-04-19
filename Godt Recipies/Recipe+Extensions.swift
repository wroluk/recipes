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
        //TODO moze wystaryczy Recipe(context)
        recipe.title = title
        recipe.fullDescription = description
        recipe.imageUrl = imageUrl
        recipe.setIngredients(from: ingredients)
        recipe.order = order

        return recipe
    }

    func setIngredients(from array: [String]) {
        // TODO: could be better encoded
        ingredients = array.flatMap({$0}).joined(separator: "\n")
    }

    func image() -> UIImage? {
        var image: UIImage? = nil
        //TODO store relative path
        if let fileName = imagePath {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let imagePathUrl = URL(fileURLWithPath: documentsPath).appendingPathComponent(fileName)
            print("LOADING IMAGE from \(imagePathUrl.path)")
            image = UIImage(contentsOfFile: imagePathUrl.path)
            if (image == nil) {
                print("ERROR loading image") // TODO error handling
            }
        }
        return image
    }

    //TODO move code here
    func deleteAll() {

    }
}
