//
//  ErrorRegistry.swift
//  ModelGen
//
//  Created by Chamira Fernando on 26/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

enum ErrorCode : Int {
    case notEnoughParamPassed = 1,
    optionNotAvailable,
    fileIO,
    optionValueIsMissing,
    notSupportedLanguage,
    notSupportedIndentation,
    wrongDataModelFileExtension,
    noDataModelIsDefined
}

struct ErrorRegistry {

    static func notEnoughParamPassed(count:Int) -> NSError {
        return NSError(domain: Config.errorDomain, code: ErrorCode.notEnoughParamPassed.rawValue, userInfo: [NSLocalizedDescriptionKey:"Not enough args passed: \(count)"])
    }
    
    static func optionNotAvailable(option:OptionType) -> NSError {
        let value = "-"+option.rawValue
        return NSError(domain:Config.errorDomain, code: ErrorCode.optionNotAvailable.rawValue, userInfo: [NSLocalizedDescriptionKey:"\(value) Option is not available on the args list"])
    }
    
    static func fileIO(errorDesc:String) -> NSError {
        return NSError(domain: Config.errorDomain, code: ErrorCode.fileIO.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDesc])
    }
    
    static func optionValueIsMissing(option:OptionType) -> NSError {
        return NSError(domain: Config.errorDomain, code: ErrorCode.optionValueIsMissing.rawValue, userInfo: [NSLocalizedDescriptionKey:"Commandline option -\(option.rawValue) param is defined but value is missing [-\(option.rawValue) = \(option.description)]"])
    }
    
    static func notSupportedLanguage(lang:String) -> NSError {
        return NSError(domain: Config.errorDomain, code: ErrorCode.notSupportedLanguage.rawValue, userInfo: [NSLocalizedDescriptionKey: "Language \(lang) is not supported"])
    }

    static func notSupportedIndentation(value:String) -> NSError {
        return NSError(domain: Config.errorDomain, code: ErrorCode.notSupportedIndentation.rawValue, userInfo: [NSLocalizedDescriptionKey: "\(value) is not supported indentation option, read the user manual"])
    }
    
    static func wrongDataModelFileExtension(value:String) -> NSError {
        return NSError(domain: Config.errorDomain, code: ErrorCode.wrongDataModelFileExtension.rawValue, userInfo: [NSLocalizedDescriptionKey:"Data model file must have extension of \(Config.xcDataModelExt.joined(separator: ", ")), your file extension is \(value)"])
    }
    
    static func noDataModelIsDefined() -> NSError {
        return NSError(domain: Config.errorDomain, code: ErrorCode.noDataModelIsDefined.rawValue, userInfo: [NSLocalizedDescriptionKey:"No data model file is defined"])
    }
}
