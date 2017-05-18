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
    static let errorDomain = "com.ModelGen"
    static let defaultLanguage = SupportLanguage.swift.rawValue
    static let xcDataModelExt:[String] = ["xcdatamodeld","xcdatamodel"]
    static let defaultIndentation = "space:4"
}

class Main {
    
    let consoleIO = ConsoleIO()
    
    
    
    func start() {
        
        let argCount = CommandLine.argc
        
        if (argCount < 2) {
            consoleIO.writeMessage("Not enough params, please read the manual below", to: .error)
            ConsoleIO.printUsage();
            return;
        }
        
        let argument = CommandLine.arguments[1]
        let (option, _) = consoleIO.getOption(argument.substring(from: argument.characters.index(argument.startIndex, offsetBy: 1)))
        
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
        
        if (argCount < 3) {
            consoleIO.writeMessage("Must specify -f followed with path to xcdatamodel file", to: .error)
            return;
        }
        
        do {
            
            let consoleOption = try consoleIO.argsSeparator(args: CommandLine.arguments)
        
            if consoleOption.version {
                consoleIO.writeMessage("ModelGen version:\(Config.version)")
            }
            
            if consoleOption.help {
                ConsoleIO.printUsage()
            }
            
            let processor = Processor(consoleOption: consoleOption)
            let response = processor.process()
            if response.status == false {
                consoleIO.writeMessage(response.message!, to: response.type!)
            }  else {
                consoleIO.writeMessage(response.message!)
                consoleIO.writeMessage("*** DONE ***\n")
            }
            
        } catch let e {
            consoleIO.writeMessage("Error: \(e.localizedDescription)", to: .error)
        }
        
    }
        
}


let process = Main()
process.start()
