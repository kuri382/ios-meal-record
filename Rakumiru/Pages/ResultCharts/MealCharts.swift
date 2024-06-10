import SwiftUI
import Charts

struct MealCharts: View {
    var userImages: [ImageData]
    
    var averageRemainings: [(index: Int, average: Double)] {
        userImages.enumerated().map { index, image in
            let totalRemaining = image.meals?.reduce(0.0) { $0 + $1.remaining } ?? 0.0
            let count = image.meals?.count ?? 1
            return (index, totalRemaining / Double(count) * 100)
        }
    }
    
    var body: some View {
        Chart {
            ForEach(averageRemainings, id: \.index) { entry in
                LineMark(
                    x: .value("Record", entry.index),
                    y: .value("Average Remaining", entry.average)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue)
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
