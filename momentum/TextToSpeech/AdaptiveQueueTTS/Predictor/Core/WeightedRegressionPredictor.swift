import Foundation

class WeightedRegressionPredictor {
    private let predictor: LinearRegressionPredictor = .init()
    struct PredictorConfiguration {
        let maxDataPoints: Int
        let weightMultipliers: [(range: CountableRange<Int>, weight: Int)]
        let nonnegativeSlope: Bool
    }
    
    private let config: PredictorConfiguration
    
    init(config: PredictorConfiguration) {
        self.config = config
    }
    
    func fit(data: [(Double, Double)]) {
        let weightedData = applyWeights(data)
        predictor.fit(weightedData.map { $0.0 }, weightedData.map { $0.1 }, slopeMustBeNonnegative: config.nonnegativeSlope)
    }
    
    func predict(_ x: Double) -> Double {
        return predictor.predict(x)
    }
    
    func predictWithPercentile(_ x: Double, percentile: Double) -> Double {
        return predictor.predictWithPercentile(x, percentile: percentile)
    }
    
    private func applyWeights(_ data: [(Double, Double)]) -> [(Double, Double)] {
        if config.weightMultipliers.isEmpty {
            return data // No weighting applied
        }

        var weightedData: [(Double, Double)] = []
        let n = data.count
        for (range, weight) in config.weightMultipliers {
            if n >= range.upperBound {
                let recentData = data[(n - range.upperBound)..<(n - range.lowerBound)]
                weightedData.append(contentsOf: Array(repeating: recentData, count: weight).flatMap { $0 })
            }
        }
        return weightedData
    }
}
