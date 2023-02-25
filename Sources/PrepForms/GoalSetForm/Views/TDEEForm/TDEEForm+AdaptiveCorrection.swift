import SwiftUI
import SwiftHaptics

extension TDEEForm {
    var adaptiveCorrectionSection: some View {
        
        var footer: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text("A correction will be applied to your maintenance calories based on the fluctuations in your weight over time.")
                Button {
                    Haptics.feedback(style: .soft)
                    showingAdaptiveCorrectionInfo = true
                } label: {
                    Label("Learn More", systemImage: "info.circle")
                        .font(.footnote)
                }
                .sheet(isPresented: $showingAdaptiveCorrectionInfo) {
                    NavigationView {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 5) {
                                /// Possibly: Mention the paper by Max Wishnofsky [mentioned here](https://www.verywellfit.com/running-to-lose-weight-how-many-calories-in-a-pound-2911107). Talk about how We'll be assuming that 500 kcal/day deficit equates to about 0.45 kg (following the 1pound/week rule) and
                                Text("Talk about how resting energy calculations are very approximate, and that they are different for everyone. Mention how using a formula is also a very rough approximation and that each person has indivudal differences that can make their BMR vary quite a bit.")
                                Text("Mention how this feature will observe the fluctuations in their weight, against the food that they log — and statistically derive what their true maintenance calories are.")
                                Text("Be transparent here and show a clear diagram of what we're doing: We will place it in the following equation weeklymaintenance+food eaten = x kg. So by placing their true weight change in that equation we'll then determine what their true weekly maintenance is.")
                                Text("")
                                Text("This will hopefully account for any errors in the calculation of their TDEE (either by a formula or using data from Apple Health), and provide them with a clearer guideline of how much to eat going forward, in order to meet their weight goals.")
                                Text("Mention how in order for this to work accurately—the user would have to consistently log their food and weigh themselves at least a few times per week.")
                            }
                        }
                        .navigationTitle("How Adaptive Correction Works")
                        .navigationBarTitleDisplayMode(.inline)
                        .padding(.horizontal)
                    }
                    .presentationDetents([.medium])
                }
            }
        }
        
        return Section(footer: footer) {
            HStack {
                //TODO: Toggling this on should ask for weight permission if not already received for BMR.
                Text("Use Adaptive Correction")
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: .constant(true))
            }
        }
    }
}
