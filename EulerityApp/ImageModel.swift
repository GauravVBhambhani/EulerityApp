//
//  ImageModel.swift
//  EulerityApp
//
//  Created by Gaurav Bhambhani on 6/12/23.
//

import Foundation
import SwiftUI

struct ImageModel: Identifiable, Decodable {
    let id = UUID()
    let url: String
    let created: Date
    let updated: Date
    var image: UIImage?

    enum CodingKeys: String, CodingKey {
        case url, created, updated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
        image = nil
    }
}
