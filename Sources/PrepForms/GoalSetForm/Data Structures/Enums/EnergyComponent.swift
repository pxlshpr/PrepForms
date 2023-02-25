import Foundation

enum EnergyComponent {
    case resting
    case active
    
    var systemImage: String {
        switch self {
        case .resting:
            return "bed.double.fill"
        case .active:
            return "figure.walk.motion"
        }
    }
}
