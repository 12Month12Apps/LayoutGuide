//
//  ContentView.swift
//  LayoutGuide
//
//  Created by Veit Progl on 17.09.23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

enum navigationViews {
    case addLayer
    case layer(Layer)
}

struct SettingsApp: View {
    
    @State var mainView = navigationViews.addLayer
    @State var layers: [Layer] = [Layer(title: "test", imageString: "", id: "123")]
    var jsonService = JsonServiceImpl()

    var body: some View {
        NavigationView () {
            List() {
                Text("Layers")
                    .font(.title)

                ForEach(layers) { layer in
                    Button(action: {
                        mainView = .layer(layer)
                    }, label: {
                        Text(layer.title)
                            .padding([.vertical], 5)
                            .frame(minWidth: 0, maxWidth: .infinity)
                    })
                }
                
                Spacer()
                    .frame(minHeight: 0, maxHeight: .infinity)
                
                Button(action: {
                    mainView = .addLayer
                },label: {
                    Text("Add Layer")
                        .padding([.vertical], 5)
                        .frame(minWidth: 0, maxWidth: .infinity)
                })
            }.listStyle(.sidebar)
            
            switch mainView {
            case .addLayer:
                AddLayer(layers: $layers)
            case .layer(let layer):
                LayerView(layers: $layers, layer: layer)
                    .id(layer.id)
            }
        }.frame(minWidth: 500, minHeight: 500)
        .onAppear(perform: {
            self.layers = jsonService.loadLayers()
        })
    }
}

struct LayerView: View {
    @Binding var layers: [Layer]
    @State var layer: Layer
    var jsonService = JsonServiceImpl()

    var body: some View {
        VStack {
            Text(layer.title)
            
            if let image = layer.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300)
            }
            
            Button("Delete") {
                jsonService.remove(layer: layer)
                layers = jsonService.loadLayers()
            }
        }
    }
}

struct AddLayer: View {
    @Binding var layers: [Layer]
    @State var title: String = ""
    @State var image: NSImage?
    var jsonService = JsonServiceImpl()
    
    var body: some View {
        VStack {
            TextField("Name:", text: $title)
                .textFieldStyle(.roundedBorder)
                .padding()
            Spacer()

            FileView(image: $image)
            
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300)
            }
            
            Spacer()
            
            Button("Save") {
                if let imageString = convertImageToBase64() {
                    let layer = Layer(title: self.title, imageString: imageString, id: UUID().uuidString)
                    jsonService.save(layer: layer)
                    layers.append(layer)
                } else {
                    
                }
            }
            .padding([.bottom], 50)
        }
    }
    
    func convertImageToBase64() -> String? {
        guard let image = image else { return nil }
        if let imageData = image.tiffRepresentation,
            let bitmapRep = NSBitmapImageRep(data: imageData),
            let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            
            let base64String = pngData.base64EncodedString()
            return base64String
        }
        return nil
    }
}

struct FileView: View {
    @Binding var image: NSImage?
    var body: some View {
        VStack {
            Button("Select File") {
                let openPanel = NSOpenPanel()
                openPanel.prompt = "Select File"
                openPanel.allowsMultipleSelection = false
                    openPanel.canChooseDirectories = false
                    openPanel.canCreateDirectories = false
                    openPanel.canChooseFiles = true
                    openPanel.allowedContentTypes = [.png, .jpeg]
                    openPanel.begin { (result) -> Void in
                        if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                            let selectedPath = openPanel.url!.path
                            print(selectedPath)
                            image = readImage(url: selectedPath)
                        }
                    }
            }
        }
    }
    
    func readImage(url: String) -> NSImage? {
        let manager = FileManager.default
        let imagePath = url
        
        if manager.fileExists(atPath: imagePath) {
            let image = NSImage(contentsOfFile: imagePath)
            return image
        } else {
            return nil
        }
    }
}

#Preview {
//    ContentView()
    SettingsApp()
}
