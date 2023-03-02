import SwiftUI

class FiltersSheetViewModel: ObservableObject {
    @Published var databaseFilters: [Filter] = allDatabases {
        didSet {
            withAnimation {
                onlyOneDatabaseIsSelected = databaseFilters.selectedCount == 1
                footerText = getFooterText()
            }
        }
    }
    @Published var typeFilters: [Filter] = allTypes {
        didSet {
            withAnimation {
                onlyOneTypeIsSelected = typeFilters.selectedCount == 1
                footerText = getFooterText()
            }
        }
    }
    @Published var onlyOneDatabaseIsSelected: Bool
    @Published var onlyOneTypeIsSelected: Bool
    @Published var footerText: Text
    
    init() {
        //TODO: Read in and set defaults here
        self.databaseFilters = allDatabases
        self.typeFilters = allTypes
        self.onlyOneDatabaseIsSelected = allDatabases.selectedCount == 1
        self.onlyOneTypeIsSelected = allTypes.selectedCount == 1
        self.footerText = Text("")
    }
    
    var foodsCount: Int {
        //TODO: Get this from the backend
        /// We should store these values in UserDefaults.
        /// Update it silently in the background whenever the app or this sheet is opened.
        let verifiedFoods = 13543
        let verifiedRecipes = 523
        let verifiedPlates = 93
        let myFoods = 154
        let myRecipes = 12
        let myPlates = 4
        let usdaFoods = 381939
        let usdaRecipes = 0
        let usdaPlates = 0
        let ausnutFoods = 5740
        let ausnutRecipes = 0
        let ausnutPlates = 0
        
        var count = 0
        if verifiedSelected {
            if foodsSelected { count += verifiedFoods }
            if recipesSelected { count += verifiedRecipes }
            if platesSelected { count += verifiedPlates }
        }
        if yourDatabaseSelected {
            if foodsSelected { count += myFoods }
            if recipesSelected { count += myRecipes }
            if platesSelected { count += myPlates }
        }
        if usdaSelected {
            if foodsSelected { count += usdaFoods }
            if recipesSelected { count += usdaRecipes }
            if platesSelected { count += usdaPlates }
        }
        if ausnutSelected {
            if foodsSelected { count += ausnutFoods }
            if recipesSelected { count += ausnutRecipes }
            if platesSelected { count += ausnutPlates }
        }
        return count
    }
    
    var typesSuffix: String {
        if foodsSelected {
            if recipesSelected {
                if platesSelected {
                    return "foods, recipes and plates"
                } else {
                    return "foods and recipes"
                }
            } else if platesSelected {
                return "foods and plates"
            } else {
                return "foods"
            }
        } else {
            if recipesSelected {
                if platesSelected {
                    return "recipes and plates"
                } else {
                    return "recipes"
                }
            } else {
                return "plates"
            }
        }
    }

    func getFooterText() -> Text {
        Text("You are searching \(foodsCount) \(typesSuffix).")
    }
    
    var verifiedSelected: Bool {
        databaseFilters.first(where: { $0.name == "Verified" })?.isSelected == true
    }
    var yourDatabaseSelected: Bool {
        databaseFilters.first(where: { $0.name == "Your Database" })?.isSelected == true
    }
    var usdaSelected: Bool {
        databaseFilters.first(where: { $0.name == "USDA" })?.isSelected == true
    }
    var ausnutSelected: Bool {
        databaseFilters.first(where: { $0.name == "AUSNUT" })?.isSelected == true
    }

    var foodsSelected: Bool {
        typeFilters.first(where: { $0.name == "Foods" })?.isSelected == true
    }
    var platesSelected: Bool {
        typeFilters.first(where: { $0.name == "Plates" })?.isSelected == true
    }
    var recipesSelected: Bool {
        typeFilters.first(where: { $0.name == "Recipes" })?.isSelected == true
    }
}
