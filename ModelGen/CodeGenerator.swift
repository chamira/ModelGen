//
//  SwiftGenerator.swift
//  ModelGen
//
//  Created by Chamira Fernando on 13/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

protocol CodeGeneratorProtocol {
    func getFileConents() -> [(entityName:String,entityContent:String)]
}

class CodeGenerator {
    
    let entities:[Entity]
    let indentation : GeneratorIndentation
    
    init(entities:[Entity], indent:GeneratorIndentation = .space(count: 4)) {
        self.entities = entities
        self.indentation = indent
    }
    
}

class SwiftCodeGenerator : CodeGenerator, CodeGeneratorProtocol {
    
    func getFileConents() -> [(entityName:String,entityContent:String)] {
        
        var files:[(entityName:String,entityContent:String)] = [(entityName:String,entityContent:String)]()
        for entity in entities {
            let str = getEntityString(entity: entity)
            files.append((entityName: entity.className, entityContent:str))
        }
        
        return files
    }
    
    
    func getEntityString(entity:Entity)->String {
        
        var str = "class \(entity.className)"
        
        if let _parent = entity.parentName {
            str += " : \(_parent) {\n\n"
        } else {
            str += " {\n\n"
        }
        
        for att in entity.attributes {
            str += getAttributeString(attribute: att)+"\n"
        }
        
        str += "\n}\n"
        return str
    }
    
    func getAttributeString(attribute:Attribute) ->String {
        var _dataType:String!
        if attribute.dataType != .transformable {
            _dataType = getGenType(dataType: attribute.dataType, isScalarValue: attribute.isScalarValueType.value)
        } else {
            if let _ = attribute.customClassName {
                _dataType = attribute.customClassName!
            } else {
                _dataType = "Any"
            }
        }
        
        let _isOpt = attribute.isOptional.value ? "?" : ""
        
        var _default = ""
        if let d = attribute.defaultValue , d.characters.count > 0 {
            _default = " = \(attribute.defaultValue!)"
        }
        
        let access = getAccessControl(accessControl: attribute.info?.access ?? .internal)
        
        let arc = attribute.cocoaARC
        let mutation = attribute.isMutable ? "var" : "let"
        
        let str = "\(access) \(arc) \(mutation) \(attribute.name):\(_dataType!)\(_isOpt)\(_default)"
        return "\(indentation.value)\(str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))"
    }
    
    func getGenType (dataType:DataType, isScalarValue:Bool = true) ->String {
        
        var type:String!
        switch dataType {
        case .int16: type = isScalarValue ? "Int16" : "NSNumber"
        case .int32: type = isScalarValue ? "Int32" : "NSNumber"
        case .int64: type = isScalarValue ? "Int64" : "NSNumber"
        case .boolean: type = isScalarValue ? "Bool" : "NSNumber"
        case .double: type = isScalarValue ? "Double" : "NSNumber"
        case .float: type = isScalarValue ? "Float" : "NSNumber"
        case .decimal: type = "NSDecimalNumber"
        case .string: type = "String"
        case .binary: type = "Data"
        case .date: type = "Date"
        default: type = "Transformable"
            
        }
        
        return type
    }
    
    func getAccessControl(accessControl:AccessControlType) ->String {
        switch accessControl {
            case .private:
            return "private"
            case .fileprivate:
            return "fileprivate"
            case .public:
            return "public"
            case .open:
            return "open"
            default:
            return ""
        }
    }

}

class KotlinGenerator : CodeGenerator , CodeGeneratorProtocol {
    
    func getFileConents() -> [(entityName: String, entityContent: String)] {
        var files:[(entityName:String,entityContent:String)] = [(entityName:String,entityContent:String)]()
        for entity in entities {
            let str = "class {}"
            files.append((entityName: entity.className, entityContent:str))
        }
        
        return files
    }
}
