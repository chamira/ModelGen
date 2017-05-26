//
//  ConsoleIO.swift
//  ModelGen
//
//  Created by Chamira Fernando on 12/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

enum OptionType : String, CustomStringConvertible  {
    case file = "f"
    case genPath = "p"
    case lang = "l"
    case indent = "i"
    case help = "h"
    case version = "v"
    case unknown
    
    init(value: String) {
        switch value {
        case "f": self = .file
        case "p": self = .genPath
        case "l": self = .lang
        case "i": self = .indent
        case "v": self = .version
        case "h": self = .help
        default: self = .unknown
        }
    }
    
    var description: String {
        switch self {
        case .file: return "File (xcdatamodel file)"
        case .genPath: return "Path (Place to save generated model files)"
        case .lang: return "Programming language (swift, kotlin or java) default is swift"
        case .indent: return "Indentation (tab/spaces) syntax is 'space:5', default is space:4"
        case .help: return "Print Help text"
        case .version: return "Print version number"
        default : return "unknown"
        }
    }
    
    static func all()->[OptionType] {
        return [.file,.genPath,.lang,.indent,.help,.version]
    }
    
}

struct ConsoleOption : Equatable {
    
    let consoleValueDictionary:[String:String]
    
    var version:Bool = false
    var help:Bool = false
    var file:String? = nil
    var path:String? = nil
    var lang:SupportLanguage
    var indent:GeneratorIndentation = GeneratorIndentation.space(count: 4)
    
    init(dict:[String:String]) throws {
        
        consoleValueDictionary = dict
        
        version = (dict["version"] == "true")
        help = (dict["help"] == "true")
        
        if let f = dict["file"] {
            file = (f.characters.count > 0 ? f : nil)
        }

        if let p = dict["path"] {
            path = (p.characters.count > 0 ? p : nil)
        }
        
        if let l = dict["lang"] {
            
            if (l.characters.count > 0) {
                do {
                    lang = try SupportLanguage(lang: l)
                } catch let e {
                    throw e
                }
            } else {
                lang = try! SupportLanguage(lang: Config.defaultLanguage)
            }
        
        } else {
            lang = try! SupportLanguage(lang: Config.defaultLanguage)
        }
        
        if let i = dict["indent"] {
            let v = (i.characters.count > 0) ? i : Config.defaultIndentation
            do {
                indent = try GeneratorIndentation(value: v)
            } catch let e {
                throw e
            }
        }
        
    }
    
    static func ==(lhs:ConsoleOption, rhs:ConsoleOption) -> Bool {
        return (lhs.version == rhs.version) && (lhs.help == rhs.help) &&
            (lhs.file == rhs.file) && (lhs.path == rhs.path) && (lhs.lang == rhs.lang) &&
            (lhs.indent == rhs.indent)
    }
}



enum ConsoleOutputType {
    case error
    case standard
}


class ConsoleIO {
    class func printUsage() {
        let tab = "\t"
        
        print("\nUsage: ModelGen version \(Config.version)\n")
        print("\(tab) -f pathToDataModel file, must be type of \(Config.xcDataModelExt)")
        print("\(tab) -p pathToDirToGenerateFiles, any writable dir, if not defined gets same dir as the data model file")
        print("\(tab) -l language(swift or java or kotlin), default is \(Config.defaultLanguage)")
        print("\(tab) -i indentation(space or tab) syntax is type:value (space:4), default is \(Config.defaultIndentation)")
        print("\(tab) -v version")
        print("\(tab) -h to show usage information\n")
    
    }
    
    func writeMessage(_ message: String, to: ConsoleOutputType = .standard) {
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
    
    func argsSeparator(args:[String]) throws -> ConsoleOption {
        
        if (args.count == 1) {
            throw NSError(domain: Config.errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey:"Not enough args passed: \(args.count)"])
        }
        
        let file = try getOptionValue(option: .file, args: args, defaultValue: "")
        let genPath = try getOptionValue(option: .genPath, args: args, defaultValue: "")
        let lang = try getOptionValue(option: .lang, args: args, defaultValue: Config.defaultLanguage)
        let indent = try getOptionValue(option: .indent, args: args, defaultValue: Config.defaultIndentation)
        
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

        let dict = ["file":file,"path":genPath,"lang":lang, "indent":indent, "help":helpText, "version":versionText]
        do {
            let optionSet = try ConsoleOption(dict: dict)
            return optionSet
        } catch let e {
            throw e
        }
        
    }
    
    private func getOptionValue(option:OptionType, args:[String], defaultValue:String) throws -> String {
        var value:String!
        do {
            let index = try optionIndexFinder(option: option, args: args)
            value = try getValueForOption(option: option, args: args, index: index + 1)
        } catch let e {
            if isThrowableError(error: e) {
                throw e
            }
            value = ""
        }
        return value
    }
    
    
    private func isThrowableError(error:Error) -> Bool {
        let e = error as NSError
        return e.domain == Config.errorDomain && e.code == ErrorCode.optionValueIsMissing.rawValue
    }
    
    private func getValueForOption(option:OptionType, args:[String], index:Int) throws -> String {
        if !isArgsOutOfBound(args: args, index: index) {
            return args[index]
        } else {
            throw ErrorRegistry.optionValueIsMissing(option: option)
        }
    }
    
    private func isArgsOutOfBound(args:[Any],index:Int) ->Bool{
        return index + 1 > args.count
    }
    
    private func optionIndexFinder(option:OptionType,args:[String]) throws -> Int {
        
        let value = "-"+option.rawValue
        guard let index = args.index(of: value) else {
            throw ErrorRegistry.optionNotAvailable(option: option)
        }
        
        return index
    }
}
