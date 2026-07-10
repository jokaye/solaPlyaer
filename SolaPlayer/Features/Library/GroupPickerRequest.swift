import Foundation

struct GroupPickerRequest: Identifiable {
    let id = UUID()
    let items: [AudioItem]
}
