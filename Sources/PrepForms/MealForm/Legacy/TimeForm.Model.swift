import SwiftUI
import Timeline
import PrepDataTypes

extension TimeForm {
    class Model: ObservableObject {
        @Published var time: Date = Date()
    }
}
