//
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

struct ImageEditorView: View {
    let image: ImageModel
    @Binding var editedImage: UIImage?
    @State private var overlayText: String = ""
    var onDone: (UIImage) -> Void

    var body: some View {
        VStack {
            ZStack {
                if let editedImage = editedImage {
                    Image(uiImage: editedImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(uiImage: image.image ?? UIImage(systemName: "photo")!)
                        .resizable()
                        .scaledToFit()
                }

                if !overlayText.isEmpty {
                    Text(overlayText)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(20)
                        .offset(x: 0, y: -20)
                }
            }

            Button("Apply Filter") {
                applyFilter()
            }

            TextField("Enter overlay text", text: $overlayText)
                .padding()

            Button("Add Text Overlay") {
                addTextOverlay()
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

    private func addTextOverlay() {
        guard let editedImage = editedImage else { return }

        let imageSize = editedImage.size

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)

        editedImage.draw(at: .zero)

        let textFont = UIFont.systemFont(ofSize: 32)
        let textRect = CGRect(x: 20, y: 20, width: imageSize.width - 40, height: imageSize.height - 40)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        overlayText.draw(in: textRect, withAttributes: attributes)

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
        UIGraphicsEndImageContext()

        self.editedImage = newImage
    }
}

struct ParentView_Previews: PreviewProvider {
    static var previews: some View {
        ParentView()
    }
}
