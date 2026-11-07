# Sila

Sila is an iOS study planner with focus timers and a productivity summary. It stores everything on the device.

## Features

- **Planner:** add, edit, complete and delete study tasks (title, subject, date, duration). Tap a task to edit it, or tap its play button to focus on it. Tasks appear by day for one week at a time, with buttons to move between weeks. Save stays disabled until the title is not blank and the duration is above zero.
- **Focus timer:** three modes, with start, pause and reset. The timer keeps running when you switch tabs. It works out remaining time from the system uptime clock, so time spent in the background still counts and changing the device time doesn't shift it. After a reboot it goes by the device time instead. Its state is saved, so a running or paused timer carries on if iOS terminates the app. It sends a notification when it finishes, if you allow notifications. Focusing on a task opens the timer with that task attached, and its Pomodoro and Deep Work sessions count toward the task. A session in progress keeps the task it started with.
  - Pomodoro: 25 minutes
  - Deep Work: 90 minutes
  - Break: 5 minutes
- **Suggestions:** two suggestions sit side by side on the Timer screen, and either can set the timer's mode.
  - General: fixed rules of thumb based on the time of day and whether you just finished a focus session. They are not personalised or based on research.
  - Your History: the focus mode you finish most reliably at this time of day, from the timer sessions saved on your device. It needs 5 focus sessions in a part of the day before it suggests anything.
- **Productivity summary:** today's focus time, a 7-day bar chart and a list of completed tasks. Minutes come from Pomodoro and Deep Work sessions, with or without a task, and leave out paused time and breaks. A session counts on the day it ended, once you finish or reset it. Reset sessions under a minute aren't saved. Completing a task without using the timer adds no minutes. Sessions saved before this was tracked may include some paused time, capped at the mode's length.

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

`SilaTests` covers the timer, the suggestions, the planner week, the summary calculations, add task validation and migrating stores from earlier Core Data model versions. Last run: 81 of 81 passed on an iPhone 16 simulator (iOS 18.0, Xcode 27.2).

`SilaUITests` drives the running app through switching tabs, going to the background, being terminated, adding, editing, completing and deleting a task, moving between weeks, using a suggestion, and focusing on a task until its time shows in the planner and Summary, and checks tap target sizes. It also runs Xcode's accessibility audit on each screen, skipping a few findings checked by hand (listed in the test). It also contains the Xcode template launch tests. Last run: 18 of 18 test methods passed on the same simulator, run one at a time. Earlier runs while the Mac was overloaded or sleeping did have failures, mostly timeouts. A UI test retries a tap once if its expected result does not appear, because taps occasionally had no visible effect. In one stress test with the Mac overloaded, 1 of about 79 taps had no effect, and 0 of 90 did without the extra load. The exact cause is unknown.

## Not yet tested

Sila has only been run on a simulator. For a physical device it has only been compiled, without code signing. These have not been tested:

- A timer across a real reboot, or a real change of the device time. Unit tests cover both with a fake clock.
- A finish notification firing on a device.
- Whether taps are ever ignored on a device.
- Using the app with VoiceOver. Only the automated audit has run, and large text was checked by eye on a simulator.
- The Your History card making a real suggestion on screen. Unit tests cover the logic, and the UI test only checks that the card appears.

## Known gaps

- The app icon is a generated placeholder.
- There is no backup or export, so deleting the app deletes your tasks and timer history.

## Privacy

Sila makes no network calls and has no accounts or analytics. Tasks and timer history stay on the device. The only permission it asks for is notifications, the first time you start a timer.

## Roadmap

- A CoreML model for suggestions: not built

## License

MIT License. See `LICENSE`.
