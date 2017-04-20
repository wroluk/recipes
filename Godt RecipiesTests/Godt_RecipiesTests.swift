//
//  Godt_RecipiesTests.swift
//  Godt RecipiesTests
//
//  Created by Lukasz Wroczynski on 13.04.2017.
//  Copyright © 2017 wroluk. All rights reserved.
//

import XCTest
@testable import Godt_Recipies

class Godt_RecipiesTests: XCTestCase {

    var provider: RecipesProvider!

    override func setUp() {
        super.setUp()

        // get the managed object context from the AppDelegate
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            XCTFail("Can't access AppDelegate.")
            return
        }
        provider = RecipesProvider(context: appDelegate.persistentContainer.viewContext)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFetch() {
        let fetchExpectation = expectation(description: "Completion is called after fetching is done")
        provider.fetch { fetchedRecipes in
            fetchExpectation.fulfill()
            // TODO check something
        }

        waitForExpectations(timeout: 60)
    }

    func testProcess() {
        let testBundle = Bundle(for: type(of: self));
        let sampleDataUrl = testBundle.url(forResource: "sampleData", withExtension: "json")!;
        let jsonData = try! Data(contentsOf: sampleDataUrl)

        let processedRecipes = provider.processRecipes(from: jsonData)

        XCTAssertNotNil(processedRecipes)

        // the sample file contains 50 recipes
        XCTAssertEqual(50, processedRecipes!.count)

        // check some recipes
        checkRecipe(processedRecipes![0], RecipesProvider.RecipeData(
                title: "Jalapeño-poppers",
                fullDescription: "Herlige små smaksbombe-munnfuller!",
                imageUrl: "https://imbo.vgc.no/users/godt/images/a9afff680e8568b9f4d4d814445cfb8d.jpg?t%5B0%5D=thumbnail%3Awidth%3D490%2Cheight%3D277%2Cfit%3Doutbound&t%5B1%5D=strip&t%5B2%5D=compress%3Alevel%3D75&t%5B3%5D=progressive&accessToken=547e5046b3e443060608e8bcfaee66c44bf752695ec05ade4581965df35e8139",
                ingredients: ["jalapeño", "mozzarella", "eggehvite", "hvetemel", "hvetemel", "maisenna", "bakepulver", "egg", "vann", "fløte", "olje", "aioli", "sriracha", "limesaft"],
                order: 0))

        checkRecipe(processedRecipes![7], RecipesProvider.RecipeData(
                title: "Wonton-suppe",
                fullDescription: "En klar suppe med fylte pastaputer - og mye god smak.",
                imageUrl: "https://imbo.vgc.no/users/godt/images/347a5f6363b09d1b8ae8eebb0dae175b.jpg?t%5B0%5D=thumbnail%3Awidth%3D490%2Cheight%3D277%2Cfit%3Doutbound&t%5B1%5D=strip&t%5B2%5D=compress%3Alevel%3D75&t%5B3%5D=progressive&accessToken=1a8fdab1a2ff952c651d3be45e6832877af4bb1d117f497907a26c3463849b61",
                ingredients: ["kyllingkraft", "sitrongress", "fishsauce", "sukker", "kjøttdeig av svin", "reker", "ingefær", "hvitløksfedd", "vannkastanje", "sesamolje", "egg", "pasta", "vårløk", "pak choy", "koriander", "lime", "salt og nykvernet pepper"],
                order: 7))

    }

    private func checkRecipe(_ found: RecipesProvider.RecipeData, _ expected: RecipesProvider.RecipeData) {
        XCTAssertEqual(expected.title, found.title)
        XCTAssertEqual(expected.fullDescription, found.fullDescription)
        XCTAssertEqual(expected.imageUrl, found.imageUrl)
        XCTAssertEqual(expected.ingredients, found.ingredients)
        XCTAssertEqual(expected.order, found.order)
    }
}
