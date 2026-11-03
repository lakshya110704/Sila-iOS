# Sila – iOS Study Planner App

**Sila** is an intelligent iOS study planner designed to help students maximize productivity using AI-driven recommendations and flexible focus timers.

---

## 🚀 Features

- 📚 **Smart Study Suggestions** — CoreML recommends ideal modes like Pomodoro, Deep Work, or Break based on your study behavior.
- ⏱️ **Custom Timer Modes**:
  - Pomodoro (25/5)
  - Deep Work (90/20)
  - Custom Sessions
- 📊 **Daily Productivity Summaries** with completed tasks, total minutes, and hourly breakdown.
- 📅 **Planner View** to schedule tasks for the week.
- 💡 **Adaptive Suggestions** powered by on-device learning.

---

## 🧠 Powered By

- **SwiftUI** for UI & architecture
- **CoreML** for on-device predictions
- **CoreData** for local task persistence
- **MVVM Architecture** for clean state handling

---

## 🛠️ Setup Instructions

1. Clone the repo:
   ```bash
   git clone https://github.com/lakshya110704/Sila-iOS.git
   ```
2. Open `Sila.xcodeproj` in Xcode.
3. Drag `TimerModePredictor.mlmodel` into the `CoreML/` folder.
4. Build & run on iOS Simulator or a real device.

---

## 🤖 CoreML Model

- Inputs: `hour`, `totalMinutes`, `completedTasks`
- Outputs: `"Pomodoro"`, `"Deep Work"`, `"Break"`
- Swift prediction usage:
  ```swift
  let prediction = try? model.prediction(hour: 14, totalMinutes: 90, completedTasks: 3)
  ```

---

## 🧪 Tests

Includes `SilaTests` and `SilaUITests` for basic validation and UI flow.

---

## 📄 License

MIT License. See `LICENSE` file for more info.