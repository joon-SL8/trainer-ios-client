import Foundation
import Combine

public protocol SensorDataSource: ObservableObject {
    var sensorData: String { get }
}

public class Sensor<Source: SensorDataSource>: ObservableObject {
    @Published public var status: Status
    @Published public var sensorType: SensorType
    @Published public var name: String
    @Published public var data: String
    
    public var source: Source?
    private var cancellables = Set<AnyCancellable>()
    
    public init(status: Status, sensorType: SensorType, name: String, data: String, source: Source? = nil) {
        self.status = status
        self.sensorType = sensorType
        self.name = name
        self.data = data
        self.source = source
        
        setupObservation()
    }
    
    private func setupObservation() {
        source?.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, let source = self.source else { return }
                self.data = source.sensorData
            }
            .store(in: &cancellables)
    }
}
