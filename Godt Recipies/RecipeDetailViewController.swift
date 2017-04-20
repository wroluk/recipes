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

    let imagePathKeyPath = "imagePath"

    var recipe: Recipe? = nil {
        didSet {
            // the image might not be downloaded - listen to change of imagePath
            if (oldValue != nil) {
                unregisterKVO(oldValue!)
            }
            if (recipe != nil) {
                registerKVO(recipe!)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = recipe?.title
        descriptionLabel.text = recipe?.fullDescription
        ingredientsLabel.text = recipe?.ingredients
        imageView.image = recipe?.image()
    }

    deinit {
        // stop listening on image path change
        if (recipe != nil) {
            unregisterKVO(recipe!)
        }
    }

    // MARK: KVO for image downloading

    private func registerKVO(_ object: Recipe) {
        object.addObserver(self, forKeyPath: imagePathKeyPath, options: [], context: nil)
    }

    private func unregisterKVO(_ object: Recipe) {
        object.removeObserver(self, forKeyPath: imagePathKeyPath)
    }

    override func observeValue(forKeyPath keyPath: String?,
                      of object: Any?,
                      change: [NSKeyValueChangeKey : Any]?,
                      context: UnsafeMutableRawPointer?) {
        guard let recipe = object as? Recipe else {
            return;
        }

        if keyPath == imagePathKeyPath {
            let image = recipe.image()
            DispatchQueue.main.async { [unowned self] in
                self.imageView.image = image
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
