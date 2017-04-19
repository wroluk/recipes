//
//  RecipeDetailViewController.swift
//  Godt Recipies
//
//  Created by Lukasz Wroczynski on 18.04.2017.
//  Copyright © 2017 wroluk. All rights reserved.
//

import UIKit

class RecipeDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var ingredientsLabel: UILabel!

    var recipe: Recipe? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = recipe?.title
        descriptionLabel.text = recipe?.fullDescription //TODO use WebView for description as it contains links and other HTML tags
        ingredientsLabel.text = recipe?.ingredients
        imageView.image = recipe?.image()

        //TODO deregister old
        // the image might not be loaded yet
        if (recipe != nil) {
            recipe!.addObserver(self, forKeyPath: "imagePath", options: [], context: nil)
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (recipe != nil) {
            recipe!.removeObserver(self, forKeyPath: "imagePath")
        }

    }


    override func observeValue(forKeyPath keyPath: String?,
                      of object: Any?,
                      change: [NSKeyValueChangeKey : Any]?,
                      context: UnsafeMutableRawPointer?) {
        guard let recipe = object as? Recipe else {
            return;
        }

        if keyPath == "imagePath" {
            let image = recipe.image()
            //TODO weak self
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
