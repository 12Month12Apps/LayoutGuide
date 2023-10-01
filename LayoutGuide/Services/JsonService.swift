//
//  JsonService.swift
//  LayoutGuide
//
//  Created by Veit Progl on 01.10.23.
//

import Foundation
import SwiftUI

struct Layer: Identifiable, Codable {
    internal init(title: String, imageString: String, id: String) {
        self.title = title
        self.imageString = imageString
        self.id = id
    }
    
    var title: String
    var image: Image? {
        get {
            guard let nsImage = convertBase64ToImage() else { return nil }
            return Image(nsImage:  nsImage)
        }
        set {
            
        }
    }
    var imageString: String
    var id: String
    
    private enum CodingKeys: String, CodingKey {
        case title, image, imageString, id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        imageString = try container.decode(String.self, forKey: .imageString)
        id = try container.decode(String.self, forKey: .id)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(imageString, forKey: .imageString)
        try container.encode(id, forKey: .id)
    }
    
    func convertBase64ToImage() -> NSImage? {
        let base64String = self.imageString
        if let imageData = Data(base64Encoded: base64String) {
            if let image = NSImage(data: imageData) {
                return image
            }
        }
        return nil
    }
}


protocol JsonService {
    
}

class JsonServiceImpl: JsonService {
    private func convertJsonToLayers(json: Data) throws -> [Layer] {
        let decoder = JSONDecoder()
        let layers = try decoder.decode([Layer].self, from: json)
        return layers
    }
    
    private func convertLayerToJson(layer: Layer) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(layer)
    }
    
    func saveDataToUserDefaults(data: Data, forKey key: String) {
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func save(layer: Layer) {
        do {
            // Retrieve existing JSON array from UserDefaults
            var existingLayers: [Layer] = []
            if let savedData = UserDefaults.standard.data(forKey: "layers") {
                existingLayers = try convertJsonToLayers(json: savedData)
            }
            
            // Append new layer to the existing array
            existingLayers.append(layer)
            
            // Convert updated array to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let updatedJson = try encoder.encode(existingLayers)
            
            // Save updated JSON array to UserDefaults
            saveDataToUserDefaults(data: updatedJson, forKey: "layers")
        } catch {
            print("Error saving layer: \(error)")
        }
    }
    
    func loadLayers() -> [Layer] {
        do {
            if let savedData = UserDefaults.standard.data(forKey: "layers") {
                let layers = try convertJsonToLayers(json: savedData)
                return layers
            }
        } catch {
            print("Error loading layers: \(error)")
        }
        return []
    }
    
    func remove(layer: Layer) {
        do {
            // Retrieve existing JSON array from UserDefaults
            if let savedData = UserDefaults.standard.data(forKey: "layers") {
                var existingLayers = try convertJsonToLayers(json: savedData)
                
                // Find and remove the desired layer from the array
                if let index = existingLayers.firstIndex(where: { $0.id == layer.id }) {
                    existingLayers.remove(at: index)
                }
                
                // Convert updated array to JSON
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let updatedJson = try encoder.encode(existingLayers)
                
                // Save updated JSON array to UserDefaults
                saveDataToUserDefaults(data: updatedJson, forKey: "layers")
            }
        } catch {
            print("Error removing layer: \(error)")
        }
    }
}
