//
//  AnalyzerViewModel.swift
//  Centered
//
//  Created by Family Galvez on 11/10/25.
//

import Foundation
import SwiftUI

enum AnalyzerMode: String {
    case weekly
    case monthly
}

struct AnalyzerDisplayData {
    let dateRangeText: String
    let startDate: Date
    let endDate: Date
    let mode: AnalyzerMode
}

struct MoodCount: Identifiable, Equatable {
    let id = UUID()
    let order: Int
    let mood: String
    let count: Int
}

@MainActor
class AnalyzerViewModel: ObservableObject {
    @Published var mode: AnalyzerMode = .weekly
    @Published var dateRangeDisplay: String = "Run analysis"
    @Published var latestEntry: AnalyzerEntry?
    @Published var moodCounts: [MoodCount] = []
    @Published var logsCount: Int = 0
    @Published var streakDuringRange: Int = 0
    @Published var favoriteLogTime: String = "—"
    @Published var centeredScore: Int?
    @Published var summaryText: String?
    @Published var isAnalyzeButtonEnabled: Bool = false
    @Published var isAnalyzing: Bool = false
    @Published var showMinimumEntriesAlert: Bool = false
    @Published var minimumEntriesMessage: String = ""
    
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    
    func update(with entries: [AnalyzerEntry]) {
        latestEntry = entries.sorted { $0.createdAt > $1.createdAt }.first
        if let entry = latestEntry {
            if entry.entryType == "monthly" {
                mode = .monthly
            } else {
                mode = .weekly
            }
            
            if let response = entry.analyzerAiResponse {
                moodCounts = parseMoodCounts(from: response)
                centeredScore = parseCenteredScore(from: response)
                summaryText = parseSummaryText(from: response)
            } else {
                moodCounts = []
                centeredScore = nil
                summaryText = nil
            }
        } else {
            moodCounts = []
            centeredScore = nil
            summaryText = nil
        }
    }
    
    func computeDisplayData(for date: Date = Date(), mode: AnalyzerMode? = nil) -> AnalyzerDisplayData {
        let effectiveMode = mode ?? self.mode
        switch effectiveMode {
        case .weekly:
            let range = weeklyRange(for: date)
            let text = formattedWeekRange(range)
            return AnalyzerDisplayData(dateRangeText: text, startDate: range.start, endDate: range.end, mode: .weekly)
        case .monthly:
            let range = monthlyRange(for: date)
            let text = formattedMonthRange(range)
            return AnalyzerDisplayData(dateRangeText: text, startDate: range.start, endDate: range.end, mode: .monthly)
        }
    }
    
    func refreshDateRangeDisplay(referenceDate: Date = Date()) {
        let displayData = computeDisplayData(for: referenceDate)
        dateRangeDisplay = displayData.dateRangeText
    }
    
    func refreshStats(using stats: AnalyzerStats) {
        logsCount = stats.logsCount
        streakDuringRange = stats.streakCount
        favoriteLogTime = stats.favoriteLogTime
    }
    
    // MARK: - Date Range Helpers
    private func weeklyRange(for date: Date) -> (start: Date, end: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysSinceSunday = (weekday + 6) % 7
        guard let previousSunday = calendar.date(byAdding: .day, value: -(daysSinceSunday + 7), to: startOfDay),
              let lastSaturday = calendar.date(byAdding: .day, value: 6, to: previousSunday) else {
            return (startOfDay, startOfDay)
        }
        return (calendar.startOfDay(for: previousSunday), calendar.startOfDay(for: lastSaturday))
    }
    
    private func monthlyRange(for date: Date) -> (start: Date, end: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        let lastMonthCandidates = stride(from: 1, through: calendar.range(of: .day, in: .month, for: startOfDay)?.count ?? 31, by: 1)
            .compactMap { calendar.date(byAdding: .day, value: -$0, to: startOfDay) }
        if let lastSunday = lastMonthCandidates.first(where: { calendar.component(.weekday, from: $0) == 1 }),
           let lastSaturday = lastMonthCandidates.first(where: { calendar.component(.weekday, from: $0) == 7 }) {
            return (calendar.startOfDay(for: lastSunday), calendar.startOfDay(for: lastSaturday))
        }
        return weeklyRange(for: date)
    }
    
    private func formattedWeekRange(_ range: (start: Date, end: Date)) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startText = formatter.string(from: range.start)
        formatter.dateFormat = "MMM d"
        let endText = formatter.string(from: range.end)
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        if let day = Int(dayFormatter.string(from: range.end)) {
            let suffix: String
            switch day % 10 {
            case 1 where day != 11: suffix = "st"
            case 2 where day != 12: suffix = "nd"
            case 3 where day != 13: suffix = "rd"
            default: suffix = "th"
            }
            return "\(startText) to \(endText)\(suffix)"
        }
        return "\(startText) to \(endText)"
    }
    
    private func formattedMonthRange(_ range: (start: Date, end: Date)) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let startMonth = formatter.string(from: range.start)
        let endMonth = formatter.string(from: range.end)
        
        if startMonth == endMonth {
            return "\(startMonth) Month"
        } else {
            return "\(startMonth) - \(endMonth)"
        }
    }
    
    private func parseMoodCounts(from response: String) -> [MoodCount] {
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstParagraph = trimmedResponse.components(separatedBy: "\n\n").first ?? trimmedResponse
        let components = firstParagraph.split(separator: ",")
        
        var counts: [MoodCount] = []
        
        for (index, component) in components.enumerated() {
            let item = component.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let open = item.lastIndex(of: "("),
                  let close = item.lastIndex(of: ")"),
                  open < close else { continue }
            let moodName = String(item[..<open]).trimmingCharacters(in: .whitespacesAndNewlines)
            let numberString = String(item[item.index(after: open)..<close])
            
            if let count = Int(numberString) {
                counts.append(MoodCount(order: index, mood: moodName, count: count))
            }
        }
        
        return counts
    }
    
    private func parseCenteredScore(from response: String) -> Int? {
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let paragraphs = trimmedResponse.components(separatedBy: "\n\n")
        guard let lastParagraph = paragraphs.last else { return nil }
        let digits = lastParagraph.compactMap { $0.isNumber ? $0 : nil }
        guard digits.count >= 2 else { return nil }
        let scoreString = String(digits.suffix(2))
        return Int(scoreString)
    }
    
    private func parseSummaryText(from response: String) -> String? {
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let paragraphs = trimmedResponse.components(separatedBy: "\n\n")
        guard paragraphs.count >= 2 else { return nil }
        let summaryParagraph = paragraphs[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return summaryParagraph.isEmpty ? nil : summaryParagraph
    }
    
    /// Determines if analysis should be weekly or monthly based on date
    /// Monthly analysis occurs on the last Sunday of the month, otherwise weekly
    func determineAnalysisMode(for date: Date) -> AnalyzerMode {
        let startOfDay = calendar.startOfDay(for: date)
        
        // Check if this date is the last Sunday of the month
        let lastSundayOfMonth = findLastSundayOfMonth(for: startOfDay)
        if let lastSunday = lastSundayOfMonth, calendar.isDate(startOfDay, inSameDayAs: lastSunday) {
            return .monthly
        }
        
        // Otherwise, use weekly analysis
        return .weekly
    }
    
    /// Finds the last Sunday of the month for a given date
    private func findLastSundayOfMonth(for date: Date) -> Date? {
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return nil
        }
        
        // Find the last Sunday of the month
        for day in range.reversed() {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                if calendar.component(.weekday, from: date) == 1 { // Sunday
                    return date
                }
            }
        }
        
        return nil
    }
    
    /// Determines if the analyze button should be enabled
    /// Button is available any day of the week, but disabled if an analysis already exists for the current period
    func determineAnalysisAvailability(for date: Date = Date(), allEntries: [AnalyzerEntry] = []) {
        // Determine the mode (weekly or monthly) based on the current date
        let currentMode = determineAnalysisMode(for: date)
        
        // Calculate the current period that would be analyzed if button is clicked today
        let currentPeriod = computeDisplayData(for: date, mode: currentMode)
        
        // Check if any existing analyzer entry was created for the same period
        // We determine the period an entry analyzed by calculating what period its createdAt date falls into
        // IMPORTANT: Only consider entries with a valid (non-empty) analyzerAiResponse
        let hasAnalysisForCurrentPeriod = allEntries.contains { entry in
            // Skip entries without a valid AI response - these are incomplete/failed analyses
            guard let response = entry.analyzerAiResponse,
                  !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return false
            }
            
            // Determine what mode this entry was created for
            let entryMode = determineAnalysisMode(for: entry.createdAt)
            
            // Calculate what period this entry analyzed based on when it was created
            let entryPeriod = computeDisplayData(for: entry.createdAt, mode: entryMode)
            
            // Check if the entry's period matches the current period
            // Compare both start and end dates to ensure exact match
            let entryStart = calendar.startOfDay(for: entryPeriod.startDate)
            let entryEnd = calendar.startOfDay(for: entryPeriod.endDate)
            let currentStart = calendar.startOfDay(for: currentPeriod.startDate)
            let currentEnd = calendar.startOfDay(for: currentPeriod.endDate)
            
            // Also check that the entry type matches (weekly vs monthly)
            let modesMatch = entryMode == currentPeriod.mode
            
            return modesMatch && entryStart == currentStart && entryEnd == currentEnd
        }
        
        // Enable button if no analysis exists for the current period
        isAnalyzeButtonEnabled = !hasAnalysisForCurrentPeriod
    }
}

