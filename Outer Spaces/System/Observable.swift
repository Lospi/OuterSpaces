//
//  AppleScriptRunner.swift
//  AppleScriptTest
//
//  Created by Mark Alldritt on 2021-02-02.
//

import Cocoa
import SwiftUI

class AppleScriptRunner: ObservableObject, Hashable {
    class Error: Equatable {
        //  Conform to Equatable
        static func == (lhs: AppleScriptRunner.Error, rhs: AppleScriptRunner.Error) -> Bool {
            return lhs.errorDict == rhs.errorDict
        }
        
        private let errorDict: NSDictionary
        
        var number: OSStatus {
            return (errorDict[NSAppleScript.errorNumber] as? NSNumber)?.int32Value ?? noErr
        }

        var message: String {
            return errorDict[NSAppleScript.errorMessage] as? String ?? briefMessage
        }

        var briefMessage: String {
            return errorDict[NSAppleScript.errorBriefMessage] as? String ?? "unknown error"
        }

        var range: NSRange? {
            return (errorDict[NSAppleScript.errorBriefMessage] as? NSValue)?.rangeValue
        }

        var application: String? {
            return errorDict[NSAppleScript.errorAppName] as? String
        }

        init(_ errorDict: NSDictionary) {
            self.errorDict = errorDict
        }
    }
    
    enum State: Equatable {
        case idle, running, complete(NSAppleEventDescriptor), error(Error)
    }
    
    //  Conform to Equitable
    static func == (lhs: AppleScriptRunner, rhs: AppleScriptRunner) -> Bool {
        return lhs.id == rhs.id
    }
    
    //  Conform to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id = UUID()
    private let script: NSAppleScript

    @Published private(set) var state = State.idle

    init(_ source: String) {
        if let script = NSAppleScript(source: source) {
            self.script = script
        }
        else {
            fatalError("Cannot compile source")
        }
    }
        
    private func start() {
        state = .running
    }
    
    private func completed(_ resultDesc: NSAppleEventDescriptor, error: NSDictionary?) {
        if let error = error {
            print("error: \(error)")
            state = .error(Error(error))
        }
        else {
            print("result: \(resultDesc)")
            state = .complete(resultDesc)
        }
    }
    
    public func executeSync() {
        start()
        
        var error: NSDictionary? = nil
        let resultDesc = script.executeAndReturnError(&error)

        completed(resultDesc, error: error)
    }
    
    public func executeAsync() {
        start()
        DispatchQueue.global(qos: .background).async {
            var error: NSDictionary? = nil
            let resultDesc = self.script.executeAndReturnError(&error)
            
            DispatchQueue.main.async {
                self.completed(resultDesc, error: error)
            }
        }
    }
}
