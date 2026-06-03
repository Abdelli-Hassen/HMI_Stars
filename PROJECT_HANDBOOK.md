# HMI Stars Project Handbook & Knowledge Base

This handbook provides a comprehensive architectural and technical overview of the **HMI Stars** software ecosystem. It outlines the methodologies, directory structures, state management mechanisms, database schemas, security configurations, and dynamic communication patterns utilized in the project.

---

## 1. Project Overview & Methodology
**HMI Stars** is a real-time communications and administrative management ecosystem designed specifically for the consulting firm **HMI Stars Consulting** to digitize, centralize, and automate exchanges between the firm and its corporate client companies.

### Monorepo Structure
The system is built as a **Flutter Monorepo** containing two distinct clients connected to a unified backend:
1. **Mobile Client Application (`hmistarsmobile`)**: A responsive mobile app compiled as an Android APK, dedicated to **Client Managers** (directors/managers of client companies).
2. **Web Administration Platform (`Platforme`)**: A high-end web administration portal deployed on Vercel, dedicated to **HMI Stars Managers & Staff** (Admins, Moderators, Secretaries).

---

## 2. Directory Modularization & Code Architecture
Both applications follow a modular structure, separating shared resources (`core`) from business features (`features`).

### Mobile App Directory Structure (`hmistarsmobile/lib`)
```
lib/
├── core/
│   ├── config/       # Global constants, routes, and client configurations
│   ├── models/       # Entity classes (Company, Employee, Message, etc.)
│   ├── providers/    # AppState state controller (Centralized State Machine)
│   ├── services/     # API Service wrappers for database and storage CRUD
│   ├── theme/        # Global HSL typography, dark mode tokens, and animations
│   └── widgets/      # Shared custom UI widgets (buttons, input fields)
├── features/
│   ├── auth/         # Login, signup, password recovery interfaces
│   ├── salaries/     # Employee registries, profiles, and avatars
│   ├── pointage/     # Calendar-based check-in grids
│   ├── conges/       # Leave request form and tracking
│   ├── messagerie/   # Real-time WebSocket chat and document uploads
│   ├── avertissements/# Warning notices workspace
│   ├── dashboard/    # Client metrics panel
│   ├── parametres/   # Manager profile settings
│   ├── shell/        # Adaptive navigation layout scaffold
│   └── router/       # GoRouter path definitions
└── main.dart         # App entry point initializing Supabase clients
```

### Web App Directory Structure (`Platforme/lib`)
```
lib/
├── core/
│   ├── models/       # Shared database mapping entities
│   ├── services/     # Supabase client REST and auth operations
│   └── theme/        # Dashboard visual styling
├── features/
│   ├── auth/         # Admin login and password reset
│   ├── dashboard/    # Operations metrics and statistics
│   ├── entreprises/  # Client company registrations, details tabs
│   ├── messagerie/   # Central client messaging panel
│   ├── settings/     # Staff sub-account administration
│   └── urgents/      # Urgent task schedules and follow-up alerts
└── main.dart         # Platform web initializer
```

---

## 3. The Centralized State Controller (`AppState`)
State management is handled by `AppState` (`ChangeNotifier` mixed with `WidgetsBindingObserver`). It coordinates the services, caches local data, handles optimistic UI updates, and manages subscriptions.

### Core Mechanisms of `AppState`:
1. **Lifecycle Observability (`WidgetsBindingObserver`)**: Detects when the application is resumed (`AppLifecycleState.resumed`) and automatically synchronizes messages, pending leaves, and push notifications to maintain consistency.
2. **Multi-Company Selector**: Supports client managers managing multiple companies. If `getEntreprisesForUser` returns multiple rows, it halts loading and displays a company selection overlay. Selecting a company triggers `selectEntreprise`, loading company-scoped records.
3. **Daily Pointage Calendar Cache**: Uses a month-scoped dictionary cache (`Map<String, List<PointageEntree>>` keyed by `yyyy-MM`) to minimize network fetches. When pointage for a day is modified, it updates locally in memory before completing database synchronization.
4. **Optimistic UI Chat Updates**: Render sent messages instantly in the chat window with a generated `optimistic_${timestamp}` ID before waiting for database inserts to complete, keeping the messaging feel fluid.
5. **Real-time Stream Subscriptions**: Spawns a WebSocket stream connection (`_abonnementMessages`) linked to Phoenix channels to receive incoming message payloads in real-time.

---

## 4. Services Layer & API Contracts
Both frontends communicate with Supabase via specialized service classes:
* **`AuthService`**: Manages sign-in, logout, and token recovery hooks (`onAuthStateChange`).
* **`SalarieService`**: Handles employee profile creation, archiving/unarchiving, details updates, and profile picture uploads to Supabase Storage buckets.
* **`PointageService`**: Performs bulk upserts for employee pointage rows and comments.
* **`CongeService`**: Submits leave requests and updates request states (Pending/Approved/Rejected).
* **`MessageService`**: Retrieves paginated messages and registers uploaded document attachments into the file database.
* **`ServiceNotification`**: Manages push notifications by registering Firebase Cloud Messaging (FCM) tokens.

---

## 5. Database Schema (PostgreSQL on Supabase)
The database structure is composed of **11 public tables**:

### `public.entreprises`
Stores company registration metadata.
* `id` (uuid, Primary Key)
* `companyName` (text)
* `managerName` (text)
* `sirenNumber` (text)
* `siret` (text)
* `legalForm` (text)
* `vatNumber` (text)
* `rcsNumber` (text)
* `shareCapital` (text)
* `apeCode` (text)
* `createdAt` (timestamp)
* `updatedAt` (timestamp)

### `public.salaries`
Contains employee registry records.
* `id` (uuid, Primary Key)
* `companyId` (uuid, Foreign Key -> `entreprises.id`)
* `gender` (text)
* `lastName` (text)
* `firstName` (text)
* `birthName` (text)
* `socialSecurityNumber` (text)
* `birthDate` (date)
* `birthPlace` (text)
* `nationality` (text)
* `postalAddress` (text)
* `phone` (text)
* `email` (text)
* `hireDate` (date)
* `contractType` (text)
* `contractEndDate` (date)
* `jobTitle` (text)
* `isArchived` (boolean)
* `avatarUrl` (text)
* `hasIdDocument`, `hasSocialSecurityCard`, `hasProofOfAddress`, `hasSignedContract` (boolean flags)

### `public.pointages`
Records daily attendance.
* `id` (uuid, Primary Key)
* `employeeId` (uuid, Foreign Key -> `salaries.id`)
* `companyId` (uuid, Foreign Key -> `entreprises.id`)
* `date` (timestamp)
* `isPresent` (boolean)
* `note` (text)

### `public.conges`
Stores leave requests.
* `id` (uuid, Primary Key)
* `employeeId` (uuid, Foreign Key -> `salaries.id`)
* `companyId` (uuid, Foreign Key -> `entreprises.id`)
* `leaveType` (text)
* `startDate` (timestamp)
* `endDate` (timestamp)
* `isHalfDay` (boolean)
* `status` (text)
* `comment` (text)

### `public.messages`
Logs chat history.
* `id` (uuid, Primary Key)
* `companyId` (uuid, Foreign Key -> `entreprises.id`)
* `content` (text)
* `isSentByUser` (boolean)
* `isFile` (boolean)
* `fileUrl` (text)
* `fileName` (text)
* `documentType` (text)
* `sentAt` (timestamp)
* `isRead` (boolean)

### `public.fichiers`
Catalogs uploaded documents.
* `id` (uuid, Primary Key)
* `companyId` (uuid, Foreign Key -> `entreprises.id`)
* `fileUrl` (text)
* `fileName` (text)
* `documentType` (text)
* `isSentByUser` (boolean)

### `public.utilisateurs_plateforme`
Directories HMI Stars platform staff.
* `id` (uuid, Primary Key)
* `name` (text)
* `email` (text)
* `role` (text: admin/moderator/secretary)
* `phone` (text)
* `avatarUrl` (text)
* `organization` (text)

### `public.notes_entreprises`
Internal company notes.
* `id` (uuid, Primary Key)
* `companyId` (uuid, Foreign Key -> `entreprises.id`)
* `content` (text)
* `createdBy` (uuid)

### `public.taches_urgentes`
Reminders and urgent follow-up tasks.
* `id` (uuid, Primary Key)
* `companyId` (uuid, Foreign Key -> `entreprises.id`)
* `title` (text)
* `dueDate` (timestamp)
* `status` (text)

### `public.modeles_avertissements`
Stores formal disciplinary templates.
* `id` (uuid, Primary Key)
* `title` (text)
* `contentTemplate` (text)

### `public.preferences`
User preference mappings.
* `id` (uuid, Primary Key)
* `userId` (uuid)
* `themeMode` (text)
* `enablePush` (boolean)

---

## 6. Security Isolation & Row Level Security (RLS)
PostgreSQL **Row Level Security (RLS)** is configured on Supabase to ensure complete data isolation between corporate tenants:
* **The Rule**: Each client account is assigned a `company_id` upon registration.
* **The RLS Policies**: Check incoming requests against the authenticated token claims. For example:
  ```sql
  CREATE POLICY "Allow read for tenant" ON public.salaries
    FOR SELECT
    USING (company_id = (auth.jwt() -> 'user_metadata' ->> 'company_id')::uuid);
  ```
* **Bypass Rule**: HMI Stars administrators (`utilisateurs_plateforme`) bypass these constraints depending on their dashboard roles (`admin`, `moderator`, `secretary`) to assist clients and review documents.

---

## 7. Operational Flows & Dynamic Sequences

### A. Implicit Authentication & Web Redirection (Password Recovery)
1. **Request**: The user submits their email on `ForgotPasswordScreen`. The frontend triggers `resetPasswordForEmail()` specifying a `/reset-password` deep link.
2. **Handshake**: Supabase sends an email containing a temporary verification token link. Clicking the link verifies the user and redirects them back to the Flutter router.
3. **Routing**: The URL features session data in the fragment hash (`#access_token=...`). The GoRouter parses the path and renders `ResetPasswordScreen`.
4. **Session Recovery**: The Supabase SDK intercepts the hash parameters, establishes an authenticated session in memory, and allows calling `updateUser(password: newPassword)` to securely update `auth.users` in PostgreSQL.

### B. Real-Time Chat Synchronization
1. **Subscription**: Upon entering the chat room, client and admin apps open WebSocket connections, subscribing to the channel `messages:company_id=eq.X`.
2. **Payload Submission**: Sending a message performs an HTTP POST request inserting a record into the `messages` table.
3. **CDC Broadcasting**: PostgreSQL processes the insertion, which triggers **CDC (Change Data Capture)**. Supabase broadcasts the transaction over WebSockets to all connected listeners to refresh the chat interface.

### C. Leave Request Submission & Processing
1. **Submission**: The Client submits a leave request through the app form.
2. **Validation**: The backend registers the row in `conges` and RLS validates the company scope.
3. **Notification**: The CDC listener pushes an update to the HMI dashboard. The Client Company Manager retains the administrative authority to approve or reject the request, updating the row status.

---

## 8. Functional Client and Manager Specifications

### Client Manager (Mobile App Scopes)
* **Staff Management**: View employee lists, register new employees, edit employee profiles, upload avatar pictures to storage, and archive or unarchive staff.
* **Pointage Logging**: Mark daily check-ins (Present/Absent) on pointage grids, record custom logs, and review leave statuses.
* **Leave Management**: Submit leave requests on behalf of employees and approve/reject leave.
* **Communication**: Upload KBIS, VAT, RIB, and bank statements, send warning notices to HMI, and use instant messaging.
* **Preferences**: Switch dark/light themes and update settings.

### HMI Manager (Web Dashboard Scopes)
* **Tenant Management**: Register, modify, and delete/archive client company profiles.
* **Employee Supervision**: Audit registered employee lists and export attendance logs to Excel sheets.
* **Document Processing**: Manage documents uploaded by clients and share documents back.
* **Role Provisioning**: Assign and configure staff sub-accounts as secretaries or administrators.
* **Exclusions**: The HMI Manager has no authority to approve/reject leave requests or issue warnings to client employees (those are scoped to the Client Company Manager).
