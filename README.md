# Sila

Sila is an iOS study planner with focus timers and a productivity summary. It stores everything on the device.

## Features

- **Planner:** add, complete and delete study tasks (title, subject, date, duration). Tasks appear in one list sorted by date.
- **Focus timer:** three modes, with start, pause and reset. The timer pauses when you leave the Timer tab.
  - Pomodoro: 25 minutes
  - Deep Work: 90 minutes
  - Break: 5 minutes
- **Productivity summary:** today's total study minutes, a list of completed tasks and a 7-day bar chart. Minutes count on a task's scheduled date, not the day it was completed.

## Built with

- SwiftUI
- Core Data
- Swift Charts

## Architecture

The timer and summary screens use MVVM: `TimerViewModel` and `ProductivitySummaryViewModel` hold their logic. The planner and add task screens read and write Core Data directly from the view.

## Setup

Requires Xcode and iOS 18.0 or later.

1. Clone the repo:
   ```bash
   git clone https://github.com/lakshya110704/Sila-iOS.git
   ```
2. Open `Sila.xcodeproj` in Xcode.
3. Build and run on an iOS Simulator or a device.

## Tests

`SilaTests` covers the timer and the summary calculations, using an in-memory Core Data store. Last run: 18 of 18 passed on an iPhone 16 simulator (iOS 18.0, Xcode 27.2).

`SilaUITests` contains only the Xcode UI test templates: not yet run.

## Roadmap

- CoreML timer mode suggestions: not built

## License

MIT License. See `LICENSE`.
