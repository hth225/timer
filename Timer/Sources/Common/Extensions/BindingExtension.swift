//
//  BindingExtension.swift
//  Timer
//
//  Created by Jason Hwang on 5/14/24.
//

import Foundation
import SwiftUI

extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
            return Binding(
                get: { self.wrappedValue },
                set: {
                    self.wrappedValue = $0
                    execute($0)
                }
            )
        }
}
