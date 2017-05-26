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
                            "path":"path/to/generate/model/classes",
                            "lang":"swift",
                            "indent":"space:4",
                            "help":"false",
                            "version":"false"]
            
            
            let expected = try! ConsoleOption(dict: expectedDict)
            
            do {
                let bestCase1 = ["./ModelGen","-f","/file/path/file/name.xcdatamodel","-p","path/to/generate/model/classes","-l","swift"]
                let ret = try consoleIO.argsSeparator(args: bestCase1)
                XCTAssertEqual(ret, expected)
            } catch let e{
                XCTFail(e.localizedDescription)
            }
            
            do {
                let bestCase2 = ["./ModelGen","-p","path/to/generate/model/classes","-f","/file/path/file/name.xcdatamodel","-l","swift"]
                let ret = try consoleIO.argsSeparator(args: bestCase2)
                XCTAssertEqual(ret, expected)
            } catch let e{
                XCTFail(e.localizedDescription)
            }
            
            do {
                let bestCase3 = ["./ModelGen","-l","swift","-p","path/to/generate/model/classes","-f","/file/path/file/name.xcdatamodel"]
                let ret = try consoleIO.argsSeparator(args: bestCase3)
                XCTAssertEqual(ret, expected)
            } catch let e{
                XCTFail(e.localizedDescription)
            }

            do {
                let bestCase4 = ["./ModelGen","-l","swift","-f","/file/path/file/name.xcdatamodel","-p","path/to/generate/model/classes"]
                let ret = try consoleIO.argsSeparator(args: bestCase4)
                XCTAssertEqual(ret, expected)
            } catch let e{
                XCTFail(e.localizedDescription)
            }
            
            do {
                let _exp = ["file":"/file/path/file/name.xcdatamodel",
                                    "path":"path/to/generate/model/classes",
                                    "lang":"swift",
                                    "indent":"tab:1",
                                    "help":"true",
                                    "version":"true"]
                
                let _expected = try! ConsoleOption(dict: _exp)
                
                let _case = ["./ModelGen","-l","swift","-f","/file/path/file/name.xcdatamodel","-p","path/to/generate/model/classes", "-i","tab:1","-v","-h"]
                let ret = try consoleIO.argsSeparator(args: _case)
                
                XCTAssertEqual(ret, _expected)
                
            } catch let e{
                XCTFail(e.localizedDescription)
            }
            
        }
        
        do { //worst case
            
            do {
                let _case = ["./ModelGen"]
                let _ = try consoleIO.argsSeparator(args: _case)
                
            } catch let e as NSError {
                XCTAssertEqual(e.code, ErrorCode.notEnoughParamPassed.rawValue)
            }
            
            do {
                let _case = ["./ModelGen","-p","-i","-f"]
                let _ = try consoleIO.argsSeparator(args: _case)
                
            } catch let e as NSError {
                XCTAssertEqual(e.code, ErrorCode.optionValueIsMissing.rawValue)
            }
            
            do {
                let _case = ["./ModelGen","-p","-i","-f","/file/path/file/name.xcdatamodel"]
                let _ = try consoleIO.argsSeparator(args: _case)
                
            } catch let e as NSError {
                XCTAssertEqual(e.code, ErrorCode.notSupportedIndentation.rawValue)
            }
            
        }
        
    }
    
}
