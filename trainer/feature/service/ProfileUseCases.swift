import Foundation
import libfitness

public struct UpdateCustomProfileUseCase {
    public init() {}
    
    public func invoke(input: UpdateCustomInput) async {
        let usecase = libfitness.UpdateCustomProfileUseCase()
        let ucInput = libfitness.UpdateCustomInput(key: input.key, data: input.value)
        let result = try? await usecase.invoke(input: ucInput) as? UpdateCustomDataResult
        print("persisting \(input.key)")
    }
}

public struct GetCustomProfileUseCase {
    public init() {}
    
    public func invoke(key: String) async -> String? {
        let usecase = libfitness.GetCustomProfileUseCase()
        let input = GetProfileInput(key: key)
        let result = try? await usecase.invoke(input: input) as? GetDataResult
        return result?.data ?? ""
    }
}
