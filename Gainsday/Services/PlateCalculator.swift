import Foundation

enum PlateCalculator {
    static func platesPerSide(total: Double, barWeight: Double = 45,
                              available: [Double] = [45, 35, 25, 10, 5, 2.5]) -> [Double] {
        var remaining = max(0, (total - barWeight) / 2)
        var result: [Double] = []
        for plate in available where remaining >= plate - 0.01 {
            while remaining >= plate - 0.01 {
                result.append(plate)
                remaining -= plate
            }
        }
        return result
    }

    static func label(total: Double) -> String {
        let plates = platesPerSide(total: total)
        guard !plates.isEmpty else { return "Bar only" }
        return plates.map { $0.truncatingRemainder(dividingBy: 1) == 0 ? String(Int($0)) : String($0) }
            .joined(separator: " + ")
    }
}
