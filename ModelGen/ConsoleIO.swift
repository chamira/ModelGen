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

struct ConsolOption : Equatable {
    
    let consolValueDictionary:[String:String]
    
    var version:Bool = false
    var help:Bool = false
    var file:String? = nil
    var path:String? = nil
    var lang:SupportLanguage = SupportLanguage(lang: Config.defaultLanguage)
    
    init(dict:[String:String]) {
        consolValueDictionary = dict
        
        version = (dict["version"] == "true")
        help = (dict["help"] == "true")
        
        if let f = dict["file"] {
            file = (f.characters.count > 0 ? f : nil)
        }

        if let p = dict["path"] {
            path = (p.characters.count > 0 ? p : nil)
        }
        
        if let l = dict["lang"] {
            lang = (l.characters.count > 0 ? SupportLanguage(lang:l) : SupportLanguage(lang: Config.defaultLanguage))
        }
    }
    
    static func ==(lhs:ConsolOption, rhs:ConsolOption) -> Bool {
        return (lhs.version == rhs.version) && (lhs.help == rhs.help) &&
            (lhs.file == rhs.file) && (lhs.path == rhs.path) && (lhs.lang == rhs.lang)
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
        print("\(executableName) -l language(swift,java,kotlin)")
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
    
    func argsSeparator(args:[String]) throws -> ConsolOption {
        
        if (args.count == 1) {
            throw NSError(domain: "com.modelGen", code: 1, userInfo: [NSLocalizedDescriptionKey:"Not enough args passed: \(args.count)"])
        }
        
        var filePath:String!
        do {
            let fileIndex = try optionIndexFinder(option: .file, args: args)
            let filePathIndex = fileIndex + 1
            filePath = args[filePathIndex]
        } catch {
            filePath = ""
        }
        
        var genPath:String!
        do {
            let genIndex = try optionIndexFinder(option: .genPath, args: args)
            let genPathIndex = genIndex + 1
            genPath = args[genPathIndex]
        } catch {
            genPath = ""
        }
        
        var lang:String!
        do {
            let langIndex = try optionIndexFinder(option: .lang, args: args)
            let langValueIndex = langIndex + 1
            lang = args[langValueIndex]
        } catch {
            lang = Config.defaultLanguage
        }
        
        var helpText = "false"
        do {
            let _ = try optionIndexFinder(option: .help, args: args)
            helpText = "true"
        } catch {
            helpText = "false"
        }

        var versionText = "false"
        do {
            let _ = try optionIndexFinder(option: .version, args: args)
            versionText = "true"
        } catch {
            helpText = "false"
        }

        let dict = ["file":filePath,"path":genPath,"lang":lang, "help":helpText, "version":versionText]
        let optionSet = ConsolOption(dict: dict as! [String : String])
        return optionSet
        
    }
    
    private func optionIndexFinder(option:OptionType,args:[String]) throws -> Int {
        
        let value = "-"+option.rawValue
        guard let index = args.index(of: value) else {
            throw NSError(domain: "com.modelGen", code: 2, userInfo: [NSLocalizedDescriptionKey:"\(value) option is not available on the args list"])
        }
        
        return index
    }
}
