//
//  import Bugsnag  func reportException(exception: NSException) {     Bugsnag.notify(exception)     super.reportException(exception) BugSnag.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 07/02/24.
//

import Bugsnag
import Cocoa

class BugSnagException: NSApplication {
    func reportException(exception: NSException) {
        Bugsnag.notify(exception)
        super.reportException(exception)
    }
}
