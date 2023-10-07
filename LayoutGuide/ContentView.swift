//
//  ContentView.swift
//  LayoutGuide
//
//  Created by Veit Progl on 17.09.23.
//

import SwiftUI
import KeyboardShortcuts

enum navigationViews {
    case addLayer
    case layer(Layer)
    case settings
}

struct SettingsScreen: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle Menubar Window:", name: .toggleMenubarWindow)
        }
    }
}

public struct LayoutApp: View {
    var isPopup: Bool
    @State var mainView = navigationViews.addLayer
    @State var layers: [Layer] = [Layer(title: "Example", imageString: "", id: "123")]
    var jsonService = JsonServiceImpl()
    @State private var selectedLayerIndex: Int? = nil
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var appState: AppState

    public init(isPopup: Bool, appState: AppState) {
        self.isPopup = isPopup
        self.appState = appState
    }
    
    public var body: some View {
        NavigationView () {
            List() {
                Text("Layers")
                    .font(.title)

                if layers.count == 0{
                    VStack {
                        Text("Open Window with:")
                        Text("Cmd + Shift + L")
                    }
                } else {
                    ForEach(layers.indices, id: \.self) { index in
                        Button(action: {
                            selectedLayerIndex = index
                            mainView = .layer(layers[index])
                        }, label: {
                            Text(layers[index].title)
                                .padding([.vertical], 5)
                                .frame(minWidth: 0, maxWidth: .infinity)
                        })
                        .tag(index)
                    }
                }
                
                Spacer()
                    .frame(minHeight: 0, maxHeight: .infinity)
                
                if !isPopup {
                    Button(action: {
                        mainView = .addLayer
                    },label: {
                        Text("Add Layer")
                            .padding([.vertical], 5)
                            .frame(minWidth: 0, maxWidth: .infinity)
                    })
                    
                    Button(action: {
                        mainView = .settings
                    }, label: {
                        Text("Settings")
                            .padding([.vertical], 5)
                            .frame(minWidth: 0, maxWidth: .infinity)
                    })
                } else {
                    Button(action: {
                        openWindow(id: "Settings")
                    },label: {
                        Text("Open Window")
                            .padding([.vertical], 5)
                            .frame(minWidth: 0, maxWidth: .infinity)
                    })
                    
                    Button(action: {
                        NSApplication.shared.terminate(self)
                    }, label: {
                        Text("Close App")
                            .padding([.vertical], 5)
                            .frame(minWidth: 0, maxWidth: .infinity)
                    })
                }
            }.listStyle(.sidebar)
            
            switch mainView {
            case .addLayer:
                AddLayer(layers: $layers)
            case .layer(let layer):
                LayerView(isPopup: isPopup, layers: $layers, layer: layer)
                    .id(layer.id)
            case .settings:
                SettingsScreen()
            }
        }.frame(minWidth: 500, minHeight: 500)
        .onAppear(perform: {
            self.layers = jsonService.loadLayers()
            if isPopup {
                if let layer = layers.first {
                    mainView = .layer(layer)
                }
            }
        })
        .background {
            Group {
                Button(action: { navigateLayers(direction: -1) }) {}
                    .keyboardShortcut(.upArrow, modifiers: [])
                Button(action: { navigateLayers(direction: 1) }) {}
                    .keyboardShortcut(.downArrow, modifiers: [])
            }.opacity(0)
        }
        .handlesExternalEvents(preferring: Set(arrayLiteral: "*"), allowing: Set(arrayLiteral: "*"))
    }

    func navigateLayers(direction: Int) {
        if let currentIndex = selectedLayerIndex {
            let newIndex = (currentIndex + direction + layers.count) % layers.count
            selectedLayerIndex = newIndex
            mainView = .layer(layers[newIndex])
        } else if !layers.isEmpty {
            selectedLayerIndex = 0
            mainView = .layer(layers[0])
        }
    }
}

struct LayerView: View {
    var isPopup: Bool
    @Binding var layers: [Layer]
    @State var layer: Layer
    var jsonService = JsonServiceImpl()

    var body: some View {
        VStack {
//            Text(layer.title)
            
            if let image = layer.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 750)
            }
            
            if !isPopup {
                Button("Delete") {
                    jsonService.remove(layer: layer)
                    layers = jsonService.loadLayers()
                }
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

//#Preview {
//    ContentView()
//    LayoutApp(isPopup: false, appState: AppState)
//}
