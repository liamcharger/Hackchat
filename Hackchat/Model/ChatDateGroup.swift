//
//  ChatDateGroup.swift
//  Hackchat
//
//  Created by Liam Willey on 4/12/25.
//

import Foundation

enum ChatDateGroup: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case pastMonths = "Past Months"
    case pastYears = "Past Years"

    static func group(for date: Date) -> ChatDateGroup {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return .today
        } else if calendar.isDateInYesterday(date) {
            return .yesterday
        } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                  date >= weekAgo {
            return .lastWeek
        } else if let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()),
                  date >= monthAgo {
            return .lastMonth
        } else if let yearAgo = calendar.date(byAdding: .year, value: -1, to: Date()),
                  date >= yearAgo {
            return .pastYears
        } else {
            return .pastMonths
        }
    }
}
