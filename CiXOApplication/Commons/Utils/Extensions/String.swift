//
//  Endpoint.swift
//  CiXOApplication
//
//  Created by Nguyen Thien on 24/02/2024.
//

import Foundation

extension String {
    func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func localised(bundle: Bundle = .main) -> String {
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}
