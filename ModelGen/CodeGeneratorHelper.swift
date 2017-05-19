//
//  CodeGeneratorHelper.swift
//  ModelGen
//
//  Created by Chamira Fernando on 19/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

func newline() -> String {
    return "\n"
}

func newlines(_ count:Int) -> String {
    if count <= 0 {
        return ""
    }
    
    var str = ""
    
    for _ in 1...count {
        str += "\n"
    }
    
    return str
}

func newline(_ text:String,indent:GeneratorIndentation = .space(count: 0)) -> String {
    return "\n\(indent.value)\(text)"
}

func filepathBuidler(fromFilePath:String) -> String {
    let initialPath = fromFilePath.hasSuffix("/") ? fromFilePath : fromFilePath + "/"
    let filepath = initialPath.hasPrefix("/") ? initialPath : FileManager.default.currentDirectoryPath + "/" + initialPath
    return filepath.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
}

func replaceTemplate(template:String, withValues:[String:String]) -> String {
    var temp = template
    for (k,v) in withValues {
        temp = temp.replacingOccurrences(of: k, with: v)
    }
    return temp
}

func cleanSpaces(codeString:String) -> String {
    let space = "[ ]{2,}"
    let regex = try! NSRegularExpression(pattern: space, options: [])
    let clear = regex.stringByReplacingMatches(in: codeString, options: [], range: NSRange(location: 0, length: codeString.characters.count), withTemplate: " ")
    return clear
}

func cleanNewlines(codeString:String) ->String {
    let newline = "[\n]{3,}"
    let newlinereRegex = try! NSRegularExpression(pattern: newline, options: [])
    let clear = newlinereRegex.stringByReplacingMatches(in: codeString, options: [], range: NSRange(location: 0, length: codeString.characters.count), withTemplate: "\n\n")
    return clear
}
