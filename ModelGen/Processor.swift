//
//  Generator.swift
//  ModelGen
//
//  Created by Chamira Fernando on 12/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

enum SupportLanguage :String {
    
    case swift = "swift"
    case kotlin = "kotlin"
    case java = "java"
    
    init(lang:String) throws {
        switch lang.lowercased() {
        case "kotlin":
            self = .kotlin
        case "java":
            self = .java
        case "swift":
            self = .swift
        default:
            throw NSError(domain: Config.errorDomain, code: 5, userInfo: [NSLocalizedDescriptionKey: "Language \(lang) is not supported"])
        }
    }
    
    var `extension`:String {
        switch self {
        case .kotlin:
            return "kotlin"
        case .java:
            return "java"
        case .swift:
            return "swift"
        }
    }
}

enum GeneratorIndentation : Equatable {
    case tab(count:Int)
    case space(count:Int)
    
    var value:String {
        
        var str = ""
        switch self {
            case let .tab (c):
                if (c <= 0) {
                    return ""
                }
                for _ in 1...c {
                    str += "\t"
                }
            
            case let .space (c):
                if (c <= 0) {
                    return ""
                }
                for _ in 1...c {
                    str += " "
                }
        }
        return str
    }
    
    init(value:String) throws {
        
        if (value.characters.count == 0 ) {
            self = .space(count: 4)
        } else {
            
            let sep = value.components(separatedBy: ":")
            if (sep.count == 2) {
                
                if let type = sep.first?.lowercased(), let count = Int(sep[1]) {
                    if type == "tab" || type == "tabs" {
                        self = .tab(count: count)
                    } else if type == "space" || type == "spaces" {
                        self = .space(count: count)
                    } else {
                         throw GeneratorIndentation.throwableError(value: value)
                    }
                } else {
                    throw GeneratorIndentation.throwableError(value: value)
                }
                
            } else {
                 throw GeneratorIndentation.throwableError(value: value)
            }
        }
            
    }
    
    static func ==(lhs:GeneratorIndentation, rhs:GeneratorIndentation) -> Bool {
        return lhs.value == rhs.value
    }
    
    static func throwableError(value:String) -> NSError {
        return  NSError(domain: Config.errorDomain, code: 6, userInfo: [NSLocalizedDescriptionKey: "\(value) is not supported indentation option, read the user manual"])
    }
}

class Processor {
    
    private var _xmlData:Data!

    var indentation : GeneratorIndentation!
    var language:SupportLanguage
    let consoleOption:ConsoleOption
    
    init(consoleOption:ConsoleOption) {
        self.consoleOption = consoleOption
        self.language = consoleOption.lang
        self.indentation = consoleOption.indent
    }
    
    func process() -> (status:Bool,message:String?, type:ConsoleOutputType?){
     
        guard let file = consoleOption.file else {
            return (false, "No model file is defined", .error)
        }
        
        let ret:(status:Bool,cleanFilePath:String?) = processXCDataModelFile(modelFile: file)
        
        guard ret.status == true else {
            return (false, ret.cleanFilePath!, .error)
        }
        
        do {
            
            let data = try readXCDataModelFile(path: ret.cleanFilePath!)
            let gen:(status:Bool,entities:[Entity]?,msg:String?) = self.generateEntities(xmlData: data)
            
            if gen.status == true {
                
                let codeContent: [EntityFileContentHolder]!
                var extContent : [EntityFileContentHolder]?
                
                switch language {
                    
                case .java:
                    let java = JavaGenerator(entities: gen.entities!, indent: indentation)
                    codeContent = java.getFileConents()
                    extContent = java.getExtensionFileContents()
                case .kotlin:
                    let kotlin = KotlinGenerator(entities: gen.entities!, indent: indentation)
                    codeContent = kotlin.getFileConents()
                    extContent = kotlin.getExtensionFileContents()
                case .swift:
                    let swift = SwiftCodeGenerator(entities: gen.entities!, indent: indentation)
                    codeContent = swift.getFileConents()
                    extContent = swift.getExtensionFileContents()
                }
                
                let savePath = try getFileSavingPath()
                let modelName = getModelName(filepath: file)
                do {
                    var finalStatus:String = ""
                    let saver = CodeFileSaver(files: codeContent, language: language)
                    finalStatus = try saver.save(atPath: savePath, createNewDir: true, dirName:modelName, overwrite: true)
                    
                    if extContent != nil {
                        do {
                            let extSave = CodeFileSaver(files: extContent!, language: language)
                            finalStatus += "\n"
                            finalStatus += try extSave.save(atPath: savePath, createNewDir: true, dirName: modelName, overwrite: false)
                        } catch let e {
                            return (false, e.localizedDescription, .error)
                        }
                    }
                    
                    return (true, finalStatus, .standard)
                    
                } catch let e {
                    return (false, e.localizedDescription, .error)
                }
                
            } else {
                return (false, gen.msg, .error)
            }
        } catch let e {
            return (false,"Error: \(e.localizedDescription)",.error)
        }
    }
    
    private func getModelName(filepath:String)->String {
        
        let nsFileName = filepath as NSString
        let path = nsFileName.lastPathComponent as NSString
        let name = path.deletingPathExtension
        return name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
    }
    
    private func getModelContentsPath(fromFilePath:String) throws -> String {
    
        let filepath = filepathBuidler(fromFilePath: fromFilePath)
        
        let fExtension = (filepath as NSString).pathExtension
        
        var path:String!
        if fExtension == XCDataModelExtensionType.xcdatamodeld.rawValue {
            path = filepath + "\(getModelName(filepath: filepath)).xcdatamodel/contents"
        } else if fExtension == XCDataModelExtensionType.xcdatamodel.rawValue {
             path = filepath + "contents"
        } else {
            throw NSError(domain: Config.errorDomain, code: 7, userInfo: [NSLocalizedDescriptionKey:"Data model file must have extension of \(Config.xcDataModelExt.joined(separator: ", ")), your file extension is \(fExtension)"])
        }

        return path.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    private func getFileSavingPath() throws -> String {
        if let filePath = consoleOption.path {
            return filepathBuidler(fromFilePath: filePath)
        }
        
        if let file = consoleOption.file {
            let contentsPath = filepathBuidler(fromFilePath: file)
            return (contentsPath as NSString).deletingLastPathComponent
        } else {
            throw NSError(domain: Config.errorDomain, code: 8, userInfo: [NSLocalizedDescriptionKey:"No model file is defined"])
        }
    
    }
        
    private func processXCDataModelFile(modelFile:String) -> (status:Bool,cleanFilePath:String?) {
        
        var filePath = modelFile
        filePath = filePath.trimmingCharacters(in: CharacterSet(charactersIn: "\'\"")).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if filePath.characters.count == 0 {
            return (false,"file path length is Zero(0)")
        }
        
        let pathExt = (filePath as NSString).pathExtension
        if  !Config.xcDataModelExt.contains(pathExt) {
            return (false,"Data model file must have extension of \(Config.xcDataModelExt.joined(separator: ", ")), your file extension is \(pathExt)")
        }
        
        do {
            let pathWithContent = try getModelContentsPath(fromFilePath: filePath)
            
            if !FileManager.default.fileExists(atPath: pathWithContent) {
                return (false,"Data model file does not exist at '\(pathWithContent)'")
            }
            
            if !FileManager.default.isReadableFile(atPath: pathWithContent) {
                return (false,"Data model file is not readable \(pathWithContent)")
            }
            
            return (true,pathWithContent)
            
        } catch let e {
            return (false,e.localizedDescription)
        }
    
    }
    
    private func readXCDataModelFile(path:String) throws -> Data {
        
        do {
            let fileUrl =  URL(fileURLWithPath: path)
            let data = try Data(contentsOf:fileUrl)
            return data
        } catch let e  {
            throw e
        }
        
    }
    
    @discardableResult
    func generateEntities(xmlData:Data) -> (Bool,[Entity]?,String?) {
        let xml = parse(xmlData: xmlData)
        
        if (!validation(xml: xml)) {
            return (false, nil, "XML is not validated")
        }
        
        guard let x = getEntities(xml: xml) else {
            return (false, nil, "XML is not able to generate entities")
        }
        
        return (true, x, nil)
        
    }
    
    private func parse (xmlData:Data) -> XMLIndexer {
     
        let xml = SWXMLHash.parse(xmlData)
        return xml
        
    }
    
    private func validation(xml:XMLIndexer) -> Bool {
        //TODO:
        return true
    }
    
    private func getEntities(xml:XMLIndexer) -> [Entity]? {
        
        let xmlEntities = xml[kXMLElement.root][kXMLElement.entity]
        
        var entities:[Entity] = [Entity]()
        
        for xmlEntity in xmlEntities {
    
            let entityUserInfo = xmlEntity[kXMLElement.userInfo]
            
            var entityInfo = EntityInfo.kDefault
            for eachUserInfo in entityUserInfo {
                
                let entries = eachUserInfo[kXMLElement.entry]
                
                for eachEntry in entries {
                    
                    if let entryAtt = eachEntry.element?.allAttributes {
                        
                        if let key = entryAtt[kXMLAttribute.key]?.text, let value = entryAtt[kXMLAttribute.value]?.text {
                        
                            if key == kXMLValue.type {
                                if value == kXMLValue.struct {
                                    entityInfo.modelType = .struct
                                }
                            }
                        }
                    }
                }
                
            }
            
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
                                let attOptional = BoolType(value:fieldAttributes[kXMLAttribute.optional]?.text ?? kXMLValue.no)
                                
                                let userInfo = field[kXMLElement.userInfo]
                                
                                var info = AttributeInfo.kDefault
                                for eachUserInfo in userInfo {
                                    
                                    let entries = eachUserInfo[kXMLElement.entry]
                                    for eachEntry in entries {
                                        
                                        if let entryAtt = eachEntry.element?.allAttributes {
                                            
                                            if let key = entryAtt[kXMLAttribute.key]?.text, let value = entryAtt[kXMLAttribute.value]?.text {
                                                
                                                if key == kXMLValue.order {
                                                    info.order = Int(value)!
                                                } else if key == kXMLValue.access {
                                                    info.access = AccessControlType(type: value)
                                                } else if key == kXMLValue.arc {
                                                    info.arc = ARCType(type: value)
                                                } else if key == kXMLValue.mutable {
                                                    info.mutable = BoolType(value: value)
                                                } else if key == kXMLValue.hash {
                                                    info.hash = BoolType(value: value)
                                                }
                                            }
                                            
                                        }
                                    }
                                    
                                }
                                
                                let attribute = Attribute(name: attName, dataType: attType, isOptional: attOptional, isScalarValueType: attScalarValueType, customClassName: attCustomClassName, defaultValue: attDefaultValue, info: info)
                                
                                attributes.append(attribute)
 
                            }
                            
                        }

                    }
                    
                    var entity:Entity = Entity(name: name, className: clsName!, parentName: parentName, codeGenType: CodeGenType(type:codeType), attributes:attributes)
                    entity.info = entityInfo
                    entities.append(entity)
                    
                }
            
            }
            
        }
        
        return entities
    }
}

enum CodeGenType : String {
    case `class` = "class", `struct` = "struct"
    init(type:String) {
        if type.lowercased() == "struct" {
            self = .`struct`
        } else {
            self = .class
        }
    }
}

enum BoolType : String {
    case yes = "YES", no = "NO"
    init(value:String) {
        if value.uppercased() == "YES" || value.uppercased() == "TRUE" {
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

enum AccessControlType : String {
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
    
    var isInt:Bool {
        return (self == .int64 || self == .int32 || self == .int16)
    }
    
}

struct Entity {
    let name:String
    let className:String
    let parentName:String?
    let codeGenType:CodeGenType
    let attributes:[Attribute]
    var info:EntityInfo = EntityInfo.kDefault
    
    init(name:String, className:String, parentName:String?, codeGenType:CodeGenType, attributes:[Attribute]) {
        self.name = name
        self.className = className
        self.parentName = parentName
        self.codeGenType = codeGenType
        self.attributes = Entity.sortedAttributes(attributes: attributes)
    }
    
    private static func sortedAttributes(attributes:[Attribute]) -> [Attribute] {
        
        let sorted = attributes.sorted { (a, b) -> Bool in
            let _a = a.info?.order ?? Int.max
            let _b = b.info?.order ?? Int.max
            if (_a == _b) {
                return a.name < b.name
            }
            return _a < _b
        }

        return sorted
    }
    
    var isChild: Bool {
        if let p = parentName, p.characters.count > 0 {
            return true
        }
        
        return false
    }
        
}

struct Attribute : Equatable, CustomStringConvertible {
    
    let name:String
    let dataType:DataType
    let isOptional:BoolType
    let isScalarValueType:BoolType
    let customClassName:String?
    let defaultValue:String?
    var info:AttributeInfo? = AttributeInfo.kDefault
    
    var isMutable:Bool {
        return info?.mutable.value ?? true
    }
    
    var cocoaARC:String {
        return info?.arc.value ?? ""
    }
    
    var description: String {
        return "Attribute:\(name) \(dataType) \(info?.order ?? 0)"
    }
    
    static func ==(lhs:Attribute, rhs:Attribute)->Bool {
        return lhs.name == rhs.name && lhs.dataType.rawValue == rhs.dataType.rawValue
    }
}

struct EntityInfo {
    var modelType:CodeGenType
    static let kDefault = EntityInfo(modelType: CodeGenType(type: "class"))
}

struct AttributeInfo {
    var order:Int
    var arc:ARCType = .strong
    var mutable:BoolType = .yes
    var access:AccessControlType = .internal
    var hash:BoolType
    static let kDefault = AttributeInfo(order: Int.max, arc: .strong, mutable: .yes, access: .internal, hash: .no)
}


struct kXMLElement {
    static let root = "model"
    static let entity = "entity"
    static let attribute = "attribute"
    static let userInfo = "userInfo"
    static let entry = "entry"
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
    static let key = "key"
    static let value = "value"
}

struct kXMLValue {
    static let yes = "YES"
    static let no = "NO"
    static let transformable = "Transformable"
    static let access = "access"
    static let order = "order"
    static let `private` = "private"
    static let `public` = "public"
    static let `internal` = "intenal"
    static let `fileprivate` = "fileprivate"
    static let `open` = "open"
    static let arc = "arc"
    static let weak = "weak"
    static let strong = "strong"
    static let mutable = "mutable"
    static let type = "type"
    static let `struct` = "struct"
    static let `class` = "class"
    static let hash = "hash"
}
