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
    
    init(lang:String) {
        switch lang {
        case "kotlin":
            self = .kotlin
        case "java":
            self = .java
        default:
            self = .swift
        }
    }
    
    var `extension`:String {
        switch self {
        case .kotlin:
            return "kotlin"
        case .java:
            return "java"
        default:
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
    
    init(value:String) {
        
        let sep = value.components(separatedBy: ":")
        if (sep.count == 2) {
            
            if let type = sep.first?.lowercased(), let count = Int(sep[1]) {
                if type == "tab" || type == "tabs" {
                    self = .tab(count: count)
                } else {
                    self = .space(count: count)
                }
            }
            self = .space(count: 4)
        } else {
            self = .space(count: 4)
        }
    }
    
    static func ==(lhs:GeneratorIndentation, rhs:GeneratorIndentation) -> Bool {
        return lhs.value == rhs.value
    }
    
}

class Processor {
    
    private var _xmlData:Data!

    var indentation : GeneratorIndentation!
    var language:SupportLanguage = SupportLanguage(lang: Config.defaultLanguage)
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
                
                //gen.generate()
                
                let codeContent: [EntityFileContentHolder]!
                
                switch language {
                case .kotlin:
                    let kotlin = KotlinGenerator(entities: gen.entities!, indent: indentation)
                    codeContent = kotlin.getFileConents()
                default:
                    let swift = SwiftCodeGenerator(entities: gen.entities!, indent: indentation)
                    codeContent = swift.getFileConents()
                }
                
                let saver = CodeFileSaver(files: codeContent, language: language, path: getFileSavingPath(), createNewDir: true)
                
                do {
                    
                    let ret = try saver.save()
                    return (true, ret, .standard)
                    
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
        
        let path = (filepath as NSString).lastPathComponent
        let name = path.replacingOccurrences(of: Config.xcDataModelExt, with: "").replacingOccurrences(of: ".", with: "")
        return name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
    }
    
    private func getFileSavingPath()->String {
        if let filePath = consoleOption.path {
            return filePath
        }
        
        if let file = consoleOption.file {
            var comps = (file as NSString).pathComponents
            let _ = comps.removeLast()
            if let first = comps.first, first == "/" {
                let _ = comps.removeFirst()
            }
            let join = "/"+comps.joined(separator: "/")+"/"
            return join
        }
        
        return ""
    }
    
    private func processXCDataModelFile(modelFile:String) -> (status:Bool,cleanFilePath:String?) {
        
        var filePath = modelFile
        filePath = filePath.replacingOccurrences(of: "\"", with: "")
        filePath = filePath.replacingOccurrences(of: "\'", with: "")
        filePath = filePath.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if filePath.characters.count == 0 {
            return (false,"file path length is Zero(0)")
        }
        
        let pathExt = (filePath as NSString).pathExtension
        if  pathExt != Config.xcDataModelExt {
            return (false,"Data model file must have extension of \(Config.xcDataModelExt), your file extension is \(pathExt)")
        }
        
        let pathWithContent = filePath + "/\(getModelName(filepath: filePath)).xcdatamodel/contents"
        if !FileManager.default.fileExists(atPath: pathWithContent) {
            return (false,"Data model file does not exist at \(pathWithContent)")
        }
        
        if !FileManager.default.isReadableFile(atPath: pathWithContent) {
            return (false,"Data model file is not readable \(pathWithContent)")
        }
        
        return (true,pathWithContent)
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
                                
                                let userInfo = field[kXMLElement.userInfo]
                                
                                var info = AttributeInfo.kDefault
                                for eachUserInfo in userInfo {
                                    
                                    let entries = eachUserInfo[kXMLElement.entry]
                                    for eachEntry in entries {
                                        
                                        if let entryAtt = eachEntry.element?.allAttributes {
                                            
                                            if let key = entryAtt[kXMLAttribute.key]?.text, let value = entryAtt[kXMLAttribute.value]?.text {
                                            
                                                if key == kXMLValue.access {
                                                    info.access = AccessControlType(type: value)
                                                } else if key == kXMLValue.arc {
                                                    info.arc = ARCType(type: value)
                                                } else if key == kXMLValue.mutable {
                                                    info.mutable = BoolType(value: value)
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
                    
                    let entity:Entity = Entity(name: name, className: clsName!, parentName: parentName, codeGenType: CodeGenType(type:codeType), attributes:attributes)
                    
                    entities.append(entity)
                    
                }
            
            }
            

        }
        
        return entities
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
    
}

struct Entity {
    let name:String
    let className:String
    let parentName:String?
    let codeGenType:CodeGenType
    let attributes:[Attribute]
}

struct Attribute {
    
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
}

struct AttributeInfo {
    var arc:ARCType = .strong
    var mutable:BoolType = .yes
    var access:AccessControlType = .internal
    static let kDefault = AttributeInfo(arc: .strong, mutable: .yes, access: .internal)
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
    static let `private` = "private"
    static let `public` = "public"
    static let `internal` = "intenal"
    static let `fileprivate` = "fileprivate"
    static let `open` = "open"
    static let arc = "arc"
    static let weak = "weak"
    static let strong = "strong"
    static let mutable = "mutable"
}