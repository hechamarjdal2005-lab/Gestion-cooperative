# GCoop - Commercial Management for Cooperatives

GCoop is a Flutter mobile application designed for cooperatives to manage their commercial operations.

## Features
- **Role-based UI**: Admin (Super Admin) and Admin Cooperative roles.
- **Commercial Documents**: Create and manage Invoices (FAC), Quotes (DEV), Purchase Orders (BDC), and Delivery Notes (BDL).
- **Inventory Management**: Automatic stock updates via database triggers.
- **Financial Tracking**: Dashboard statistics and expense management.
- **Professional PDFs**: Generate, share, and print commercial documents.
- **Multilingual**: Full support for Arabic (RTL) and French (LTR).
- **Supabase Backend**: PostgreSQL database, Authentication, and Storage.

## Setup
1. **Database**: Run the SQL script in `sql/gcoop_full.sql` in your Supabase SQL Editor.
2. **Flutter**:
   - Update `lib/core/constants/supabase_constants.dart` with your Supabase URL and Anon Key.
   - Run `flutter pub get`.
   - Run `flutter run`.

## Dependencies
- `supabase_flutter`
- `flutter_riverpod`
- `go_router`
- `pdf` & `printing`
- `fl_chart`
- `intl`
- `share_plus`
# Gestion-cooperative
