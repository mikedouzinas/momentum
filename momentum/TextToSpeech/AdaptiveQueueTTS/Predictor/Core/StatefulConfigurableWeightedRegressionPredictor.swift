import Foundation

actor StatefulConfigurableWeightedRegressionPredictor {
    struct PredictorConfiguration {
        let maxDataPoints: Int
        let weightMultipliers: [(range: CountableRange<Int>, weight: Int)]
        let nonnegativeSlope: Bool
        let reliableSampleCount: Int
        let conservativePredictionWeight: Double
        let conservativePredictionBias: Double
        
        func asWeightedRegressionPredictorConfiguration() -> WeightedRegressionPredictor.PredictorConfiguration {
            return .init(
                maxDataPoints: maxDataPoints,
                weightMultipliers: weightMultipliers,
                nonnegativeSlope: nonnegativeSlope
            )
        }
    }
    
    private class UserDefaultsStorage {
        private let defaults: UserDefaults
        
        init(defaults: UserDefaults = .standard) {
            self.defaults = defaults
        }
        
        func save(_ data: [(Double, Double)], key: String) {
            let encodedData = data.map { [$0.0, $0.1] }
            defaults.set(encodedData, forKey: key)
        }
        
        func load(key: String) -> [(Double, Double)]? {
            guard let encodedData = defaults.array(forKey: key) as? [[Double]] else {
                return nil
            }
            return encodedData.map { ($0[0], $0[1]) }
        }
    }
    
    private let predictor: WeightedRegressionPredictor
    private let storage: UserDefaultsStorage = .init(defaults: .standard)
    private let storageKey: String
    private let config: PredictorConfiguration

    
    private var recentData: [(Double, Double)] = []
    private var isDirty: Bool = true
    
    func getSampleCount() -> Int {
        return recentData.count
    }
    
    init(config: PredictorConfiguration, storageKey: String) {
        self.storageKey = storageKey
        self.config = config
        self.predictor = .init(config: config.asWeightedRegressionPredictorConfiguration())
        self.recentData = storage.load(key: storageKey) ?? []
    }
    
    func addDataPoint(_ x: Double, _ y: Double) {
        recentData.append((x, y))
        if recentData.count > config.maxDataPoints {
            recentData.removeFirst()
        }
        storage.save(recentData, key: storageKey)
        isDirty = true
    }
    
    private func fit() {
        guard isDirty else { return }
        
        predictor.fit(data: recentData)
        
        isDirty = false
    }
    
    func predict(_ x: Double) -> Double {
        fit()
        return predictor.predict(x)
    }
    
    func predictWithPercentile(_ x: Double, percentile: Double) -> Double {
        fit()
        return predictor.predictWithPercentile(x, percentile: percentile)
    }
    
    func getConservativeLowPrediction(_ x: Double) -> Double {
        if getSampleCount() < self.config.reliableSampleCount {
            return 0
        } else {
            return predictWithPercentile(x, percentile: 5) * (1 - config.conservativePredictionWeight) - config.conservativePredictionBias
        }
    }
    
    func getConservativeHighPrediction(_ x: Double) -> Double {
        if getSampleCount() < self.config.reliableSampleCount {
            return .greatestFiniteMagnitude
        } else {
            return predictWithPercentile(x, percentile: 95) * (1 + config.conservativePredictionWeight) + config.conservativePredictionBias
        }
    }
}

extension StatefulConfigurableWeightedRegressionPredictor.PredictorConfiguration {
    static func audioDurationPredictorConfiguration() -> StatefulConfigurableWeightedRegressionPredictor.PredictorConfiguration {
        return .init(
            maxDataPoints: 1000,
            weightMultipliers: [],
            nonnegativeSlope: true,
            reliableSampleCount: 20,
            conservativePredictionWeight: 0.2,
            conservativePredictionBias: 0
        )
    }
    
    static func apiResponseTimePredictorConfiguration() -> StatefulConfigurableWeightedRegressionPredictor.PredictorConfiguration {
        return .init(
            maxDataPoints: 30,
            weightMultipliers: [((0..<5), 6), ((5..<10), 4), ((10..<20), 3), ((20..<30), 2)],
            nonnegativeSlope: true,
            reliableSampleCount: 10,
            conservativePredictionWeight: 0.2,
            conservativePredictionBias: 1.5
        )
    }
}
