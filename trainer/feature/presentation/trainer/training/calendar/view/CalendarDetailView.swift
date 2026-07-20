import SwiftUI
import libfitness

struct CalendarDetailView: View {
    @StateObject var viewModel: CalendarDetailViewModel

    init(session: libfitness.Session) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading details...")
            } else {
                VStack(spacing: 20) {
                    Text(viewModel.session.name)
                        .font(.largeTitle)

                    if let tss = viewModel.tss, let np = viewModel.np {
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text("TSS").font(.caption).foregroundColor(.secondary)
                                let data = tss > 0 && tss < 2000 ? String(format: "%.0f W", tss) : "-"
                                Text(data).font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 4) {
                                Text("NP").font(.caption).foregroundColor(.secondary)
                                let data = np > 0 && np < 2000 ? String(format: "%.0f W", np) : "-"
                                Text(data).font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 48)
                    }

                    LineGraphView(title: "Power", data: viewModel.sessionEntries.map { Double($0.power) })
                    LineGraphView(title: "Heart Rate", data: viewModel.sessionEntries.map { Double($0.heart) })
                    LineGraphView(title: "Cadence", data: viewModel.sessionEntries.map { Double($0.cadence) })
                    LineGraphView(title: "Speed", data: viewModel.sessionEntries.map { Double($0.speed) })
                }
                .padding(.horizontal, 48)
                .padding(.vertical)
            }
        }
        .navigationTitle("Session Details")
    }
}

struct LineGraphView: View {
    let title: String
    let data: [Double]

    private var average: Double {
        data.isEmpty ? 0 : data.reduce(0, +) / Double(data.count)
    }

    // Total duration in seconds
    private var durationSeconds: Int { data.count }

    // Determine interval in seconds
    private var labelInterval: Int {
        let minutes = durationSeconds / 60
        if minutes > 240 { return 3600 }      // > 4 hours: per hour
        if minutes > 90 { return 1800 }       // 90m - 4h: per 30 mins
        if minutes > 30 { return 900 }        // 30m - 90m: per 15 mins
        if minutes > 10 { return 300 }        // 10m - 30m: per 5 mins
        return 60                             // 0 - 10m: per minute
    }

    private var labelTimes: [Int] {
        stride(from: 0, through: durationSeconds, by: labelInterval).map { $0 }
    }

    private func formatTime(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            GeometryReader { geometry in
                if !data.isEmpty {
                    let maxVal = max(data.max() ?? 1.0, 1.0)
                    let scaleY = geometry.size.height / CGFloat(maxVal)
                    let avgY = geometry.size.height - (CGFloat(average) * scaleY)
                    let stepX = geometry.size.width / CGFloat(data.count - 1)

                    ZStack(alignment: .topLeading) {
                        // Average Line
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: avgY))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: avgY))
                        }
                        .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))

                        // Average Label
                        Text(String(format: "Avg: %.1f", average))
                            .font(.caption2.bold())
                            .foregroundColor(.gray)
                            .position(x: geometry.size.width - 30, y: avgY - 10) // Positioned right-aligned above the line

                        // Data Line
                        Path { path in
                            for (index, value) in data.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = geometry.size.height - (CGFloat(value) * scaleY)

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.accentColor, lineWidth: 2)
                    }
                }
            }
            .frame(height: 100)

            // Dynamic X-Axis Labels
            HStack {
                ForEach(labelTimes, id: \.self) { time in
                    Text(formatTime(seconds: time))
                        .font(.caption2)
                    if time != labelTimes.last { Spacer() }
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
    }
}

