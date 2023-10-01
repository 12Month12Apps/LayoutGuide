//
//  JsonService.swift
//  LayoutGuide
//
//  Created by Veit Progl on 01.10.23.
//

import Foundation
import SwiftUI

struct Layer: Identifiable {
    var title: String
    var image: Image?
    var imageString: String
    var id: String
}


protocol JsonService {
    
}

class JsonServiceImpl: JsonService {
    private func loadJson<T: Decodable>(filename fileName: String) -> T? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("error:\(error)")
        }
        return nil
    }
    
    private func createJson<T: Encodable>(filename fileName: String, data: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(data)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            print(jsonString)
        } catch {
            print(error)
        }
    }
    
    func save(image: Image) {
//        image.conte
    }

}
