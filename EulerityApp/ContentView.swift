//  ContentView.swift
//  EulerityApp
//
//  Created by Gaurav Bhambhani on 6/11/23.

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct HomeView: View {
    @State private var images: [ImageModel] = []

    var body: some View {
        ContentView(images: $images)
    }
}

struct ContentView: View {
    
    @Binding private var images: [ImageModel]
    
    @State private var selectedImage: ImageModel?
    @State private var editedImage: UIImage?
    
    @State private var isShowingPopup: Bool = false

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
            .navigationTitle("Eulerity Hackathon")
            .navigationBarItems(trailing:
                                    Button(action: {
                isShowingPopup = true
                
            }) {
                Image(systemName: "info.circle")
                    .font(.subheadline)
                
            })
        }
        .onAppear {
            getImages()
        }
        .sheet(item: $selectedImage, onDismiss: {
            editedImage = nil // Reset editedImage when the sheet is dismissed
            
        }) { image in
            ImageEditorView(image: image, editedImage: $editedImage) { editedImage in postImage(editedImage)
            }
        }
        .alert(isPresented: $isShowingPopup) {
            Alert(title: Text("Why you should hire me?"),
                  message: Text("\nDear Hiring Manager,\n\n As a motivated and aspiring iOS developer, I am eager to gain hands-on experience and further enhance my skills in a professional environment.\n\nI believe that this internship opportunity at Eulerity would provide me with valuable learning opportunities and contribute to my growth as an iOS developer.\n\nThank you for considering my application. I am excited about the possibility of joining the Eulerity team and making meaningful contributions.\n\nBest regards,\nGaurav Bhambhani"), dismissButton: .default(Text("OK"))
            )
        }
    }

    private func getImages() {
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

    private func postImage(_ image: UIImage) {
        
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

                    postImage(to: uploadURL, image: image)
                } else {
                    print("Invalid JSON response")
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func postImage(to url: URL, image: UIImage) {
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
                    if let data = data {
                        let responseString = String(data: data, encoding: .utf8)
                        print("Error response: \(responseString ?? "")")
                    }
                }
            }
        }.resume()
    }
}

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
