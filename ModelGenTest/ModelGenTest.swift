//
//  ModelGenTest.swift
//  ModelGenTest
//
//  Created by Chamira Fernando on 15/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import XCTest

class ModelGenTest: XCTestCase {
    
    let consoleIO = ConsoleIO()
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testARGSSeparator() {
        
        do { //Best case
            let expectedDict = ["file":"/file/path/file/name.xcdatamodel",
                            "path":"path/to/generate/mode/classes",
                            "lang":"swift",
                            "help":"false",
                            "version":"false"]
            
            let expected = ConsolOption(dict: expectedDict)
            
            do {
                let bestCase1 = ["./ModelGen","-f","/file/path/file/name.xcdatamodel","-p","path/to/generate/mode/classes","-l","swift"]
                let ret = try consoleIO.argsSeparator(args: bestCase1)
                XCTAssertEqual(ret, expected)
            } catch let e{
                XCTFail(e.localizedDescription)
            }
            
            do {
                let bestCase2 = ["./ModelGen","-p","path/to/generate/mode/classes","-f","/file/path/file/name.xcdatamodel","-l","swift"]
                let ret = try consoleIO.argsSeparator(args: bestCase2)
                XCTAssertEqual(ret, expected)
            } catch let e{
                XCTFail(e.localizedDescription)
            }
            
            do {
                let bestCase3 = ["./ModelGen","-l","swift","-p","path/to/generate/mode/classes","-f","/file/path/file/name.xcdatamodel"]
                let ret = try consoleIO.argsSeparator(args: bestCase3)
                XCTAssertEqual(ret, expected)
            } catch let e{
                XCTFail(e.localizedDescription)
            }

            do {
                let bestCase4 = ["./ModelGen","-l","swift","-f","/file/path/file/name.xcdatamodel","-p","path/to/generate/mode/classes"]
                let ret = try consoleIO.argsSeparator(args: bestCase4)
                XCTAssertEqual(ret, expected)
            } catch let e{
                XCTFail(e.localizedDescription)
            }
        }
        
        do { //worst case
            
            do {
                let worstCase1 = ["./ModelGen"]
                let _ = try consoleIO.argsSeparator(args: worstCase1)
                XCTFail("This can not be passed")
            } catch let e as NSError {
                XCTAssertEqual(e.code, 1)
            }
            
            
            
        }
        
    }
    
}
