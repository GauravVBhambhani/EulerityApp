//
//  TextOverlay.swift
//  EulerityApp
//
//  Created by Gaurav Bhambhani on 6/12/23.
//

import SwiftUI

struct TextOverlay: View {
    var text: String

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            Text(text)
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
                .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
