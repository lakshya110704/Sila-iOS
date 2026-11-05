# Sila

Sila is an iOS study planner with focus timers and a productivity summary. It stores everything on the device.

## Features

- **Planner:** add, complete and delete study tasks (title, subject, date, duration). Tasks appear in one list sorted by date. Save stays disabled until the title is not blank and the duration is above zero.
- **Focus timer:** three modes, with start, pause and reset. The timer keeps running when you switch tabs. It works out remaining time from the clock, so time spent in the background still counts. Its state is saved, so a running or paused timer carries on if iOS terminates the app. It does not send a notification when it finishes.
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

`SilaTests` covers the timer, the summary calculations and add task validation, using an in-memory Core Data store. Last run: 32 of 32 passed on an iPhone 16 simulator (iOS 18.0, Xcode 27.2).

`TimerFlowUITests` in `SilaUITests` drives the running app through switching tabs, going to the background and being terminated. Last run: 4 of 4 passed on the same simulator, repeated 3 times. The Xcode template UI tests in that target: not yet run.

## Roadmap

- CoreML timer mode suggestions: not built

## License

MIT License. See `LICENSE`.
