import SwiftUI
import PrepDataTypes

extension FoodForm {
    
    var imagesDict: [UUID: UIImage] {
        var dict: [UUID: UIImage] = [:]
        for imageModel in sources.imageModels {
            guard let image = imageModel.image else { continue }
            dict[imageModel.id] = image
        }
        return dict
    }
    
    func foodFormOutput(shouldPublish: Bool) -> FoodFormOutput? {
        guard
            let fieldsAndSources = FoodFormFieldsAndSources(fields: fields, sources: sources, shouldPublish: shouldPublish),
            let createForm = fieldsAndSources.createForm,
            let jsonData = try? JSONEncoder().encode(fieldsAndSources)
        else {
            return nil
        }
        
        return FoodFormOutput(
            createForm: createForm,
            fieldsAndSourcesJSONData: jsonData,
            images: imagesDict,
            shouldPublish: shouldPublish)
    }
}
