//  ContentView.swift
//  EulerityApp
//
//  Created by Gaurav Bhambhani on 6/11/23.

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
        .sheet(item: $selectedImage, onDismiss: {
                    editedImage = nil // Reset editedImage when the sheet is dismissed
                }) { image in
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
                dateFormatter.dateFormat = "MMM d, yyyy h:mm:ss a"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)

                var imageArray = try decoder.decode([ImageModel].self, from: data)

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
        
        //GET Request
        guard let getUrl = URL(string: "https://eulerity-hackathon.appspot.com/upload") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: getUrl) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("Empty data")
                return
            }
            
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let uploadURLString = jsonObject["url"] as? String,
                   let uploadURL = URL(string: uploadURLString) {

                    uploadImage(to: uploadURL, image: image)
                } else {
                    print("Invalid JSON response")
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func uploadImage(to url: URL, image: UIImage) {
        let appid = "bhambhani.g@northeastern.edu"
        let originalURL = selectedImage?.url ?? ""

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"appid\"\r\n\r\n")
        body.appendString("\(appid)\r\n")

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"original\"\r\n\r\n")
        body.appendString("\(originalURL)\r\n")

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendString("\r\n")

        body.appendString("--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                print("Upload status code: \(response.statusCode)")

                if response.statusCode == 200 {
                    // Upload successful
                    if let data = data {
                        do {
                            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                            print("Upload response: \(jsonResponse)")
                        } catch {
                            print("Error decoding JSON response: \(error.localizedDescription)")
                        }
                    }
                } else {
                    // Error occurred
                    if let data = data {
                        let responseString = String(data: data, encoding: .utf8)
                        print("Error response: \(responseString ?? "")")
                    }
                }
            }
        }.resume()
    }
}

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

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

struct TextOverlay: View {
    var text: String

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            Text(text)
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
//                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ImageEditorView: View {
    let image: ImageModel
    @Binding var editedImage: UIImage?
    @State private var overlayText: String = ""
    @State private var isOverlayAdded: Bool = false
    var onDone: (UIImage) -> Void

    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                if let editedImage = editedImage {
                    Image(uiImage: editedImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(uiImage: image.image ?? UIImage(systemName: "photo")!)
                        .resizable()
                        .scaledToFit()
                }

                if isOverlayAdded {
                    TextOverlay(text: overlayText)
                        .foregroundColor(.white)
                        .padding()
//                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
            }

            VStack {
                if isOverlayAdded {
                    TextField("Enter overlay text", text: $overlayText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            .padding()

            HStack {
                Button("Add Overlay") {
                    isOverlayAdded = true
                }
                .disabled(isOverlayAdded)

                Button("Remove Overlay") {
                    isOverlayAdded = false
                }
                .disabled(!isOverlayAdded)

                Spacer()

                Button("Apply Filter") {
                    applyFilter()
                }
                
                Button("Remove Filter") {
                    removeFilter()
                }
            }
            .padding()

            Button("Save") {
                if let editedImage = editedImage, let newImage = addOverlayText(to: editedImage) {
                    onDone(newImage)
                } else if let newImage = addOverlayText(to: image.image ?? UIImage()) {
                    onDone(newImage)
                }
            }
        }
    }

    private func applyFilter() {
        // Apply the filter

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

    private func removeFilter() {
        editedImage = nil
    }

    private func addOverlayText(to image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Draw the image
        image.draw(in: CGRect(origin: .zero, size: image.size))

        // Draw the overlay text
        if isOverlayAdded {
            let textRect = CGRect(x: 10, y: 10, width: image.size.width - 20, height: image.size.height - 20)
            let textStyle = NSMutableParagraphStyle()
            textStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 240),
                .foregroundColor: UIColor.white,
                .paragraphStyle: textStyle
            ]

            let attributedText = NSAttributedString(string: overlayText, attributes: attributes)
            attributedText.draw(in: textRect)
        }

        // Get the combined image
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }

        return newImage
    }
}



struct ParentView_Previews: PreviewProvider {
    static var previews: some View {
        ParentView()
    }
}
