import SwiftUI
import Timeline
import PrepDataTypes

extension TimeForm {
    class ViewModel: ObservableObject {
        @Published var time: Date = Date()
    }
}
