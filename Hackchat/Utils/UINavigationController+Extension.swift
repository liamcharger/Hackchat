//
//  UINavigationController+Extension.swift
//  Hackchat
//
//  Created by Liam Willey on 4/12/25.
//

import SwiftUI

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        // This enables swipe to dismiss when the back button is disabled
        interactivePopGestureRecognizer?.delegate = nil
    }
}
