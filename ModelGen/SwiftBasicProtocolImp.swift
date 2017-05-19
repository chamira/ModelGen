//
//  SwiftBasicProtocolImp.swift
//  ModelGen
//
//  Created by Chamira Fernando on 19/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

struct SwiftBasicProtocol {
    static let list:[SwiftBasicProtocolTemplate] = [SwiftCustomStringConvertible(),SwiftEquatable()]
}

enum SwiftBasicProtocolImpOption {
    case `class`,`extension`
}

enum SwiftBasicProtocolImpScope {
    case `in`,`out`
}

protocol SwiftBasicProtocolTemplate {
    var name:String { get }
    var implementaionIn:SwiftBasicProtocolImpOption { get }
    var scope:SwiftBasicProtocolImpScope { get }
    func implementationTemplate()->String
    func propertyStringForEnitity(entity:Entity)->String
}


struct SwiftCustomStringConvertible : SwiftBasicProtocolTemplate {
    
    var name: String {
        return "CustomStringConvertible"
    }
    
    var implementaionIn: SwiftBasicProtocolImpOption {
        return .class
    }
    
    var scope: SwiftBasicProtocolImpScope {
        return .in
    }
    
    func implementationTemplate() -> String {
        return "$indent$$override$var description: String {\n$indent$$indent$return \"{$entityDesc$ -> $properties$}\"\n$indent$}"
    }
    
    func propertyStringForEnitity(entity: Entity) -> String {
        var list:[String] = [String]()
        for att in entity.attributes {
            var printable:Bool = true
            if let access = att.info?.access {
                if access == .private || access == .fileprivate {
                    printable = false
                }
            }
            
            printable = att.isOptional.value ? false : true
            
            if (printable) {
                
                let a:String!
                if (att.dataType == .string) {
                    a = "\(att.name):" + "\\(" + "\(att.name)" + ")"
                } else {
                    a = "\(att.name):" + "\\(String(describing: " + "\(att.name)" + "))"
                }
                list.append(a)
            }
        }
        return list.joined(separator: ", ")
    }
}

struct SwiftEquatable : SwiftBasicProtocolTemplate {
    
    var name: String {
        return "Equatable"
    }
    
    var implementaionIn: SwiftBasicProtocolImpOption {
        return .extension
    }
    
    var scope: SwiftBasicProtocolImpScope {
        return .out
    }
    
    func implementationTemplate() -> String {
        return "func ==(lhs:$entity$, rhs:$entity$)->Bool {\n$indent$return lhs == rhs \n}"
    }
    
    func propertyStringForEnitity(entity: Entity) -> String {
        return ""
    }
}

extension SwiftBasicProtocolTemplate {
    
    func codeForEnitity(entity:Entity,indent:GeneratorIndentation) -> String {
        
        var override =  ""
        
        if let parent = entity.parentName, parent.characters.count > 0 {
            
            if entity.info.modelType != .struct {
                override =  "override "
            }
            
        }
        
        let replaceable:[String:String] = ["$indent$":indent.value,
                                           "$entityDesc$": "\(entity.className):" + "\\(self)",
                                           "$entity$":entity.className,
                                           "$properties$": propertyStringForEnitity(entity:entity),
                                           "$override$":override]

        return replaceTemplate(template: implementationTemplate(), withValues: replaceable)
        
    }
    
}
