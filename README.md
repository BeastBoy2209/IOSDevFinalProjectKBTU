# IOSDevFinalProjectKBTU
# 🎰 VirtualCasino — iOS Dashboard UI/UX

A high-fidelity, premium Casino Management application built with **Swift** and **UIKit**. This project focuses on a modern "Neon Dark" aesthetic, featuring advanced Auto Layout techniques and real-time state management.

---

## ✨ Key Features

* **🏠 Dynamic Home Dashboard**: Interactive promotional banners with "Stencil" cutout text effects and real-time balance tracking.
* **🎮 Modular Games Library**: A responsive 2-column grid system designed with nested StackViews for perfect scalability across all iPhone sizes.
* **💳 Advanced Wallet System**: Real-time credit management with a dynamic "Recent Activity" feed that updates via a centralized state manager.
* **👤 Player Profile & Achievements**: Comprehensive user statistics, level progress tracking, and a modular achievement system with "Locked/Unlocked" states.
* **🎨 Custom UI Components**: Hand-crafted `CardView` classes, animated button states, and specialized drawing logic for high-end UI elements.

---

## 🛠 Technical Architecture

### 🧠 State Management

The app utilizes a **Singleton Pattern** via the `UserManager` class. This ensures that the user's balance, transaction history, and achievements stay synchronized across the Home, Wallet, and Profile tabs without data lag.

### 📐 UI Engine

* **Nested UIStackViews**: Built entirely using nested vertical and horizontal stacks to ensure "pixel-perfect" layouts without the complexity of hundreds of individual constraints.
* **Stencil/Cutout Buttons**: Custom `draw(_ rect:)` implementation using **Core Graphics** to create transparent text layers, allowing background gradients to "shine through" the button label.
* **Adaptive ScrollViews**: Fully optimized vertical scrolling architecture that handles dynamic content height and safe area insets automatically.

### ⚡ Performance & Animations

* **UIView Extensions**: Custom `.animatePress()` scaling animations for a tactile, "bouncy" feel on every interactive element.
* **Core Graphics**: Optimized rendering for borders, corner radii, and custom gradients.

---

## 📸 Screenshots & UI Design
> **Design Note:** The UI uses a strictly curated palette of **Neon Cyan (#00D1FF)**, **Deep Indigo (#0B0B19)**, and **Vivid Purple** to simulate a high-stakes casino environment.

---

## 🚀 Installation & Setup

1. **Clone the repository:**
```bash
git clone https://github.com/BeastBoy2209/VirtualCasino.git

```


2. **Open in Xcode:**
Navigate to the project folder and open `VirtualCasino.xcodeproj`.
3. **Run:**
Select your preferred iPhone Simulator (iPhone 15 or later recommended) and press `Cmd + R`.

---

## 📁 Project Structure

* `Controllers/`: Contains `HomeViewController`, `WalletViewController`, and `ProfileViewController`.
* `Models/`: `UserManager` handles all logic, data persistence, and notifications.
* `Views/`: Custom `CardView` and `CutoutButton` classes for specialized UI rendering.
* `Extensions/`: Helper methods for `UIView` animations and UI customization.

---
