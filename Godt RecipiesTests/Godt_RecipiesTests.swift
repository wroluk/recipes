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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFetch() {
        let provider = RecipesProvider()
        // TODO name the exp
        let fetchExpectation = expectation(description: "SomeService does stuff and runs the callback closure")
        provider.fetch { result in
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
