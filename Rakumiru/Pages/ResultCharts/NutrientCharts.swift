import SwiftUI
import Charts

struct NutrientBalanceChart: View {
    var userImages: [ImageData]
    
    var nutrientCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for image in userImages {
            for meal in image.meals ?? [] {
                counts[meal.nutrients, default: 0] += 1
            }
        }
        return counts
    }
    
    var body: some View {
        Chart {
            ForEach(nutrientCounts.sorted(by: >), id: \.key) { nutrient, count in
                BarMark(
                    x: .value("Nutrient", nutrient),
                    y: .value("Count", count)
                )
                .foregroundStyle(.green)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
        .frame(height: 300)
        .padding()
    }
}
