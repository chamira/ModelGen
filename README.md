# ModelGen
Simple Commandline tool to generate model objects.
This project reads **xcdatamodel** (Xcode data model) file and generate the model objects.
Initial idea is to generate **.swift**, **.kotlin** and **.java**

# Usecase
**xcdatamodel** file is used by **Xcode** to generate codedata objects in ios/macos projects. Why can't it be used to generate non-coredata model objects?

# How to use it?
  * Create new **.xcdatamodel** file in your Xcode project. (Highlight Xcode project->NewFile->Data Model under Core Data)
  * Remove created **.xcdatamodel** from the target (if it's is added), This is very important otherwise there will be compile errors.
  * Add Entities of the model
  * Add Attributes of each entity, and define data type and default value of each attribute in *Model inspector pane*.
  * Add Entity or Attribute options for special cases
  * Download ModelGen change dir to ModelGenExecutable and run  
  `./ModelGen -f path/to/created/object.xcdatamodel`  

### Entity option
Entity option can be added under **User info** section
  * Highlight the Entity
  * Open Data Model inspector pane
  * Under **User info** section add **<Key,Value>** for options
  * Supported option

  `type = class | struct` if model object is type of a `struct` or a `class` default is `class`

### Attribute options
Attribute options can be added under **User info** section
  * Highlight the Attribute
  * Open Data Model inspector pane
  * Under **User info** section add **<Key,Value>** for options
  * Supported options  

  `order = integer (0...)` defines sort order of the attribute list, this is useful if you want attribute to be in certain order.
  `access = private | fileprivate | internal | public | open` default `internal`  
  `mutable = yes | no` default `no` (this defines var or let in **.swift**)  
  `arc = strong | weak` default `strong`  
  `hash = yes | no` default `no` (Special case when Swift **Hashable** Protocol is used, an attribute can be defined as hash)  

# Commands
`  
-f path/to/dataModel file, must be type of *.xcdatamodeld, *.xcdatamodel`  
`-p path/to/dir/to/generate/files, any writable dir, if not defined gets same dir as the data model file`  
`-l language(swift or java or kotlin). only swift is supported at this moment`  
`-i indentation(space or tab) syntax is type:value (space:4), default is space:4`  
`-v version`  
`-h to show usage information`  

# SWIFT
## init method & swift extensions
* `init(...) {}` method is generated with all immutable properties as params, order of the params can be defined `order = integer (0...)`
* for each and every model object swift **extension** is generated in a separate file. This is extension file would not be overwritten thus the business logic can be written there.

## Swift Protocols implementation
If you want to auto generate some Swift protocols as the part of the model generation have a look at **SwiftBasicProtocolImp.swift**  
implement **SwiftBasicProtocolTemplate** and add implemented protocol to **SwiftBasicProtocol.list** array.
Example:  
```
protocol SwiftBasicProtocolTemplate {
    var name:String { get }
    var implementaionIn:SwiftBasicProtocolImpOption { get }
    var scope:SwiftBasicProtocolImpScope { get }
    func implementationTemplate()->String
    func propertyStringForEnitity(entity:Entity)->String
}  

struct SwiftBasicProtocol {
    static let list:[SwiftBasicProtocolTemplate] = [
        SwiftCustomStringConvertible(),
        SwiftEquatable()
        /*,SwiftHashable()*/ // Add SwiftHashable if you want to
    ]
}
```

# License  
ModelGen is available under the MIT license. See the LICENSE file for more info.
