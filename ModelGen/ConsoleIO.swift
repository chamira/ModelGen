//
//  ConsoleIO.swift
//  ModelGen
//
//  Created by Chamira Fernando on 12/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

enum OptionType: String {
    case file = "f"
    case genPath = "p"
    case lang = "l"
    case help = "h"
    case version = "v"
    case unknown
    
    init(value: String) {
        switch value {
        case "f": self = .file
        case "p": self = .genPath
        case "l": self = .lang
        case "v": self = .version
        case "h": self = .help
        default: self = .unknown
        }
    }
}


enum OutputType {
    case error
    case standard
}

class ConsoleIO {
    class func printUsage() {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        
        print("usage: ModelGen version \(Config.version)\n")
        print("\(executableName) -f pathToDataModel")
        print("or")
        print("\(executableName) -p pathToDirToGenerateFiles")
        print("or")
        print("\(executableName) -v version")
        print("or")
        print("\(executableName) -h to show usage information")
        print("Type \(executableName) without an option to enter interactive mode.")
    }
    
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\u{001B}[;m\(message)")
        case .error:
            fputs("\u{001B}[0;31m\(message)\n\u{001B}[;m", stderr)
        }
    }
    
    func getOption(_ option: String) -> (option:OptionType, value: String) {
        return (OptionType(value: option), option)
    }
    
    func argsManager(args:[String]) throws ->[String:String] {
        
        let fileIndex = try optionIndexFinder(option: .file, args: args)
        let filePathIndex = fileIndex + 1
        let filePath = args[filePathIndex]
        
        let genIndex = try optionIndexFinder(option: .genPath, args: args)
        let genPathIndex = genIndex + 1
        let genPath = args[genPathIndex]
        
        let langIndex = try optionIndexFinder(option: .lang, args: args)
        let langValueIndex = langIndex + 1
        let lang = args[langValueIndex]
        
        return ["file":filePath,"path":genPath,"lang":lang]
        
    }
    
    private func optionIndexFinder(option:OptionType,args:[String]) throws -> Int {
        guard let index = args.index(of: option.rawValue) else {
            throw NSError(domain: "com.modelGen", code: 1, userInfo: [NSLocalizedDescriptionKey:"\(option.rawValue) option is not available on the args list"])
        }
        
        return index
    }
}
