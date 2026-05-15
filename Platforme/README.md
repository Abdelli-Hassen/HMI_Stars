# HMI Stars Consulting App

Enterprise management system mobile application for HMI Stars Consulting.

## Getting Started

This project is built using Flutter. 

## Changelog & Updates
*This section tracks what was added, changed, or removed for future presentation reference.*

### [Added] Supabase Database Schema
- **Added**: `database_schema.sql` file containing the complete Supabase backend schema.
- **Added**: Core tables mapped to Dart models (`entreprises`, `salaries`, `pointages`, `messages`, `avertissement_templates`).
- **Added**: Row Level Security (RLS) policies to ensure data isolation between different enterprises.
- **Added**: Storage buckets definition for `avatars`, `documents`, and `salaries_pieces_jointes`.
- **Changed**: Defined the relationship between Supabase `auth.users` and `entreprises` via the `entreprise_users` table for secure authentication and access control.

## Next Steps / Upcoming Work (Pre-Launch)
*This section tracks the pending tasks and features required for the upcoming launch.*

### [Pending] Supabase Integration
- **TODO**: Connect the Flutter frontend to the Supabase backend.
- **TODO**: Implement real authentication flows using Supabase Auth.
- **TODO**: Hook up state management (Providers) to fetch and mutate real data from the remote database.

### [Pending] AI & Advanced Features
- **TODO**: Implement AI-driven warning/alert generation for employees (drafting warnings dynamically based on context).
- **TODO**: Finalize real PDF export (for employee dossiers and warnings) and CSV export (for pointage) using backend data.
- **TODO**: Implement document management features (categorized filtering and real storage upload/download).
