# Eulerity Hackathon App

<img src="https://github.com/GauravVBhambhani/EulerityApp/assets/113461154/74fb9cdc-0c38-4072-96f5-792758e457d5" width="300">

This is the first page of the application. I have fetched all the images from the give /image url.


<img src="https://github.com/GauravVBhambhani/EulerityApp/assets/113461154/e5732058-90f7-44f0-80df-8acc31aab158" width="300">

This is the ImageEditorView page where the user, when they select an image, lands. Here, the user can make changes to the image.
Here, the user can apply a filter and add a text overlay.
 
<img src="https://github.com/GauravVBhambhani/EulerityApp/assets/113461154/88540958-8dc3-40b5-8a26-f53b15225753" width="300">

<img src="https://github.com/GauravVBhambhani/EulerityApp/assets/113461154/e6717081-3dac-4d47-b61b-f88cd0b56489" width="300">

The user can then upload the image to the given /upload url.

<img src="https://github.com/GauravVBhambhani/EulerityApp/assets/113461154/20bc65ca-3bd4-4259-8a3c-201ca23be3ed" width="600">

This is the App uploads page that allowed me to test my application.


## Learnings
Throughout the development of this project using SwiftUI, I gained valuable knowledge and experience. Here are some of the key learnings:

### Data Flow: 
SwiftUI's data flow paradigm, including @State, @Binding, and @StateObject, helped me manage and propagate changes in my app's state. I learned how to use @State to create mutable state variables within a view and @Binding to share data between parent and child views.

### Asynchronous Image Loading: 
I explored techniques to load images asynchronously in SwiftUI. By using SwiftUI's Image view and the URLSession API to make GET requests for image URLs, I learned how to handle the asynchronous nature of network requests and display images once they were retrieved.

### Editing Images: 
SwiftUI provided a versatile set of tools for editing images. I learned how to apply filters to images using Core Image filters like sepiaTone() and adjust their parameters. Additionally, I discovered how to overlay text on images using SwiftUI's Text view and modifying its attributes.

### Networking: 
I became proficient in making network requests using SwiftUI. I learned how to use URLSession to make GET and POST requests, parse JSON responses, and handle multipart/form-data encoding for file uploads.

### Error Handling: 
I encountered various scenarios where error handling was necessary, such as network failures or unsuccessful requests. I learned how to handle errors gracefully using SwiftUI's features like alerts and error presentation.

### Project Structure and Organization: 
Developing the project allowed me to understand the importance of project structure and code organization. I learned how to create reusable views and separate concerns to improve code maintainability and readability.

### Debugging and Troubleshooting: 
During the development process, I faced various issues and bugs. I developed skills in debugging and troubleshooting by leveraging SwiftUI's debugging tools, such as inspecting view hierarchies and examining state changes.
