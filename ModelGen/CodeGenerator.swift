//
//  SwiftGenerator.swift
//  ModelGen
//
//  Created by Chamira Fernando on 13/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

protocol CodeGeneratorProtocol {
    func getFileConents() -> [EntityFileContentHolder]
    func getExtensionFileContents() -> [EntityFileContentHolder]?
}

struct EntityFileContentHolder {
    let entity:Entity
    let fileName:String
    let content:String
}

class CodeGenerator {
    
    let entities:[Entity]
    let indentation : GeneratorIndentation
    
    init(entities:[Entity], indent:GeneratorIndentation = .space(count: 4)) {
        self.entities = entities
        self.indentation = indent
    }
    
}



class JavaGenerator : CodeGenerator , CodeGeneratorProtocol {
    
    func getFileConents() -> [EntityFileContentHolder] {
        var files:[EntityFileContentHolder] = [EntityFileContentHolder]()
        for entity in entities {
            let str = "class \(entity.className)\n{\n}"
            files.append(EntityFileContentHolder(entity: entity, fileName:entity.className, content: str))
        }
        
        return files
    }
    
    func getExtensionFileContents() -> [EntityFileContentHolder]? {
        return nil
    }
}

class KotlinGenerator : CodeGenerator , CodeGeneratorProtocol {
    
    func getFileConents() -> [EntityFileContentHolder] {
        var files:[EntityFileContentHolder] = [EntityFileContentHolder]()
        for entity in entities {
            let str = "class \(entity.className)\n{\n}"
            files.append(EntityFileContentHolder(entity: entity, fileName:entity.className, content: str))
        }
        
        return files
    }
    
    func getExtensionFileContents() -> [EntityFileContentHolder]? {
        return nil
    }
}
