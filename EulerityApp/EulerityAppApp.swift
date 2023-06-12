//
//  EulerityAppApp.swift
//  EulerityApp
//
//  Created by Gaurav Bhambhani on 6/11/23.
//

import SwiftUI

@main
struct EulerityAppApp: App {
    
    @State private var images: [ImageModel] = [] // Create a state property for the images

    var body: some Scene {
        WindowGroup {
            ContentView(images: $images)
        }
    }
}
