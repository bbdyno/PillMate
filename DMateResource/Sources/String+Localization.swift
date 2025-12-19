//
//  String+Localization.swift
//  DMateResource
//
//  Created by bbdyno on 12/6/25.
//

import Foundation

// MARK: - String Localization Extension

public extension String {
    /// Returns the localized string for the current key
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns the localized string with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
