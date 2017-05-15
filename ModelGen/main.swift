//
//  main.swift
//  ModelGen
//
//  Created by Chamira Fernando on 11/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

struct Config {
    static let version = "0.0.1"
}

class Main {
    
    let consoleIO = ConsoleIO()
    var modelFilePath:String?
    var dirToGenFile:String?
    
    private let xcDataModelExt = "xcdatamodel"
    
    func start() {
        
        let argCount = CommandLine.argc
        
        if (argCount < 2) {
            consoleIO.writeMessage("Not enough params, please read the manual below", to: .error)
            ConsoleIO.printUsage();
            return;
        }
        
        let argument = CommandLine.arguments[1]
        let (option, value) = consoleIO.getOption(argument.substring(from: argument.characters.index(argument.startIndex, offsetBy: 1)))
        
        if (argCount == 2) {
        
            if (option == .version) {
                consoleIO.writeMessage("ModelGen version:\(Config.version)")
            } else if (option == .help) {
                ConsoleIO.printUsage()
            } else {
                ConsoleIO.printUsage()
            }
            return
        }
        
        if (argCount != 3) {
            consoleIO.writeMessage("Must specify -f followed with path to xcdatamodel file", to: .error)
            return;
        }
        
    
        if (option == .file) {
            
            let allGoodWithModelFile = processXCDataModelFile(index: 2)
            if (allGoodWithModelFile) {
                do {
                    let data = try readXCDataModelFile(path: modelFilePath!)
                    let gen = Generator(data)
                    gen.generate()
                } catch let e {
                    consoleIO.writeMessage("Error: \(e.localizedDescription)", to: .error)
                }
                
            }
        }
        
        consoleIO.writeMessage("Argument count: \(argCount) Option: \(option) value: \(value)")
        
    }
    
    private func processXCDataModelFile(index:Int) -> Bool {
        
        modelFilePath = CommandLine.arguments[index].replacingOccurrences(of: "\"", with: "")
        modelFilePath = modelFilePath?.replacingOccurrences(of: "\'", with: "")
        modelFilePath = modelFilePath?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        guard let filePath = modelFilePath, filePath.characters.count != 0 else {
            consoleIO.writeMessage("file path length is Zero(0)", to: .error)
            return false
        }
        
        let pathExt = (filePath as NSString).pathExtension
        if  pathExt != xcDataModelExt {
            consoleIO.writeMessage("Data model file must have extension of \(xcDataModelExt), your file extension is \(pathExt)", to: .error)
            return false
        }
        
        if !FileManager.default.fileExists(atPath: filePath) {
            consoleIO.writeMessage("Data model file does not exist at \(filePath)", to: .error)
            return false
        }
        
        if !FileManager.default.isReadableFile(atPath: filePath) {
            consoleIO.writeMessage("Data model file is not readable \(filePath)", to: .error)
            return false
        }
        
        consoleIO.writeMessage("xcdatamodel file path is \(filePath)")
        return true
    }
    
    private func readXCDataModelFile(path:String) throws -> Data {
        let pathWithContent = path + "/contents"
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: pathWithContent))
            print("data", data)
            return data
        } catch let e  {
            print("error",e)
            throw e
        }
    }
    
}


let process = Main()
process.start()
