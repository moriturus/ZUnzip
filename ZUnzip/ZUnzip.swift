//
//  ZUnzip.swift
//  ZUnzip
//
//  Created by Henrique Sasaki Yuya on 7/25/16.
//  Original file written in Objective-C:
//      Copyright © 2016 Kaz Yoshikawa. All rights reserved.
//

import Foundation
import libzip
import fmemopen

public final class ZUnzip {
    
    public enum Error: Int32, CustomStringConvertible, ErrorType {
        
        public enum RawError: ErrorType {
            
            case RawValue(Int32)
            
        }
        
        case InMemoryFileAllocation = -1
        case OK = 0
        case Multidisk
        case Rename
        case Close
        case Seek
        case Read
        case Write
        case CRC
        case ZipClosed
        case NoEntry
        case Exists
        case FileOpen
        case TemporaryFileOpen
        case Zlib
        case Allocation
        case Changed
        case CompressionMethodNotSupported
        case EOF
        case InvalidArgument
        case NotZip
        case Internal
        case Inconsistent
        case CannotRemove
        case Deleted
        case EncryptionMethodNotSupported
        case ReadOnly
        case NoPassword
        case WrongPassword
        
        public var description: String {
            
            switch self {
                
            case .InMemoryFileAllocation:
                return "Allocation for in-memory file failed"
                
            case .OK:
                return "No Error"
                
            case .Multidisk:
                return "Multi-disk zip archives not supported"
                
            case .Rename:
                return "Renaming temporary file failed"
                
            case .Close:
                return "Closing zip archive failed"
                
            case .Seek:
                return "Seek error"
                
            case .Read:
                return "Read error"
                
            case .Write:
                return "Write error"
                
            case .CRC:
                return "CRC error"
                
            case .ZipClosed:
                return "Containing zip archive was closed"
                
            case .NoEntry:
                return "No such file"
                
            case .Exists:
                return "File already exists"
                
            case .FileOpen:
                return "Can't open file"
                
            case .TemporaryFileOpen:
                return "Failure to create temporary file"
                
            case .Zlib:
                return "Zlib error"
                
            case .Allocation:
                return "Malloc failure"
                
            case .Changed:
                return "Entry has been changed"
                
            case .CompressionMethodNotSupported:
                return "Compression method not supported"
                
            case .EOF:
                return "Premature EOF"
                
            case .InvalidArgument:
                return "Invalid argument"
                
            case .NotZip:
                return "Not a zip archive"
                
            case .Internal:
                return "Internal error"
                
            case .Inconsistent:
                return "Zip archive inconsistent"
                
            case .CannotRemove:
                return "Can't remove file"
                
            case .Deleted:
                return "Entry has been deleted"
                
            case .EncryptionMethodNotSupported:
                return "Encryption method not supported"
                
            case .ReadOnly:
                return "Read-only archive"
                
            case .NoPassword:
                return "No password provided"
                
            case .WrongPassword:
                return "Wrong password provided"
                
            }
            
        }
        
    }
    
    private var fileToIndexDictionaryStorage: [String: UInt64]? = nil
    public var fileToIndexDictionary: [String: UInt64] {
        
        if let s = fileToIndexDictionaryStorage {
            
            return s
            
        } else {
            
            var dictionary: [String: UInt64] = [:]
            let count = zip_uint64_t(zip_get_num_entries(zip, 0))
            
            for i in 0..<count {
                
                var status = zip_stat()
                zip_stat_init(&status)
                zip_stat_index(zip, i, 0, &status)
                
                let fileName = String(CString: status.name, encoding: NSUTF8StringEncoding)
                
                if let f = fileName {
                    
                    dictionary[f] = i
                    
                }
                
            }
            
            fileToIndexDictionaryStorage = dictionary
            
            return dictionary
            
        }
        
    }
    
    public var files: [String] {
        
        return fileToIndexDictionary.keys.map { $0 }
        
    }
    
    private var zip: UnsafeMutablePointer<libzip.zip> = nil
    private var file: UnsafeMutablePointer<FILE> = nil
    
    deinit {
        
        if zip != nil {
            
            zip_close(zip)
            
        }
        
        if file != nil {
            
            fclose(file)
            
        }
        
    }
    
    public init(zipData data: NSData) throws {
        
        file = fmemopen(UnsafeMutablePointer(data.bytes), data.length, "rb")
        
        guard file != nil else {
            
            throw Error.InMemoryFileAllocation
            
        }
        
        var error: Int32 = 0
        zip = _zip_open(nil, file, 0, &error)
        
        guard let e = Error(rawValue: error) where e == .OK else {
            
            defer {
                
                fclose(file)
                
            }
            
            if let e = Error(rawValue: error) {
                
                throw e
                
            } else {
                
                throw Error.RawError.RawValue(error)
                
            }
            
        }
        
    }
    
    public init(filePath: NSString) throws {
        
        var error: Int32 = 0
        zip = zip_open(filePath.fileSystemRepresentation, 0, &error)
        
        guard let e = Error(rawValue: error) where e == .OK else {
            
            if let e = Error(rawValue: error) {
                
                throw e
                
            } else {
                
                throw Error.RawError.RawValue(error)
                
            }
            
        }
        
    }
    
    public func data(forFile file: String) -> NSData? {
        
        guard zip != nil else {
            
            return nil
            
        }
        
        guard let i = fileToIndexDictionary[file] else {
            
            return nil
            
        }
        
        var status = zip_stat()
        zip_stat_init(&status)
        zip_stat_index(zip, i, 0, &status)
        
        let zipFile = zip_fopen_index(zip, i, 0)
        var buf: [UInt8] = Array(count: Int(status.size), repeatedValue: 0)
        zip_fread(zipFile, &buf, status.size)
        zip_fclose(zipFile)
        
        return NSData(bytesNoCopy: &buf, length: buf.count, freeWhenDone: false)
        
    }
    
}