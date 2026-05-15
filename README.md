# 🌟 HMI Stars - Enterprise Messaging Ecosystem

![HMI Stars Banner](https://img.shields.io/badge/Status-Restored_&_Secured-brightgreen?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

## 🛠️ Project Status: RESTORED & SECURED (May 14, 2026)

The project has undergone a full environment restoration and security hardening cycle.

### Key Restorations
- **SQL Schema**: `database_schema.sql` and `platform_migration.sql` have been reconstructed from the live Supabase instance.
- **Configurations**: Live `supabase_config.dart` files have been restored for both Platform and Mobile apps.
- **Dependencies**: All Flutter dependencies have been re-initialized (`flutter pub get`).

### Security Posture
- **Secret Management**: All production secrets are stored in `supabase_config.dart` files, which are explicitly **excluded from Git**.
- **Templates**: `.example` files are provided for safe GitHub sharing and local setup.
- **Monorepo Hygiene**: Redundant build artifacts and temporary logs have been purged.

---

HMI Stars is a high-performance, real-time messaging ecosystem designed for enterprise communication. It bridges the gap between administrators and mobile users with a unified backend powered by **Supabase**.

---

## 🏗️ Architecture

This repository is organized as a monorepo containing two main projects:

| Component | Path | Description |
| :--- | :--- | :--- |
| **Admin Platform** | `/Platforme` | Web-based dashboard for administrators to manage enterprises and respond to messages. |
| **Mobile App** | `/hmistarsmobile` | Flutter mobile application for clients to interact with the platform. |

### Core Tech Stack
- **Frontend**: Flutter (Web & Mobile)
- **Backend**: Supabase (PostgreSQL, Realtime, Auth, Storage)
- **State Management**: Provider
- **Design**: Premium Glassmorphism & Modern UI/UX

---

## 🚀 Key Features

- **Real-time Messaging**: Instant synchronization across all devices using PostgreSQL streams.
- **Enterprise Management**: Automated client account creation and data isolation.
- **Smart UI**: Unread message indicators, automatic read tracking, and intuitive conversation sorting.
- **Performance**: Lazy loading for message history and optimized data fetching.

---

## 🛠️ Setup & Installation

### Prerequisites
- Flutter SDK (Latest Stable)
- Supabase Project Credentials

### Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/hmi_stars.git
   ```

2. **Configure Environment**:
   Ensure you have your Supabase URL and Anon Key. Update the initialization in `main.dart` for both projects.

3. **Install Dependencies**:
   Navigate to each folder and run:
   ```bash
   flutter pub get
   ```

4. **Run the projects**:
   - **Admin Platform**: `flutter run -d chrome` (from `/Platforme`)
   - **Mobile App**: `flutter run` (from `/hmistarsmobile`)

---

## 🛡️ Security
- **Row Level Security (RLS)**: Enforced at the database level to ensure enterprises only access their own data.
- **Admin Roles**: Managed via service role keys for critical operations like user creation.

---

## 📝 License
Proprietary - All Rights Reserved.

---

*Developed with ❤️ for HMI Stars.*
