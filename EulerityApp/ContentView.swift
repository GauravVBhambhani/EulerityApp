//
//  ContentView.swift
//  EulerityApp
//
//  Created by Gaurav Bhambhani on 6/11/23.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ParentView: View {
    @State private var images: [ImageModel] = []
    
    var body: some View {
        ContentView(images: $images)
    }
}

struct ContentView: View {
    @Binding private var images: [ImageModel]
    @State private var selectedImage: ImageModel?
    @State private var editedImage: UIImage?
    
    init(images: Binding<[ImageModel]>) {
        _images = images
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if images.isEmpty {
                    ProgressView()
                } else {
                    List(images) { image in
                        Button(action: {
                            selectedImage = image
                        }) {
                            if let unwrappedImage = image.image {
                                Image(uiImage: unwrappedImage)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Image Gallery")
        }
        .onAppear {
            fetchImages()
        }
        .sheet(item: $selectedImage) { image in
            ImageEditorView(image: image, editedImage: $editedImage) { editedImage in
                uploadImage(editedImage)
            }
        }
    }
    
    private func fetchImages() {
        guard let url = URL(string: "https://eulerity-hackathon.appspot.com/image") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("Empty data")
                return
            }

            do {
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy h:mm:ss a" // Specify the date format
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                var imageArray = try decoder.decode([ImageModel].self, from: data)
                
                // Download the image data for each ImageModel
                for i in 0..<imageArray.count {
                    if let imageUrl = URL(string: imageArray[i].url),
                       let imageData = try? Data(contentsOf: imageUrl),
                       let image = UIImage(data: imageData) {
                        imageArray[i].image = image
                    }
                }
                
                DispatchQueue.main.async {
                    images = imageArray
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func uploadImage(_ image: UIImage) {
        guard let url = URL(string: "https://eulerity-hackathon.appspot.com/upload") else { return }
        
        let appid = "bhambhani.g@northeastern.edu" // Replace with your unique project identifier
        
        let originalURL = selectedImage?.url ?? ""
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("multipart/form-data; boundary=Boundary-\(UUID().uuidString)", forHTTPHeaderField: "Content-Type")
        
        let boundary = "--Boundary-\(UUID().uuidString)\r\n"
        
        var body = Data()
        body.appendString(boundary)
        body.appendString("Content-Disposition: form-data; name=\"appid\"\r\n\r\n")
        body.appendString("\(appid)\r\n")
        
        body.appendString(boundary)
        body.appendString("Content-Disposition: form-data; name=\"original\"\r\n\r\n")
        body.appendString("\(originalURL)\r\n")
        
        body.appendString(boundary)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendString("\r\n")
        
        body.appendString("--Boundary-\(UUID().uuidString)--\r\n")
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Upload status code: \(response.statusCode)")
                // Handle the response status code as needed
            }
        }.resume()
    }
}

struct ImageModel: Identifiable, Decodable {
    let id = UUID() // Assuming you want to generate a unique ID for each image
    let url: String
    let created: Date
    let updated: Date
    var image: UIImage? // Added image property
    
    enum CodingKeys: String, CodingKey {
        case url, created, updated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
        image = nil // Set initial value of image property
    }
}

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

struct ImageEditorView: View {
    let image: ImageModel
    @Binding var editedImage: UIImage?
    var onDone: (UIImage) -> Void
    
    var body: some View {
        VStack {
            Image(uiImage: image.image ?? UIImage(systemName: "photo")!)
                .resizable()
                .scaledToFit()
            
            Button("Apply Filter") {
                applyFilter()
            }
            
            if let editedImage = editedImage {
                Image(uiImage: editedImage)
                    .resizable()
                    .scaledToFit()
            }
            
            Button("Save") {
                if let editedImage = editedImage {
                    onDone(editedImage)
                }
            }
        }
    }
    
    private func applyFilter() {
        guard let ciImage = CIImage(image: image.image ?? UIImage()) else { return }
        
        let filter = CIFilter.sepiaTone()
        filter.inputImage = ciImage
        filter.intensity = 0.8
        
        guard let outputImage = filter.outputImage,
              let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            return
        }
        
        editedImage = UIImage(cgImage: cgImage)
    }
}

struct ParentView_Previews: PreviewProvider {
    static var previews: some View {
        ParentView()
    }
}
