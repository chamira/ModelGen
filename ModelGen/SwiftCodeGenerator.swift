//
//  SwiftCodeGenerator.swift
//  ModelGen
//
//  Created by Chamira Fernando on 16/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

struct SwiftModuler {
    static let list = [
        "UI":"UIKit",
        "CL":"CoreLocation"
    ]
}

class SwiftCodeGenerator : CodeGenerator, CodeGeneratorProtocol {
    
    func getFileConents() -> [EntityFileContentHolder] {
        
        var files:[EntityFileContentHolder] = [EntityFileContentHolder]()
        for entity in entities {
            let str = getEntityString(entity: entity)
            files.append(EntityFileContentHolder(entity: entity, content: str))
        }
        
        return files
    }
    
    
    func getExtensionFileContents() -> [EntityFileContentHolder]? {
        var files:[EntityFileContentHolder] = [EntityFileContentHolder]()
        for entity in entities {
            let str = getEntityExtensionString(entity: entity)
            files.append(EntityFileContentHolder(entity: entity, content: str))
        }
        
        return files

    }
    
    func getEntityExtensionString(entity:Entity) -> String {
        var str = "//\n//\(indentation.value)\(entity.className)+Extension.swift\n" +
            "//\(indentation.value)Created by ModelGen - v\(Config.version)\n" +
        "//\n\n"
        
        str += "extension \(entity.className) {\n"
        str += "\n}\n"
        return str
    }
    
    func getEntityString(entity:Entity)->String {
        
        var str = "//\n//\(indentation.value)\(entity.className).swift\n" +
            "//\(indentation.value)Created by ModelGen - v\(Config.version)\n" +
            "//\(indentation.value)This file was automatically generated and should not be edited.\n" +
        "//\n\n"
        
        str += "\nimport Foundation"
        str += "\n"+getImportLibsForEntity(entity: entity)
        
        str += "class \(entity.className)"
        
        if let _parent = entity.parentName {
            str += " : \(_parent) {\n\n"
        } else {
            str += " {\n\n"
        }
        
        for att in entity.attributes {
            str += getAttributeString(attribute: att)+"\n"
        }
        
        if let initMethod = getInitMethod(entity: entity) {
            str += "\n" + initMethod
        }
        
        str += "\n}\n"
        return str
    }
    
    func getImportLibsForEntity(entity:Entity) -> String {
        var lib:[String] = [String]()
        
        entity.attributes.forEach {
            
            let type = getDataTypeForAttribute(attribute: $0)
                .replacingOccurrences(of: "[", with: ":")
                .replacingOccurrences(of: "]", with: ":")
                .replacingOccurrences(of: "<", with: ":")
                .replacingOccurrences(of: ">", with: ":")
            let subs = type.components(separatedBy: ":")
            
            for each in SwiftModuler.list {
                if libFilter(comps: subs, prefix: each.key) {
                    lib.append("import \(each.value)\n")
                }
            }
        }
        
        return lib.joined(separator: "\n") + "\n"
        
    }
    
    private func libFilter(comps:[String], prefix:String) -> Bool {
        let has = comps.filter { $0.hasPrefix(prefix) }.count
        return has > 0
    }
    
    
    func getAttributeString(attribute:Attribute) ->String {
        
        let _dataType:String = getDataTypeForAttribute(attribute: attribute)
        let _isOpt = attribute.isOptional.value ? "?" : ""
        
        var _default = ""
        if let d = attribute.defaultValue , d.characters.count > 0 {
            _default = " = \(attribute.defaultValue!)"
        }
        
        let access = getAccessControl(accessControl: attribute.info?.access ?? .internal)
        
        let arc = attribute.cocoaARC
        let mutation = attribute.isMutable ? "var" : (attribute.info?.arc == .weak ? "var" :"let")
        
        let str = "\(access) \(arc) \(mutation) \(attribute.name):\(_dataType)\(_isOpt)\(_default)"
        return "\(indentation.value)\(str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))"
        
    }
    
    func getInitMethod(entity:Entity) -> String? {
        
        var nonOptionalAtts:[Attribute] = [Attribute]()
        var superInit = ""
        var superNonOptionalAtts:[Attribute] = [Attribute]()
        
        if let parentEntity = getEntityByName(entityName: entity.parentName) {
            superNonOptionalAtts = parentEntity.attributes.filter { $0.isOptional.value == false || $0.info?.mutable.value == false }
            superNonOptionalAtts.forEach { nonOptionalAtts.append($0) }
            superInit = getSuperInitMethodSignatureForEntity(entity: parentEntity)
        }
        
        let selfNonOptionalAtts = entity.attributes.filter { $0.isOptional.value == false || $0.info?.mutable.value == false }
        selfNonOptionalAtts.forEach { nonOptionalAtts.append($0) }
        
        if (selfNonOptionalAtts.count > 0) {
            
            var attsStr:[String] = [String]()
            var properyStack:[String] = [String]()
            
            for attribute in nonOptionalAtts {
                let _dataType = getDataTypeForAttribute(attribute: attribute)
                let str = "\(attribute.name):\(_dataType)"
                attsStr.append(str)
                
                let contains = superNonOptionalAtts.contains(where: { $0 == attribute })
                
                if (!contains) {
                    let stack = "\(indentation.value)\(indentation.value)self.\(attribute.name) = \(attribute.name)"
                    properyStack.append(stack)
                }
                
            }
            
            if attsStr.count > 0 {
                
                var compArr:[String] = [String]()
                
                let header = "init(\(attsStr.joined(separator: ", "))) {"
                
                compArr.append(indentation.value +  header.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                compArr.append(properyStack.joined(separator: "\n"))
                if (superInit.characters.count > 0) {
                    compArr.append(indentation.value + superInit)
                }
                compArr.append(indentation.value + "}\n")
                
                let str = compArr.joined(separator: "\n")
                return str
            }
        }
        
        return nil
    }
    
    private func getSuperInitMethodSignatureForEntity(entity:Entity) ->String {
        let nonOptionalAtts = entity.attributes.filter { $0.isOptional.value == false }
        
        if (nonOptionalAtts.count > 0) {
            
            var attsStr:[String] = [String]()
            
            for attribute in nonOptionalAtts {
                let str = "\(attribute.name):\(attribute.name)"
                attsStr.append(str)
            }
            
            if attsStr.count > 0 {
                let str = "\(indentation.value)super.init(\(attsStr.joined(separator: ", ")))"
                return str
            }
        }
        
        return ""
        
    }
    
    private func getEntityByName(entityName:String?) -> Entity? {
        return entities.filter { $0.className == entityName }.first
    }
    
    func getDataTypeForAttribute(attribute:Attribute) -> String {
        
        let dataType:DataType = attribute.dataType
        let isScalarValue:Bool = attribute.isScalarValueType.value
        
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
        default:
            if let _ = attribute.customClassName {
                type = attribute.customClassName!
            } else {
                type = "Any"
            }
            
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
