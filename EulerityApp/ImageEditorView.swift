//
//  ImageEditorView.swift
//  EulerityApp
//
//  Created by Gaurav Bhambhani on 6/12/23.
//

import SwiftUI

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
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(uiImage: image.image ?? UIImage(systemName: "photo")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
                if isOverlayAdded {
                    TextOverlay(text: overlayText)
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
            
            
            Spacer()
                        
            VStack {
                HStack {
                    Button(action: {
                        isOverlayAdded = true
                        
                    }) {
                        Image(systemName: "text.bubble")
                        Text("Add Text")
                        
                    }
                    .disabled(isOverlayAdded)
                    
                    Button(action: {
                        isOverlayAdded = false
                        
                    }) {
                        Image(systemName: "xmark")
                        Text("Remove Text")
                    }
                    .disabled(!isOverlayAdded)
                    
                }
                .padding(.bottom)
                HStack {
                    Button(action: {
                        applyFilter()
                    }) {
                        Image(systemName: "wand.and.stars")
                        Text("Apply Filter")
                        
                    }
                    Button(action: {
                        removeFilter()
                    }) {
                        Image(systemName: "wand.and.stars.inverse")
                        Text("Remove Filter")
                        
                    }
                    
                }
                .padding(.bottom)
                            
                Button(action: {
                    if let editedImage = editedImage, let newImage = addOverlayText(to: editedImage) {
                        onDone(newImage)
                        
                    } else if let newImage = addOverlayText(to: image.image ?? UIImage()) {
                        onDone(newImage)
                    }
                    
                }) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Upload")
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
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

    private func removeFilter() {
        editedImage = nil
    }

    private func addOverlayText(to image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        guard UIGraphicsGetCurrentContext() != nil else { return nil }

        image.draw(in: CGRect(origin: .zero, size: image.size))

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

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }

        return newImage
    }
}
