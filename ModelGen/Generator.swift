//
//  Generator.swift
//  ModelGen
//
//  Created by Chamira Fernando on 12/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

enum GeneratorIndentation {
    case tab(count:Int)
    case space(count:Int)
    
    var value:String {
        
        var str = ""
        switch self {
            case let .tab (value):
            
                for _ in 1...value {
                    str += "\t"
                }
            
            case let .space (value):
            
                for _ in 1...value {
                    str += " "
                }
        }
        return str
    }
    
}

class Generator {
    
    private let _xmlData:Data
    
    private var _entities:[Entity]?
    let _indentation : GeneratorIndentation
    
    init(_ xmlData:Data, indentation:GeneratorIndentation = GeneratorIndentation.space(count: 4)) {
        _xmlData = xmlData
        _indentation = indentation
    }
    
    
    @discardableResult
    func generate() -> Bool {
        let xml = parse()
        
        if (!validation(xml: xml)) {
            return false
        }
        
        let x = getEntities(xml: xml)
        return true
    }
    
    private func parse () -> XMLIndexer {
     
        let xml = SWXMLHash.parse(_xmlData)
        return xml
        
    }
    
    private func validation(xml:XMLIndexer) -> Bool {
        //TODO:
        guard let genLanguage = xml[kXMLElement.root].element?.attribute(by: "sourceLanguage")?.text else {
            return false
        }
        print(genLanguage)
        return true
    }
    
    private func getEntities(xml:XMLIndexer) -> [Entity]? {
        
        let xmlEntities = xml[kXMLElement.root][kXMLElement.entity]
        
        var entities:[Entity] = [Entity]()
        
        for xmlEntity in xmlEntities {
            
            //each entity must have a name
            if let entityAttributes = xmlEntity.element?.allAttributes {
                
                if let name = entityAttributes[kXMLAttribute.entityName]?.text, name.characters.count > 0  {
                    
                    var clsName = entityAttributes[kXMLAttribute.representedClassName]?.text
                    
                    if clsName == nil || clsName?.characters.count == 0 {
                        clsName = name
                    }
                    
                    let parentName = entityAttributes[kXMLAttribute.parentEntity]?.text
                    let codeType = entityAttributes[kXMLAttribute.codeGenerationType]?.text ?? "class"
                    
                    let fields = xmlEntity[kXMLElement.attribute]
                    var attributes:[Attribute] = [Attribute]()
                    for field in fields {
                        
                        if let fieldAttributes = field.element?.allAttributes {
                            
                            if let attName = fieldAttributes[kXMLAttribute.entityName]?.text, attName.characters.count > 0 {
                                
                                let attType = DataType(value:fieldAttributes[kXMLAttribute.attributeType]?.text ?? kXMLValue.transformable)
                                let attScalarValueType = BoolType(value:fieldAttributes[kXMLAttribute.usesScalarValueType]?.text ?? kXMLValue.yes)
                                let attDefaultValue = fieldAttributes[kXMLAttribute.defaultValueString]?.text ?? ""
                                let attCustomClassName = fieldAttributes[kXMLAttribute.customClassName]?.text
                                let attOptional = BoolType(value:fieldAttributes[kXMLAttribute.optional]?.text ?? kXMLValue.yes)
                                
                                let attribute = Attribute(name: attName, dataType: attType, isOptional: attOptional, isScalarValueType: attScalarValueType, customClassName: attCustomClassName, defaultValue: attDefaultValue)
                                
                            
                                attributes.append(attribute)
                                
                            }
                        }
                        
                        
                    }
                    
                    let entity:Entity = Entity(name: name, className: clsName!, parentName: parentName, codeGenType: CodeGenType(type:codeType), attributes:attributes)
                    
                    entities.append(entity)
                    print(entity.stringRep(indentation: _indentation))
                }
            
            }
            

        }
        
        //print("entities",entities)
        
        return nil
    }
}

enum CodeGenType : String {
    case `class` = "class", category = "category"
    init(type:String) {
        if type.lowercased() == "category" {
            self = .category
        } else {
            self = .class
        }
    }
}

enum BoolType : String {
    case yes = "YES", no = "NO"
    init(value:String) {
        if value.uppercased() == "YES" {
            self = .yes
        } else {
            self = .no
        }
    }
    
    var value:Bool {
        return self == .yes ? true : false
    }
    
}


enum ARCType : String {
    case strong = "strong", weak = "weak"
    init(type:String) {
        if type.lowercased() == "weak" {
            self = .weak
        } else {
            self = .strong
        }
    }
    
    var value:String {
        if self == .weak {
            return "weak"
        } else {
            return ""
        }
    }
}

enum AccessType : String {
    case `private` = "private", `fileprivate` = "fileprivate", `public` = "public", open = "open", `internal` = "internal"
    init(type:String) {
        
        switch type.lowercased() {
        case "private":
            self =  .private
        case "fileprivate":
            self = .fileprivate
        case "public":
            self = .public
        case "open":
            self = .open
        default:
            self = .internal
        }
    }
    
    var value:String {
        switch self {
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

enum DataType : String {

    case int16 = "Integer 16",
         int32 = "Integer 32",
         int64 = "Integer 64",
         decimal = "Decimal",
         double = "Double",
         float = "Float",
         string = "String",
         boolean = "Boolean",
         date = "Date",
         binary = "Binary",
         transformable = "Transformable"
    
    init(value:String) {
        let lValue = value.lowercased()
        
        switch lValue {
        case "integer 16":
            self = .int16
        case "integer 32":
            self = .int32
        case "integer 64":
            self = .int64
        case "decimal":
            self = .decimal
        case "double":
            self = .double
        case "float":
            self = .float
        case "string":
            self = .string
        case "boolean":
            self = .boolean
        case "date":
            self = .date
        case "binary":
            self =  .binary
        default:
            self = .transformable
        }
    }
    
    func getGenType (isScalarValue:Bool = true) ->String {
        
        var type:String!
        switch self {
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
}

struct Entity {
    let name:String
    let className:String
    let parentName:String?
    let codeGenType:CodeGenType
    let attributes:[Attribute]
    
    func stringRep(indentation:GeneratorIndentation = GeneratorIndentation.space(count: 4))->String {
    
        var str = "class \(className)"
        
        if let _parent = parentName {
            str += " : \(_parent) {\n\n"
        } else {
            str += " {\n\n"
        }
        
        for att in attributes {
            str += att.stringRep(indentation: indentation)+"\n"
        }
        
        str += "\n}\n"
        return str
    }
    
}

struct Attribute {
    
    let name:String
    let dataType:DataType
    let isOptional:BoolType
    let isScalarValueType:BoolType
    let customClassName:String?
    let defaultValue:String?
    let info:AttributeInfo? = AttributeInfo.kDefault
    
    func stringRep(indentation:GeneratorIndentation = GeneratorIndentation.space(count: 4))->String {
        
        var _dataType:String!
        if dataType != .transformable {
            _dataType = dataType.getGenType(isScalarValue: isScalarValueType.value)
        } else {
            if let _ = customClassName {
                _dataType = customClassName!
            } else {
                _dataType = "Any"
            }
        }
        
        let _isOpt = isOptional.value ? "?" : ""
        
        var _default = ""
        if let d = defaultValue , d.characters.count > 0 {
            _default = " = \(defaultValue!)"
        }
        
        let access = info?.access.value ?? ""
        let arc = info?.arc.value ?? ""
        let mutation = (info?.mutable.value ?? true ) ? "var" : "let"
        
        let str = "\(indentation.value)\(access) \(arc) \(mutation) \(name):\(_dataType!)\(_isOpt)\(_default)"
        
        return str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
    }
    
}

struct AttributeInfo {
    var arc:ARCType = .strong
    var mutable:BoolType = .yes
    var access:AccessType = .internal
    static let kDefault = AttributeInfo(arc: .strong, mutable: .yes, access: .internal)
}


struct kXMLElement {
    static let root = "model"
    static let entity = "entity"
    static let attribute = "attribute"
}

struct kXMLAttribute {
    static let entityName = "name"
    static let representedClassName = "representedClassName"
    static let parentEntity = "parentEntity"
    static let codeGenerationType = "codeGenerationType"
    static let customClassName = "customClassName"
    static let attributeType = "attributeType"
    static let defaultValueString = "defaultValueString"
    static let usesScalarValueType = "usesScalarValueType"
    static let optional = "optional"
}

struct kXMLValue {
    static let yes = "YES"
    static let no = "NO"
    static let transformable = "Transformable"
}
