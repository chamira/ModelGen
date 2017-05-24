//
//  SwiftBasicProtocolImp.swift
//  ModelGen
//
//  Created by Chamira Fernando on 19/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

struct SwiftBasicProtocol {
    static let list:[SwiftBasicProtocolTemplate] = [SwiftCustomStringConvertible(),SwiftEquatable() /*,SwiftHashable()*/] // Add SwiftHashable if you want to
}

enum SwiftBasicProtocolImpOption {
    case classOrStruct,`extension`
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


struct SwiftCustomStringConvertible : SwiftBasicProtocolTemplate {
    
    var name: String {
        return "CustomStringConvertible"
    }
    
    var implementaionIn: SwiftBasicProtocolImpOption {
        return .classOrStruct
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

/*
 //Example how to add Swift protocol to be a part of auto generation
struct SwiftHashable : SwiftBasicProtocolTemplate {
    
    var name: String {
        return "Hashable"
    }
    
    var implementaionIn: SwiftBasicProtocolImpOption {
        return .classOrStruct
    }
    
    var scope: SwiftBasicProtocolImpScope {
        return .in
    }
    
    func implementationTemplate() -> String {
        return "$indent$$override$var hashValue: Int {\n$indent$$indent$return $properties$\n$indent$}"
    }
    
    //Define How you want hash to be generated
    func propertyStringForEnitity(entity: Entity) -> String {
        
        if entity.isChild {
            return "super.hashValue"
        }
        
        let filteredHashables = entity.attributes.filter { $0.info?.hash.value == true }.filter { $0.dataType.isInt }.map { "\($0.name)" }
        let copy = filteredHashables
        let zipB = zip(filteredHashables, copy)
        let join = zipB.map { "Int(\($0.0)" + " ^ " + "\($0.1))"}
        return join.first ?? "0"
    }
}
*/
