//
//  FlexibleCalendarView.swift
//  FlexibleCalender
//
//  Created by Heshan Yodagama on 10/22/20.
//

import SwiftUI

public struct DateGrid<DateView>: View where DateView: View {
    @Environment(\.calendar) var envCalendar

    /// DateStack view
    /// - Parameters:
    ///   - interval:
    ///   - selectedMonth: date relevant to showing month, then you can extract the components
    ///   - content:
    public init(
          interval: DateInterval,
          selectedMonth: Binding<Date>,
          mode: CalendarMode,
          @ViewBuilder content: @escaping (DateGridDate) -> DateView
      ) {
          // Initialize viewModel here without calendar, since we can't access envCalendar
          self._viewModel = StateObject(wrappedValue: DateGridViewModel(interval: interval, mode: mode))
          self._selectedMonth = selectedMonth
          self.content = content
      }
    
    //TODO: make Date generator class
    @StateObject private var viewModel: DateGridViewModel
    private let content: (DateGridDate) -> DateView
    @Binding var selectedMonth: Date

    public var body: some View {
        TabView(selection: $selectedMonth) {
            MonthsOrWeeks(viewModel: viewModel, content: content)
        }
        .frame(height: viewModel.mode.estimateHeight, alignment: .center)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onAppear {
            // Now that envCalendar is accessible, update the viewModel's calendar
            viewModel.calendar = self.envCalendar
        }
    }

    //MARK: constant and supportive methods
}

struct CalendarView_Previews: PreviewProvider {
    
    @State static var selectedMonthDate = Date()
    
    static var previews: some View {
        VStack {
            Text(DateFormatter.monthAndYear.string(from: selectedMonthDate))
                .font(.title)
                .fontWeight(.bold)
            WeekDaySymbols()
            
            DateGrid(
                interval:
                        .init(
                            start: Date.getDate(from: "2024 01 01")!,
                            end: Date.getDate(from: "2024 12 31")!
                        ),
                selectedMonth: $selectedMonthDate,
                mode: .week(estimateHeight: 400)
            ) { dateGridDate in
                
                NormalDayCell(date: dateGridDate.date)
            }
        }
        
    }
}

struct MonthsOrWeeks<DateView>: View where DateView: View {
    let viewModel: DateGridViewModel
    let content: (DateGridDate) -> DateView
    
    var body: some View {
        ForEach(Array(viewModel.monthsOrWeeks.enumerated()), id: \.element) { index, monthOrWeek  in
            
            VStack {
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: numberOfDaysInAWeek), spacing: 0) {
                    
                    ForEach(viewModel.days(for: monthOrWeek), id: \.self) { date in
                        
                        let dateGridDate = DateGridDate(date: date, currentMonth: monthOrWeek)
                        if viewModel.calendar.isDate(date, equalTo: monthOrWeek, toGranularity: .month) {
                            content(dateGridDate)
                                .id(date)
                            
                        } else {
                            content(dateGridDate)
                                .hidden()
                        }
                    }
                }
                .tag(index) // Use index for stable identifier
                //Tab view frame alignment to .Top didn't work dtz y
                Spacer()
            }
        }
    }
    
    //MARK: constant and supportive methods
    private let numberOfDaysInAWeek = 7
}

extension DateGridViewModel {
    func index(forMonth date: Date) -> Int? {
        // Find the index of the month that contains the given date.
        return monthsOrWeeks.firstIndex { calendar.isDate($0, equalTo: date, toGranularity: .month) }
    }
    
    func date(forIndex index: Int) -> Date? {
        // Return the Date at the given index, if it exists.
        guard monthsOrWeeks.indices.contains(index) else { return nil }
        return monthsOrWeeks[index]
    }
}
