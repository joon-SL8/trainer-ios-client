import Foundation
import Combine
import libfitness

class SessionStore: ObservableObject {
    static let shared = SessionStore()
    @Published var didUpdateSessions: Bool = false
    
    private init() {}
    
    func notifySessionCompleted() {
        DispatchQueue.main.async {
            self.didUpdateSessions.toggle()
        }
    }
}
