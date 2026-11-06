# Sila

Sila is an iOS study planner with focus timers and a productivity summary. It stores everything on the device.

## Features

- **Planner:** add, complete and delete study tasks (title, subject, date, duration). Tasks appear in one list sorted by date. Save stays disabled until the title is not blank and the duration is above zero.
- **Focus timer:** three modes, with start, pause and reset. The timer keeps running when you switch tabs. It works out remaining time from the system uptime clock, so time spent in the background still counts and changing the device time doesn't shift it. After a reboot it goes by the device time instead. Its state is saved, so a running or paused timer carries on if iOS terminates the app. It sends a notification when it finishes, if you allow notifications.
  - Pomodoro: 25 minutes
  - Deep Work: 90 minutes
  - Break: 5 minutes
- **Productivity summary:** today's total study minutes, a list of completed tasks and a 7-day bar chart. Minutes count on the day a task was completed. Tasks completed before the app stored that date count on their scheduled date.

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

`SilaTests` covers the timer, the summary calculations, add task validation and migrating a store from the first Core Data model version. Last run: 45 of 45 passed on an iPhone 16 simulator (iOS 18.0, Xcode 27.2).

`SilaUITests` drives the running app through switching tabs, going to the background, being terminated, and adding and completing a task, and checks tap target sizes. It also contains the Xcode template launch tests. Last run: 8 of 9 test methods passed on the same simulator. The template `testLaunchPerformance` was terminated while the Mac was overloaded, then passed when rerun alone. A UI test retries a tap once if its expected result does not appear, because taps occasionally had no visible effect. In one stress test with the Mac overloaded, 1 of about 79 taps had no effect, and 0 of 90 did without the extra load. The exact cause is unknown.

## Roadmap

- CoreML timer mode suggestions: not built

## License

MIT License. See `LICENSE`.
