import Foundation
import libfitness

public struct UpdateCustomProfileUseCase {
    public init() {}
    
    public func invoke(input: UpdateCustomInput) {
        UserDefaults.standard.set(input.value, forKey: input.key)
    }
}

public struct GetCustomProfileUseCase {
    public init() {}
    
    public func invoke(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
}
