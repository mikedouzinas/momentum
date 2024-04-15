import Foundation

class LinearRegressionPredictor {
    private var slope: Double = 0.0
    private var intercept: Double = 0.0
    private var sortedResiduals: [Double] = []
    
    func fit(_ features: [Double], _ targets: [Double], slopeMustBeNonnegative: Bool) {
        // Perform linear regression using OLS
        let meanFeature = features.reduce(0, +) / Double(features.count)
        let meanTarget = targets.reduce(0, +) / Double(targets.count)
        
        var numerator: Double = 0.0
        var denominator: Double = 0.0
        
        for (feature, target) in zip(features, targets) {
            numerator += (feature - meanFeature) * (target - meanTarget)
            denominator += pow(feature - meanFeature, 2)
        }
        
        slope = numerator / denominator
        if slopeMustBeNonnegative {
            slope = max(slope, 0)
        }
        intercept = meanTarget - slope * meanFeature
        
        // Calculate and sort residuals
        let residuals = targets.map { target in
            target - (slope * features[targets.firstIndex(of: target)!] + intercept)
        }
        sortedResiduals = residuals.sorted()
    }
    
    func predict(_ feature: Double) -> Double {
        // Predict the target value using the linear regression model
        return slope * feature + intercept
    }
    
    func predictWithPercentile(_ feature: Double, percentile: Double) -> Double {
        // Predict the target value using the linear regression model
        // and add a percentile-based buffer
        let prediction = predict(feature)
        let percentileValue = getPercentileValue(percentile)
        return prediction + percentileValue
    }
    
    private func getPercentileValue(_ percentile: Double) -> Double {
        // Get the percentile value from the sorted residuals
        let index = Int(percentile * Double(sortedResiduals.count) / 100)
        return sortedResiduals[index]
    }
}
