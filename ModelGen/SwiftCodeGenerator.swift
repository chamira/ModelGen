//
//  SwiftCodeGenerator.swift
//  ModelGen
//
//  Created by Chamira Fernando on 16/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation


// This is swift specific generator

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
            files.append(EntityFileContentHolder(entity: entity, fileName:entity.className, content: str))
        }
        
        return files
    }
    
    func getExtensionFileContents() -> [EntityFileContentHolder]? {
        var files:[EntityFileContentHolder] = [EntityFileContentHolder]()
        for entity in entities {
            let str = getEntityExtensionString(entity: entity)
            files.append(EntityFileContentHolder(entity: entity, fileName:entity.className + "+Extension", content: str))
        }
        
        return files
    }
    
    //Entry point of generating class or struct.
    func getEntityString(entity:Entity)->String {
        
        var str = fileHeader(fileName: entity.className, language: .swift)

        str += newline("import Foundation")
        str += getImportLibsForEntity(entity: entity)
        
        if (entity.info.modelType == .struct) {
            str += getStructEntity(entity: entity)
        } else {
            str += getClassEntity(entity: entity)
        }
        
        return str
    }
    
    //Swift extension syntax
    func getEntityExtensionString(entity:Entity) -> String {
        
        var str = fileHeader(fileName: entity.className + "Extension", language: .swift, showWarning: false)
        
        let basicProtocolList = SwiftBasicProtocol.list.filter { $0.implementaionIn == .extension }
        
        for item  in  basicProtocolList {
            
            var extend = ""
        
            if entity.info.modelType == .struct || !entity.isChild {
                extend = " : " + item.name
            }
            
            if item.scope == .in {
                str += newline("extension \(entity.className)\(extend) {")
                str += newline(item.codeForEnitity(entity: entity, indent: indentation))
                str += newline("}") + newline()
            } else {
                str += newline(item.codeForEnitity(entity: entity, indent: indentation))
            }
            
            str += newline()
        }
       
        
        str += newline("extension \(entity.className) {")
        str += newline("}") + newline()
        return str.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    //Returns entity as a struct
    func getStructEntity(entity:Entity) -> String {
        var str = "struct \(entity.className) { " + newline()
        
        for att in entity.attributes {
            str += newline(getAttributeString(attribute: att))
        }
        
        str += newline()
        str += newline("}")
        str += newline()
        return str

    }
    
    func getSwiftClassTemplate(forEntity:Entity) -> String {
        if (forEntity.isChild) {
            return "class $className$ : $parentName$ {\n\n$propertyStack$$initStack$$methodStack$\n\n}\n"
        } else {
            return "class $className$ : $protocolStack$ {\n\n$propertyStack$$initStack$$methodStack$\n\n}\n"
        }
    }
    
    //Transform entity object to class string.
    func getClassEntity(entity:Entity) -> String {
    
        var hasParent:Bool
        var replaceDict:[String:String] = [:]
        
        replaceDict["$className$"] = entity.className
        replaceDict["$indent$"] = indentation.value
        
        //Entity has a parent
        if let _parent = entity.parentName {
            hasParent = true
            replaceDict["$parentName$"] = _parent
        } else {
            hasParent = false
        }
        
        var properies:[String] = [String]()
        for att in entity.attributes {
            properies.append(getAttributeString(attribute: att))
        }

        replaceDict["$propertyStack$"] = properies.joined(separator: newline())
        
        //initMethod
        if let initMethod = getInitMethod(entity: entity) {
            replaceDict["$initStack$"] = newline(initMethod)
        } else {
             replaceDict["$initStack$"] = ""
        }
        
        //Logic: 
        //Protocols can be implemetned in class/struct or an extension
        //Since this is a class imp, filter protocols that should be imp in this class.
        //If Entity is a parent class, even though imp happens in extension still the declaration of the protocol stack must be added($protocolStack$)
        var protocolsStackGen:[SwiftBasicProtocolTemplate]
        if entity.isChild {
            protocolsStackGen = SwiftBasicProtocol.list.filter{ $0.implementaionIn == .classOrStruct }
        } else {
            protocolsStackGen = SwiftBasicProtocol.list
        }
        
        let protocolNames = protocolsStackGen.map { $0.name }
    
        let protoclStack = protocolNames.joined(separator: ", ")
        
        if !hasParent {
            replaceDict["$protocolStack$"] = protoclStack
        } else {
            replaceDict["$protocolStack$"] = ""
        }
        
        let protocols = SwiftBasicProtocol.list.filter{ $0.implementaionIn == .classOrStruct }
        //Add Swift basic protocols
        var methodStack = [String]()
        for eachImp in  protocols {
            let str = newline(eachImp.codeForEnitity(entity: entity, indent: indentation))
            methodStack.append(str)
         }

        replaceDict["$methodStack$"] = newline(newline(methodStack.joined(separator: newline())))
        let temp = replaceTemplate(template: getSwiftClassTemplate(forEntity: entity), withValues: replaceDict)
        return cleanNewlines(codeString: temp)
        
    }
    
    //This mothod is import lib defines in SwiftModuler.list
    func getImportLibsForEntity(entity:Entity) -> String {
        var lib:[String] = [String]()
        
        let rDict:[String:String] = ["[":":","]":":","<":":",">":":","{":":","}":":"]
        
        let libFilter:([String],String)->Bool = { (comps, prefix) in
            let has = comps.filter { $0.hasPrefix(prefix) }.count
            return has > 0
        }
        
        entity.attributes.forEach {
            
            let type = getDataTypeForAttribute(attribute: $0)
            let replaced = replaceTemplate(template: type, withValues: rDict)
            let subs = replaced.components(separatedBy: ":")
            
            for each in SwiftModuler.list {
                if libFilter(subs,each.key) {
                    lib.append(newline("import \(each.value)"))
                }
            }
        }
        
        return lib.joined(separator: newline()) + newlines(2)
        
    }

    //Returns Object property(attributes) with type example var username:String? or let images:[UIImage]? ...
    func getAttributeString(attribute:Attribute) ->String {
        
        let _dataType:String = getDataTypeForAttribute(attribute: attribute)
        let _isOpt = attribute.isOptional.value ? "?" : ""
        
        var _default = ""
        if let d = attribute.defaultValue , d.characters.count > 0 {
            _default = " = \(attribute.defaultValue!)"
        }
        
        let access = getAccessControl(accessControl: attribute.info?.access ?? .internal)
        
        let arc = attribute.cocoaARC.characters.count > 0 ?  " " + attribute.cocoaARC : ""
        let mutation = attribute.isMutable ? "var" : (attribute.info?.arc == .weak ? "var" :"let")
        
        let str = "\(access)\(arc) \(mutation) \(attribute.name):\(_dataType)\(_isOpt)\(_default)"
        return "\(indentation.value)\(cleanSpaces(codeString: str.trimmingCharacters(in: CharacterSet.whitespaces)))"
        
    }
    
    
    //Returns init method string rep
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
                
                let header = newline("\(indentation.value)init(\(attsStr.joined(separator: ", "))) {")
                
                compArr.append(indentation.value +  header.trimmingCharacters(in: CharacterSet.whitespaces))
                compArr.append(properyStack.joined(separator: newline()))
                
                if (superInit.characters.count > 0) {
                    compArr.append(indentation.value + superInit)
                }
                compArr.append(indentation.value + "}" + newline())
                
                let str = compArr.joined(separator: newline())
                return str
            }
        }
        
        return nil
    }
    
    //Returns super init method declaration
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
