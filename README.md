# Sila

Sila is an iOS study planner with focus timers and a productivity summary. It stores everything on the device.

## Features

- **Planner:** add, complete and delete study tasks (title, subject, date, duration). Tasks appear by day for one week at a time, with buttons to move between weeks. Save stays disabled until the title is not blank and the duration is above zero.
- **Focus timer:** three modes, with start, pause and reset. The timer keeps running when you switch tabs. It works out remaining time from the system uptime clock, so time spent in the background still counts and changing the device time doesn't shift it. After a reboot it goes by the device time instead. Its state is saved, so a running or paused timer carries on if iOS terminates the app. It sends a notification when it finishes, if you allow notifications.
  - Pomodoro: 25 minutes
  - Deep Work: 90 minutes
  - Break: 5 minutes
- **Suggestions:** two suggestions sit side by side on the Timer screen, and either can set the timer's mode.
  - General: fixed rules of thumb based on the time of day and whether you just finished a focus session. They are not personalised or based on research.
  - Your History: the focus mode you finish most reliably at this time of day, from the timer sessions saved on your device. It needs 5 focus sessions in a part of the day before it suggests anything.
- **Productivity summary:** today's total study minutes, a list of completed tasks and a 7-day bar chart. Minutes count on the day a task was completed. Tasks completed before the app stored that date count on their scheduled date.

## Built with

- SwiftUI
- Core Data
- Swift Charts

## Architecture

The timer and summary screens use MVVM: `TimerViewModel`, `SuggestionsViewModel` and `ProductivitySummaryViewModel` hold their logic. The planner and add task screens read and write Core Data directly from the view.

## Setup

Requires Xcode and iOS 18.0 or later.

1. Clone the repo:
   ```bash
   git clone https://github.com/lakshya110704/Sila-iOS.git
   ```
2. Open `Sila.xcodeproj` in Xcode.
3. Build and run on an iOS Simulator or a device.

## Tests

`SilaTests` covers the timer, the suggestions, the planner week, the summary calculations, add task validation and migrating stores from earlier Core Data model versions. Last run: 71 of 71 passed on an iPhone 16 simulator (iOS 18.0, Xcode 27.2).

`SilaUITests` drives the running app through switching tabs, going to the background, being terminated, adding, completing and deleting a task, moving between weeks, and using a suggestion, and checks tap target sizes. It also contains the Xcode template launch tests. Last run: 12 of 12 test methods passed on the same simulator. A UI test retries a tap once if its expected result does not appear, because taps occasionally had no visible effect. In one stress test with the Mac overloaded, 1 of about 79 taps had no effect, and 0 of 90 did without the extra load. The exact cause is unknown.

## Roadmap

- A CoreML model for suggestions: not built

## License

MIT License. See `LICENSE`.
