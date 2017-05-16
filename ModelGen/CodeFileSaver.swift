//
//  CodeFileSaver.swift
//  ModelGen
//
//  Created by Chamira Fernando on 15/05/2017.
//  Copyright © 2017 Arangaya Apps. All rights reserved.
//

import Foundation

struct CodeFileSaverStatus : CustomStringConvertible {
    let fileName:String
    let status:(Bool,String?)
    
    var description: String {
        
        let st = self.status.0 == true ? "Done" : ("Fail->" + self.status.1!)
        return "Model:"+self.fileName + " Status:" + st
    }
    
}

class CodeFileSaver {
    
    let files:[EntityFileContentHolder]
    let language:SupportLanguage
    let path:String
    let createNewDir:Bool
    
    init(files:[EntityFileContentHolder], language:SupportLanguage, path:String, createNewDir:Bool = true) {
        self.files = files
        self.language = language
        self.createNewDir = createNewDir
        self.path = path
    }
    
    func save() throws -> String {
        
        var status:[String] = [String]()
        
        let dirToWrite = getDirToWrite()
        if (dirToWrite.0 == false) {
            throw NSError(domain: Config.errorDomain, code: 3, userInfo: [NSLocalizedDescriptionKey: dirToWrite.1!])
        }
        
        for eachEntity in files {
            
            var s:CodeFileSaverStatus!
            let fileName = eachEntity.entity.className+"."+language.extension
            do {
               
                let fileName = dirToWrite.1!+"/"+fileName
                try eachEntity.content.write(toFile: fileName, atomically: true, encoding: String.Encoding.utf8)
                
                s = CodeFileSaverStatus(fileName: fileName, status: (true,fileName))
                
            } catch let e {
                s = CodeFileSaverStatus(fileName: fileName, status: (false,e.localizedDescription))
            }
            
            status.append(s.description)
            
        }
        
        return status.joined(separator: "\n")
    }
    
    func createNewDir(path:String) -> (Bool,String?){
        
        let newPath =  path+"/"+getNewDirName()
        
        if FileManager.default.fileExists(atPath: newPath) {
            return (true,newPath)
        }
        
        do {
            try FileManager.default.createDirectory(atPath:newPath, withIntermediateDirectories: true, attributes: nil)
            return (true, newPath)
        } catch let e {
            return (false,e.localizedDescription)
        }
        
    }
    
    func getDirToWrite() ->(Bool,String?) {
        if createNewDir {
            let p = createNewDir(path: self.path)
            return p
        }
        return (true,self.path)
    }
    
    func getNewDirName()->String {
        return "ModelObjects-"+language.rawValue
    }
}
