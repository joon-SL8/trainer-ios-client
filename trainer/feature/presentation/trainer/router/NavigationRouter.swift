import SwiftUI
import Combine

public class NavigationRouter: ObservableObject {
    @Published public var path = NavigationPath()
    
    public init() {}
    
    public func navigate(to destination: any Hashable) {
        path.append(destination)
    }
    
    public func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    public func popToRoot() {
        path = NavigationPath()
    }
}
