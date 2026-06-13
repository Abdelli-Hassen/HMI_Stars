#  HMI Stars — Enterprise Management & Communication Ecosystem

Welcome to the **HMI Stars** project! This repository contains a unified, multi-platform ecosystem designed to streamline communication and administrative management between **HMI Stars** (as a service provider) and its **client companies**. 

Rather than building separate backends, the entire system is structured as a **Flutter Monorepo** backed by a shared, secure **Supabase** backend.



## The Core Idea

The HMI Stars ecosystem is designed to solve a classic enterprise challenge: how can a service provider efficiently manage multiple client companies, coordinate their personnel request/absence tracking, and maintain real-time communication?

The solution consists of two tailored user experiences connected to a single source of truth:

1. **The Web Administration Platform (`/Platforme`)**
   * **Target Audience**: HMI Stars staff (Admins, Moderators, Secretaries).
   * **Purpose**: A desktop-optimized hub to onboard client companies, manage employee databases, review leave/absence records, configure contracts (CDI, CDD), and chat directly with client managers.

2. **The Mobile Client Application (`/hmistarsmobile`)**
   * **Target Audience**: Client Company Managers (directors/managers of the companies HMI Stars serves).
   * **Purpose**: A mobile-first dashboard to submit and track absence/leave requests for their teams, manage their company's employee list, and chat in real-time with the HMI Stars agency support.



##  Technological Stack & How it Works

To keep development clean, fast, and maintainable, we chose a modern, serverless-first architecture:

* **Cross-Platform Frontend (Flutter & Dart)**: Used for both the Web administration platform and the mobile application. This enables shared logic, a cohesive UI style, and high-performance components across web and mobile.
* **Backend-as-a-Service (Supabase)**:
  * **PostgreSQL Database**: Holds all relational data, including `companies`, `employees`, `absences`, and `messages`.
  * **Row Level Security (RLS)**: Crucial for enterprise privacy. RLS policies ensure that a client manager from Company A can only view, create, or update data belonging to Company A. HMI Stars administrators retain global access.
  * **Supabase Realtime (WebSockets)**: Powers the live chat system and instant status updates. When a manager submits an absence or sends a message, PostgreSQL changes are immediately broadcasted to the web platform.
  * **OTP-Driven Security (Supabase Auth)**: Account recoveries and email updates are fully secured via one-time passwords (OTP) sent directly to user mailboxes.
  * **Supabase Storage**: Manages secure file uploads, profile photos, and document attachments.



##  General Workflow

* **Onboarding**: An HMI Stars Administrator creates a new client company profile on the Web Platform. They set up the primary Client Manager's credentials.
* **Staff Coordination**: The Client Manager logs into the Mobile App. From there, they can add employees, declare absences (illness, leave), and upload supporting documents.
* **Real-time Collaboration**: If there is an issue or a custom request, the Client Manager and HMI Stars staff can instantly chat via the integrated messaging system.
* **Security & Verification**: Any sensitive changes, such as resetting a forgotten password or updating an account email, trigger secure OTP verification emails (available in both French and English).



*Developed with for HMI Stars.*

