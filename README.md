# PiFork Scheduler

**PiFork Scheduler** is a robust automation module for managing Play Integrity Fork updates. It combines the reliability of native Android `cron` scheduling with the flexibility of Termux to keep your integrity fingerprints up to date automatically.

## 🚀 Features

* **Automated Updates:** Runs silently in the background (Default: Daily at 4:00 AM).
* **Smart Scheduling:** Supports "Standard" (Daily) or "Hybrid" (Weekly download + Daily refresh) schedules.
* **Action Button Support:** Check service status, view the next scheduled run time, or force stop/start the service directly from your root manager.
* **Termux Integration:** Automatically injects the helper script (`update_pifork.sh`) into Termux for easy manual updating or advanced logic.
* **Conflict-Free:** Intelligent process management ensures no overlap with manual updates.

---

## 📥 Installation

1.  Download the latest release zip.
2.  Install via **Magisk**, **KernelSU**, or **APatch**.
3.  Reboot your device.

> **Note:** If you use Termux, it is recommended to have Termux installed *before* flashing this module so the permissions for the helper script are set automatically.

---

## ⚙️ Configuration

### 1. The Schedule (Cron)
The schedule is defined in the `root` file located at:
`/data/adb/modules/pifork-scheduler/root`

You can edit this file to customize when the update runs.
* **Standard (Default):** Runs everyday at 4:00 AM.
* **Hybrid:** Uncomment the provided lines to run a full download on Sundays and a local refresh on other days.

### 2. The Action Button
Use the Action Button in your root manager (Magisk/KSU) to:
* **View Status:** See if the scheduler is running.
* **Check Schedule:** Displays the exact time of the "Next Run" (e.g., `🗓️ Mon-Sat @ 04:00`).
* **Pause/Resume:** Toggling the button stops or restarts the background daemon.

---

## 🖥️ Termux Integration

During installation, the module attempts to detect Termux and installs a helper script to:
`/data/data/com.termux/files/home/update_pifork.sh`

This allows you to trigger updates manually from a terminal environment.

**If Termux was not detected during install:**
1.  Install Termux from F-Droid or GitHub.
2.  **Reinstall this module.** (This is required to automatically set the correct ownership and execution permissions for the script).

---

## ⚠️ Security Disclaimer

**Please Read Carefully:**

The included helper script (`update_pifork.sh`) is designed to download and execute code from remote sources to update your Play Integrity fingerprints.

* **Remote Code Execution:** This script may use `curl | sh` or similar methods to fetch the latest fixes.
* **User Responsibility:** It is strongly recommend you **review the contents** of `/data/data/com.termux/files/home/update_pifork.sh` before running it to ensure you trust the source it connects to.

---

## 📜 License

This project is open source. Feel free to fork, modify, and distribute.
