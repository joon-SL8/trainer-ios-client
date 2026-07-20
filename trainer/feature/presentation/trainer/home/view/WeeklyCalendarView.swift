import SwiftUI
import libfitness

struct WeeklyCalendarView: View {
    @StateObject private var viewModel = WeeklyCalendarViewModel()
    @State private var showNoSessionError = false

    var body: some View {
        VStack(spacing: 12) {
            headerView
            daysRow
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .alert("No Session", isPresented: $showNoSessionError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("There is no session recorded for this day.")
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                viewModel.navigateBackward()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(viewModel.canNavigateBackward ? .blue : .gray)
            }
            .disabled(!viewModel.canNavigateBackward)
            .accessibilityIdentifier("calendarPrevWeek")

            Spacer()

            Text(viewModel.headerTitle)
                .font(.headline)
                .fontWeight(.bold)
                .accessibilityIdentifier("calendarHeaderTitle")

            Spacer()

            Button(action: {
                viewModel.navigateForward()
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(viewModel.canNavigateForward ? .blue : .gray)
            }
            .disabled(!viewModel.canNavigateForward)
            .accessibilityIdentifier("calendarNextWeek")
        }
        .padding(.horizontal)
    }

    private var daysRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.currentWeek, id: \.self) { date in
                dayItem(for: date)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func dayItem(for date: Date) -> some View {
        let content = VStack(spacing: 0) {
            // Day and Date area
            VStack(spacing: 4) {
                Text(viewModel.dayAbbreviation(for: date))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(viewModel.dayNumber(for: date))
                    .font(.body)
                    .fontWeight(viewModel.isToday(date) ? .bold : .regular)
                    .accessibilityIdentifier("calendarDayNumber_\(viewModel.dayNumber(for: date))")
            }
            .frame(height: 29)

            // Activity area
            VStack {
                if viewModel.hasActivity(on: date) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .accessibilityIdentifier("calendarActivityIcon_\(viewModel.dayNumber(for: date))")
                } else {
                    Spacer()
                }
            }
            .frame(height: 58)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(borderColor(for: date).opacity(0.05)) // Visual click region
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor(for: date), lineWidth: borderWidth(for: date))
        )
        .contentShape(Rectangle()) // Ensure entire area is clickable
        .accessibilityIdentifier("calendarDayItem_\(viewModel.dayNumber(for: date))")

        if viewModel.hasActivity(on: date) {
            NavigationLink(destination: CalendarListView(date: date)) {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            Button(action: {
                if Bool.random() {
                    showNoSessionError = true
                }
            }) {
                content
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func borderColor(for date: Date) -> Color {
        if viewModel.isToday(date) {
            return .blue
        } else if viewModel.isFuture(date) {
            return .gray.opacity(0.3)
        } else {
            return .gray.opacity(0.6)
        }
    }

    private func borderWidth(for date: Date) -> CGFloat {
        if viewModel.isToday(date) {
            return 3
        } else if viewModel.isFuture(date) {
            return 1
        } else {
            return 2
        }
    }
}

#Preview {
    WeeklyCalendarView()
}
