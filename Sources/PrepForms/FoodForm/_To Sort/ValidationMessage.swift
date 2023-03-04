import Foundation

enum ValidationMessage {
    case needsSource
    case missingFields([String])
    case notEnoughIngredients
}
