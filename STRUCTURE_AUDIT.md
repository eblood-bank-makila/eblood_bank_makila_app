# eblood_bank_makila_app — Codebase Structure Audit

**Audit Date:** April 26, 2026  
**Project:** `/Users/delatour007/Documents/PROJECTS/EBLOOD/EBLOOD_APP/eblood_bank_makila_app`  
**Scope:** `lib/` directory (544 Dart files across 13 top-level folders)

---

## Executive Summary

This Flutter app has grown organically with **mixed French/English folder names, significant legacy code**, and **dual API endpoint schemas**. The codebase currently supports:
- **53 legacy `/eblood-connect/` endpoints** (older backend)
- **20 new `/api/v1/`, `/auth/`, `/delivery/` endpoints** (new modular backend)

Estimated restructuring effort: **80–120 hours** (folder rename + dead code removal + API migration).

---

## 1. Folder Rename Map

### Top-Level Folders in `lib/` (Current → Proposed)

| Current Name | Proposed Name | File Count | Status |
|---|---|---|---|
| `utilisateurs` | `users` | 114 | **FRENCH** — French word for "users" |
| `commande` | `orders` | 72 | **FRENCH** — French word for "orders/commands" |
| `gestionStocks` | `stock_management` | 73 | **FRENCH+CAMEL** — Mixed case, French "stock management" |
| `paiement` | `payments` | 16 | **FRENCH** — French word for "payments" |
| `delivery` | `delivery` | 11 | ✓ Already English |
| `blood_bank` | `blood_bank` | 56 | ✓ Already English (clean snake_case) |
| `blood_search_flow` | `blood_search_flow` | 25 | ✓ Already English (clean snake_case) |
| `core` | `core` | 33 | ✓ Already English (infrastructure) |
| `apps` | `apps` | 137 | ✓ Already English (highest-level entry points & shared infrastructure) |
| `qrcode` | `qr_code` | 4 | **CAMEL** — Inconsistent naming (should be snake_case for consistency) |
| `common` | `common` | 0 | ✓ Already English (no files, minimal folder) |
| `services` | `shared_services` | 1 | ✓ Already English; only 1 file, likely dead |

### Summary
- **4 folders need rename** (all due to French names): `utilisateurs`, `commande`, `gestionStocks`, `paiement`
- **1 folder needs minor fix** (camelCase to snake_case): `qrcode` → `qr_code`
- **Estimated rename operations:** ~600 import statements to update (spread across 544 files)

---

## 2. Per-Folder Analysis

### 2.1 `apps/` (137 files)
**Purpose:** Global application entry points, configuration, theme, routing, shared services, and cross-cutting concerns.

**Structure:**
```
apps/
├── config/             # API, theme, routing, enums, utilities
│   ├── api/           # DioClient, API config
│   ├── route/         # Route definitions
│   ├── theme/         # Theme configuration
│   └── ...
├── MonApplication.dart # Main app entry point
├── home/              # Home/dashboard flows
├── donor/             # Blood donor features
├── volunteer/         # Volunteer management
├── ins/               # Institution/Hospital flows
├── demarrage/         # Startup/initialization
├── debug/             # Debug utilities
├── services/          # Auth, error navigation, health structures
├── widgets/           # Shared UI components (advertisement, SVG icons)
├── models/            # API response models
├── translations/      # i18n strings
└── ...
```

**Status:** ✅ **ACTIVE & MODERN**
- Uses Riverpod providers, modern state management patterns
- Contains routing logic and configuration (AppConfig, app-wide DioClient setup)
- Well-organized by concern (theme, API, routing)

**Dead Code Indicators:** None significant; mostly entry points and configuration.

---

### 2.2 `utilisateurs/` → `users/` (114 files)
**Purpose:** User authentication, profile management, role-based access control (RBAC), and notification handling.

**Structure:**
```
utilisateurs/
├── business/
│   ├── interactors/usecase/  # Auth, password reset, notification usecases
│   ├── models/               # User, auth, notification models
│   ├── providers/            # Riverpod providers
│   └── service/              # Business service implementations
├── ui/
│   ├── pages/               # Auth, profile, notification, password change UI
│   ├── framework/           # Network/local service implementations
│   └── widgets/             # Shared UI components
└── [various duplicated pages: auth/, authentification/, motdepasse/]
```

**Status:** 🟠 **ACTIVE BUT MESSY**
- **Duplicate folder structures:** `auth/` + `authentification/` + `motdepasse/` (all handle password/auth separately)
- Uses modern Riverpod + GetX patterns inconsistently
- Mixed French/English file names within

**Dead Code Identified (18 orphaned files):**
- `ui/pages/users/EditUserPage.dart` — No imports
- `ui/pages/users/AddUserPage.dart` — No imports
- `ui/pages/patient/PatientDetailsPage.dart` — RBAC feature, likely obsolete
- `ui/pages/profil/admin/RolePermissionsPage.dart` — Admin RBAC UI, orphaned
- `business/interactors/usecase/reinitialiserPassword/*.dart` (2 files) — Legacy password reset
- Multiple model files (OtpCodeModele, NotificationResponseModel, etc.) — Unused

**Migration Target:** `/api/v1/auth/*` endpoints (login, logout, OTP validation, refresh token)

---

### 2.3 `commande/` → `orders/` (72 files)
**Purpose:** Order/cart management, blood requests (orders for blood), delivery assignments, and QR code actions.

**Structure:**
```
commande/
├── business/
│   ├── interactor/usecase/  # Blood request, delivery, panier (cart), QR actions
│   ├── model/               # Order, delivery, cart, QR models
│   └── service/             # Network services (Currency Exchange, etc.)
├── ui/
│   ├── pages/              # Blood request, commande (checkout), delivery, QR, history
│   ├── framework/          # Network/local cart, delivery, blood request services
│   └── widgets/            # Order-related UI
└── ui/debug/               # Debug pages
```

**Status:** 🟠 **ACTIVE, HIGH COMPLEXITY**
- Heavy use of `/eblood-connect/` legacy endpoints
- **Large pages:** `BloodBagOrderStepperPage.dart` (2000+ lines) — unclear separation of concerns
- Framework layer mixes network + local service patterns inconsistently

**Dead Code Identified (10+ orphaned files):**
- `business/model/panier/SuppresionPanierModel.dart` — Unused model
- `business/model/blood_request/RecupererListePanierModel.dart` — Legacy model
- `business/service/panier/PanierServiceLocalImpl.dart` — Local cache implementation, unused
- `ui/framework/blood_request/BloodRequestNetworkService.dart` (interface only, no impl)
- `ui/framework/delivery/DeliveryValidationNetworkServiceImpl.dart` — Unused delivery validation

**Migration Target:** 
- Cart/orders → `/api/v1/orders/*` (list, create, confirm, close)
- Delivery assignment → `/api/v1/main-app/create-delivery-assignment`, `/api/v1/orders/assign-delivery`
- Blood requests → Legacy, may map to orders

---

### 2.4 `gestionStocks/` → `stock_management/` (73 files)
**Purpose:** Blood inventory management (blood bags), blood bank/hospital/CNTS search, favorites, and pricing.

**Structure:**
```
gestionStocks/
├── business/
│   ├── interactor/usecase/  # Search, banque (bank), poche (bag), favoris (favorites)
│   ├── model/               # Respective models
│   └── service/             # Business services
├── ui/
│   ├── pages/              # Bank, hospital, CNTS inventory, search, favorites, location
│   ├── framework/          # Network/local service implementations
│   └── widgets/            # Stock-related UI
└── [duplicate pages: localisationBanque/, recherchePoche/]
```

**Status:** 🟠 **ACTIVE, LEGACY-HEAVY**
- **ALL endpoints are legacy `/eblood-connect/`**
- Duplicate structures: `banque/` (blood bank) + `blood_bank/` + `hospital/` + `cnts/` — inconsistent naming
- Framework layer has unused local service implementations (FavorisServiceLocalImpl)

**Dead Code Identified (12+ orphaned files):**
- `ui/pages/blood_bank/BloodBankHomePage.dart` — Orphaned page
- `ui/pages/banque/BanquePageState.dart` — Orphaned state
- `business/model/favoris/RecupererFavorisModel.dart` — Legacy model
- `ui/framework/favoris/FavorisServiceLocalImpl.dart` — Unused local cache

**Migration Target:**
- List bags → `/api/v1/blood-bank/inventory/list-bags`, `/api/v1/hospital/inventory/list-bags`, `/api/v1/cnts/inventory/list-bags`
- Get bag → `/api/v1/blood-bank/inventory/get-bag`, etc.
- Create bag (CNTS) → `/api/v1/cnts/inventory/create-bag`
- Trace bag → `/api/v1/reports/get-bag-trace`

---

### 2.5 `blood_bank/` (56 files)
**Purpose:** Blood bank-specific features: donor registration, eligibility checks, blood request lists, announcements, and inventory.

**Structure:**
```
blood_bank/
├── business/
│   ├── service/           # BloodDonorApiService (temp.dart!), blood request service
│   ├── models/            # Donor, eligibility, announcement models
│   ├── providers/         # Riverpod providers (donors, announcements, WebSocket)
│   └── interactors/       # Business logic
├── data/
│   ├── models/            # Blood request model (auto-generated .g.dart)
│   └── services/          # Data layer services
├── ui/
│   ├── pages/            # Donor registration, blood request list pages
│   └── widgets/          # Donor card, eligibility widgets
├── controllers/          # GetX controllers
├── utils/                # Helper utilities
└── services/             # Service interfaces
```

**Status:** ✅ **REASONABLY ORGANIZED, TRANSITIONING**
- Mixes newer (`/api/v1/`) and legacy (`/eblood-connect/`) endpoints
- Contains `.temp.dart` file: `BloodDonorApiService.temp.dart` — indicates refactoring in progress
- WebSocket provider for real-time features (announcements, streaming)

**Dead Code:** Minimal; mostly active.

**Migration Target:**
- Donor registration → `/eblood-connect/blood-donors/register` (legacy, needs new endpoint)
- Donor eligibility → `/eblood-connect/blood-donors/eligibility`
- Blood request list (bank/hospital) → `/eblood-connect/blood-requests/list`, `/eblood-connect/blood-requests/hospital/list`
- Confirm delivery → `/eblood-connect/blood-requests/confirm-delivery`

---

### 2.6 `blood_search_flow/` (25 files)
**Purpose:** Blood search and ordering flow for hospital/institution visitors; OTP-based login.

**Structure:**
```
blood_search_flow/
├── data/
│   └── services/       # Blood search, payment, visitor registration services
├── domain/
│   ├── entities/       # Business entities
│   └── services/       # Domain service interfaces
├── providers/          # Riverpod providers (search flow state, recent activity)
├── ui/
│   ├── pages/         # Blood search flow, results, payment, visitor phone/OTP pages
│   └── widgets/       # Search-related widgets
└── blood_search_routes.dart
```

**Status:** ✅ **CLEAN, WELL-ORGANIZED**
- Follows clean architecture (data/domain/ui layers clearly separated)
- Uses modern Riverpod patterns
- Mixes legacy (`/eblood-connect/`) and new (`/api/v1/`) endpoints

**Dead Code:** None identified.

**Migration Target:**
- Recent activity → `/eblood-connect/my-recent-activity` (legacy, may need new endpoint)
- Payment pricing → `/eblood-connect/address-access-price`, `/eblood-connect/delivery-price`
- Visitor login/OTP → `/eblood-connect/users/*` (legacy, should migrate to `/api/v1/auth/`)

---

### 2.7 `delivery/` (11 files)
**Purpose:** Delivery tracking, assignment management, and location updates for delivery personnel.

**Structure:**
```
delivery/
├── business/
│   ├── service/        # DeliveryApiService (mixed legacy + new endpoints)
│   ├── model/          # Delivery models
│   └── interactors/    # Delivery usecases
├── ui/
│   ├── pages/         # Delivery list, tracking, confirmation pages
│   └── widgets/       # Delivery-related UI
└── [no framework layer]
```

**Status:** ✅ **ACTIVE, MODERN APIS**
- **Only folder mixing legacy + new endpoints actively**
- DeliveryApiService contains both `/eblood-connect/delivery-assignment/*` (legacy) and `/delivery/deliveries/*` (new)
- Indicates active refactoring toward new modular backend

**Dead Code:** None.

**Migration Target:**
- List deliveries → `/api/v1/main-app/list-deliveries`
- Get delivery → `/api/v1/main-app/get-delivery`
- Update location → `/api/v1/delivery/publish-position`
- Stream location → `/api/v1/delivery/stream-position`
- Get tracking allowed → `/api/v1/orders/get-live-tracking-allowed`
- Available persons → `/api/v1/main-app/list-available-delivery-persons`

---

### 2.8 `paiement/` → `payments/` (16 files)
**Purpose:** Payment processing, invoicing, and payment status checking.

**Structure:**
```
paiement/
├── businness/              # NOTE: Typo in folder name ("businness")
│   ├── interactors/usecase/  # Payment usecases
│   ├── models/               # Payment models
│   └── service/              # Payment service
├── services/               # Additional service layer
├── ui/
│   ├── pages/             # Invoice, payment message pages
│   └── framework/         # Payment network services
└── [Inconsistent casing: "businness" vs "business"]
```

**Status:** 🟠 **ACTIVE, SPELLING ERROR**
- **Critical typo:** `businness/` should be `business/` (impacts 5 files)
- Mixes legacy endpoints (`/eblood-connect/cart/submit-payment`) and custom payment status checks
- Uses PDF generation for invoicing (invoice_pdf_service.dart)

**Dead Code Identified (2 orphaned files):**
- `ui/pages/invoice/InvoiceViewerPage.dart` — Unused invoice viewer
- `businness/interactors/usecase/PaiementUseCase.dart` — Unused usecase

**Migration Target:**
- Payment submission → Already mapped to `/eblood-connect/cart/submit-payment` or `/eblood-connect/blood-bank-address-request/submit-payment`
- Payment status → `/eblood-connect/blood-bank-address-request/check-payment-status`

---

### 2.9 `core/` (33 files)
**Purpose:** Cross-cutting infrastructure: network (DioClient), RBAC, configuration, dynamic forms, and utilities.

**Structure:**
```
core/
├── network/            # DioClient, dio_client_improved (dual implementations!)
├── config/             # AppConfig, API base URLs
├── rbac/               # Role-based access control system
├── dynamic_form/       # Dynamic form generation from JSON
├── models/             # System-wide models (Country, etc.)
├── services/           # Location tracking, health structure services
├── widgets/            # Reusable UI widgets (tree select, location dropdown)
└── utils/              # Utility functions
```

**Status:** 🟡 **PARTIALLY ACTIVE, DUAL IMPLEMENTATIONS**
- **Two DioClient implementations:** `dio_client.dart` (apps/config/api/) and `dio_client_improved.dart` (core/network/)
  - Both provide similar functionality; suggests incomplete refactoring
  - Unclear which is used where
- RBAC system is complex but appears orphaned (providers/services not all imported)
- Dynamic form system is modern but usage not fully traced

**Dead Code Identified (8+ orphaned files):**
- `core/config/app_config.dart` — Config file, possibly superseded
- `core/network/dio_client_improved.dart` — Redundant DioClient
- `core/widgets/tree_select_improved.dart` — Multiple similar widgets (tree_select_fixed, etc.)
- `core/rbac/data/rbac_repository.dart` — Repository pattern, likely unused

**Note:** AppConfig likely **should not be removed** despite no direct imports; it's likely imported indirectly or via module initialization.

---

### 2.10 `qrcode/` (4 files)
**Purpose:** QR code scanning and processing.

**Structure:**
```
qrcode/
├── qrcode_page.dart
├── scanner_button_widgets.dart
├── scanned_barcode_label.dart
└── scanner_error_widget.dart
```

**Status:** ✅ **MINIMAL, ACTIVE**
- Simple, focused folder; likely active
- **Naming issue:** Should be `qr_code/` (snake_case) for consistency with Flutter conventions

---

### 2.11 `common/` (0 files)
**Purpose:** (Intended for) shared/common widgets and utilities.

**Status:** ❌ **EMPTY/UNUSED**
- Folder exists but has no .dart files
- Remove or populate with truly cross-cutting utilities

---

### 2.12 `services/` (1 file)
**Purpose:** (Unclear) Likely intended for service interfaces.

**Structure:**
```
services/
└── HealthStructureService.dart
```

**Status:** ❌ **LIKELY DEAD**
- Single orphaned file
- Probably should be in `core/services/` or `apps/services/`
- No import references found

---

---

## 3. Dead Code Analysis

### 3.1 Methodology
- Scanned all 544 Dart files
- Identified files with **zero import references** from any other file in `lib/`
- Excluded generated files (`.g.dart`) and temporary files (`.temp.dart`)
- Excluded main entry points and configuration files (often not imported directly)

### 3.2 Dead Code by Folder

| Folder | Orphaned File Count | Sample Files | Confidence |
|---|---|---|---|
| `utilisateurs/` | ~18 | EditUserPage, PatientDetailsPage, RolePermissionsPage, OtpCodeModele | HIGH |
| `gestionStocks/` | ~12 | BloodBankHomePage, BloodBankInventoryPage, FavorisServiceLocalImpl, RecupererFavorisModel | HIGH |
| `commande/` | ~10 | SuppresionPanierModel, DeliveryValidationNetworkServiceImpl, BloodRequestNetworkService | HIGH |
| `paiement/` | ~2 | InvoiceViewerPage, PaiementUseCase | MEDIUM |
| `core/` | ~8 | tree_select_improved.dart, dio_client_improved.dart, location_permission_prompt.dart, cascading_location_dropdown.dart | MEDIUM |
| `blood_bank/` | ~2 | Minimal orphaned code | LOW |
| `delivery/` | ~0 | None identified | LOW |
| `blood_search_flow/` | ~0 | None identified | LOW |

### 3.3 Summary
- **~52+ orphaned files total** (9.5% of 544 files)
- **High-confidence removals:** 40 files (mostly unused UI pages and models)
- **Medium-confidence removals:** 12 files (duplicate widgets, unused service implementations)

### 3.4 Classification

#### REMOVE (Clear Orphans)
- All `_Page.dart` files in admin/user/patient sections that are unreferenced
- All unused model files ending in `Model.dart` with zero imports
- Duplicate widgets in `core/widgets/` (tree_select_fixed, tree_select_improved, location_permission_prompt, cascading_location_dropdown)
- All `*ServiceLocalImpl.dart` files (local caching not used)
- `paiement/ui/pages/invoice/InvoiceViewerPage.dart`
- `services/HealthStructureService.dart`

#### INVESTIGATE (Check Before Removal)
- `core/network/dio_client_improved.dart` — Verify which DioClient is actually used
- `core/config/app_config.dart` — May be imported dynamically; check dotenv usage
- All `*Ctrl.g.dart` and `*Interactor.g.dart` files (generated; verify generation source)
- `blood_bank/business/service/BloodDonorApiService.temp.dart` — Explicitly marked temp; confirm status

---

## 4. API Endpoint Audit

### 4.1 Legacy Endpoints (`/eblood-connect/`)

**Total: 53 distinct legacy endpoints** currently in use. These are endpoints the app currently sends requests to.

#### Cart Management (4 endpoints)
- `POST /eblood-connect/cart/add` — Add item to cart
- `GET /eblood-connect/cart` — Fetch cart contents
- `DELETE /eblood-connect/cart/remove` — Remove item from cart
- `POST /eblood-connect/cart/submit-payment` — Submit payment for cart

**Migration Target:** → `/api/v1/orders/*` (create, confirm)

#### Blood Request Management (5 endpoints)
- `GET /eblood-connect/blood-requests/list` — List blood requests
- `GET /eblood-connect/blood-requests/hospital/list` — Hospital-specific blood requests
- `GET /eblood-connect/blood-requests/{id}` — Get blood request details
- `POST /eblood-connect/blood-requests/confirm-delivery` — Confirm delivery for blood request
- `POST /eblood-connect/blood-requests/blood-bags/mark-used` — Mark blood bag as used
- `POST /eblood-connect/blood-requests/deliveries/request-coolbox-password` — Request coolbox access

**Migration Target:** → `/api/v1/orders/*` (list, get, confirm, close) + `/api/v1/delivery/*`

#### Delivery Assignment (5 endpoints, with path parameters)
- `GET /eblood-connect/delivery-assignment/pending-requests` — List pending deliveries
- `GET /eblood-connect/delivery-assignment/active-delivery` — Get currently active delivery
- `POST /eblood-connect/delivery-assignment/{id}/accept` — Accept delivery assignment
- `POST /eblood-connect/delivery-assignment/{id}/reject` — Reject delivery assignment
- `POST /eblood-connect/delivery-assignment/{id}/confirm` — Confirm delivery completion
- `POST /eblood-connect/delivery-assignment/{id}/phase` — Update delivery phase
- `POST /eblood-connect/delivery-assignment/{id}/tracking` — Publish tracking info
- `PUT /eblood-connect/delivery-assignment/update-location` — Update current location

**Migration Target:** → `/api/v1/orders/assign-delivery`, `/api/v1/main-app/create-delivery-assignment`, `/api/v1/delivery/publish-position`, etc.

#### Blood Bag Search & Inventory (6 endpoints)
- `GET /eblood-connect/blood-bags` — List blood bags (generic)
- `GET /eblood-connect/blood-bags/search-simple` — Simple search for blood bags
- `GET /eblood-connect/blood-banks/nearby` — Find nearby blood banks

**Migration Target:** → `/api/v1/blood-bank/inventory/list-bags`, `/api/v1/hospital/inventory/list-bags`, `/api/v1/cnts/inventory/list-bags`

#### Favorites (3 endpoints)
- `GET /eblood-connect/blood-bank-favory` — List favorite blood banks
- `POST /eblood-connect/blood-bank-favory` — Add favorite
- `DELETE /eblood-connect/blood-bank-favory` — Remove favorite

**Migration Target:** → New `/api/v1/favorites/*` module (if applicable)

#### Pricing (2 endpoints)
- `GET /eblood-connect/address-access-price` — Get pricing for address access
- `GET /eblood-connect/delivery-price` — Get delivery pricing
- `GET /eblood-connect/amount-exchances` — Get currency exchange rates

**Migration Target:** → `/api/v1/orders/*` (pricing included in order responses) or new `/api/v1/pricing/*` module

#### Blood Donor Features (6 endpoints)
- `POST /eblood-connect/blood-donors/register` — Register as blood donor
- `POST /eblood-connect/blood-donors/profil-photo-upload` — Upload donor profile photo
- `GET /eblood-connect/blood-donors/me` — Get current donor profile
- `GET /eblood-connect/blood-donors/history` — Get donation history
- `GET /eblood-connect/blood-donors/eligibility` — Check donor eligibility
- `GET /eblood-connect/blood-donors/top-donors` — List top donors
- `POST /eblood-connect/blood-donors/become-donor-register` — Register to become donor
- `POST /eblood-connect/blood-donors/become-volonteer-register` — Register as volunteer

**Migration Target:** → `/api/v1/donors/*` (new module needed)

#### Visitor Authentication (4 endpoints)
- `GET /eblood-connect/users/login-visitor` — Visitor login (GET!)
- `POST /eblood-connect/users/visitor-send-phone-otp` — Send OTP to visitor phone
- `POST /eblood-connect/users/visitor-verify-phone-otp` — Verify visitor OTP
- `PUT /eblood-connect/users/update-visitor-phone` — Update visitor phone number

**Migration Target:** → `/api/v1/auth/*` (login, OTP flow should be standardized)

#### Payment Status & Streaming (2 endpoints)
- `GET /eblood-connect/blood-bank-address-request/check-payment-status?identifier=X` — Check payment status
- `GET /eblood-connect/blood-bank-address-request/payment-stream?page=X&page_size=Y` — Stream payment status

**Migration Target:** → `/api/v1/orders/get-order` (payment status included) or `/api/v1/payments/status`

#### Institution/Hospital Request (3 endpoints)
- `POST /eblood-connect/ins-request/submit` — Submit institution blood request
- `GET /eblood-connect/ins-request/get-my-ins-request` — Get user's institution requests
- `GET /eblood-connect/init-ins-request-infos` — Initialize institution request form
- `POST /eblood-connect/ins-request/upload-*` (face, ID, profile photo) — Upload request documents

**Migration Target:** → New `/api/v1/institution-requests/*` module or map to `/api/v1/orders/*`

#### Miscellaneous (2 endpoints)
- `GET /eblood-connect/my-recent-activity` — Get recent activity log
- `POST /eblood-connect/firebase-messaging` — Register Firebase messaging token

**Migration Target:** → `/api/v1/activity/recent` or `/api/v1/notifications/register`

---

### 4.2 New Modular API Endpoints (`/api/v1/`, `/auth/`, `/delivery/`)

**Total: ~20+ new endpoints** in use by newer modules, especially in `delivery/` and `blood_bank/`.

#### Authentication (`/auth/`)
- `POST /auth/login` — User login
- `POST /auth/register` — User registration
- `POST /auth/logout` — Logout
- `POST /auth/validate-otp` — Validate OTP
- `GET /auth/get-specific-otp` — Fetch OTP (GET!)
- `POST /auth/initiate-device-activation` — Device activation flow
- `POST /auth/refresh-token` — Refresh access token
- `GET /auth/user-profile` — Get user profile

**Status:** ✅ Active and being used by newer authentication code

#### Delivery Module (`/delivery/deliveries/`)
- `GET /delivery/deliveries` — List all deliveries
- `GET /delivery/deliveries?status=inProgress` — Filter by status
- `GET /delivery/deliveries?status=delivered` — Get completed deliveries
- `GET /delivery/deliveries/{id}` — Get delivery details
- `PUT /delivery/deliveries/{id}/status` — Update delivery status
- `POST /delivery/deliveries/{id}/start` — Start delivery trip
- `POST /delivery/deliveries/{id}/complete` — Complete delivery
- `GET /delivery/stats` — Get delivery statistics
- `GET /delivery/activity?limit=X` — Get recent activity
- `POST /delivery/deliveries/{id}/location` — Update location
- `POST /delivery/deliveries/{id}/emergency` — Trigger emergency alert

**Status:** ✅ Active; being phased in alongside legacy endpoints

#### Other New Endpoints (emerging patterns)
- `GET /cores/get-config-roles` — Fetch RBAC configuration
- `POST /auth/` — Various auth endpoints

**Status:** 🟡 Partial adoption; legacy code still dominates

---

### 4.3 Endpoint Migration Map

Below is a mapping of **legacy endpoints → new module endpoints** based on your provided list:

| Legacy Endpoint | New Endpoint | Status | Module |
|---|---|---|---|
| `/eblood-connect/blood-requests/list` | `/api/v1/orders/list-orders` | READY | orders |
| `/eblood-connect/blood-requests/{id}` | `/api/v1/orders/get-order` | READY | orders |
| `/eblood-connect/cart/add` | `/api/v1/orders/create-order` (or cart) | READY | orders |
| `/eblood-connect/cart/submit-payment` | `/api/v1/orders/confirm-supplier` (or `/api/v1/orders/submit-payment`) | NEEDS REVIEW | orders |
| `/eblood-connect/delivery-assignment/pending-requests` | `/api/v1/main-app/list-deliveries` (or `/api/v1/orders/list-orders?status=pending_assignment`) | READY | orders / main-app |
| `/eblood-connect/delivery-assignment/{id}/accept` | `/api/v1/orders/assign-delivery` | READY | orders |
| `/eblood-connect/delivery-assignment/{id}/confirm` | `/api/v1/orders/confirm-delivery` | READY | orders |
| `/eblood-connect/delivery-assignment/update-location` | `/api/v1/delivery/publish-position` | READY | delivery |
| `/eblood-connect/delivery-price` | Pricing in `/api/v1/orders/get-order` response | NEEDS REVIEW | orders |
| `/eblood-connect/blood-bags` | `/api/v1/blood-bank/inventory/list-bags` (and hospital, cnts variants) | READY | inventory |
| `/eblood-connect/blood-bags/search-simple` | `/api/v1/blood-bank/inventory/list-bags?q=...` or new search endpoint | NEEDS DESIGN | inventory |
| `/eblood-connect/blood-donors/register` | No direct equivalent yet; needs new `/api/v1/donors/register` | **MISSING** | donors |
| `/eblood-connect/users/login-visitor` | `/api/v1/auth/login` (visitor as user type) | NEEDS REFACTOR | auth |
| `/eblood-connect/users/visitor-send-phone-otp` | `/api/v1/auth/send-otp` | NEEDS DESIGN | auth |
| `/eblood-connect/blood-requests/confirm-delivery` | `/api/v1/orders/confirm-delivery` | READY | orders |
| `/eblood-connect/blood-requests/blood-bags/mark-used` | `/api/v1/orders/mark-items-used` or similar | NEEDS DESIGN | orders |
| `/eblood-connect/firebase-messaging` | `/api/v1/notifications/register-device` | READY | notifications |
| `/eblood-connect/blood-bank-favory` | `/api/v1/favorites/manage` (if applicable) | OPTIONAL | favorites |
| `/eblood-connect/ins-request/submit` | `/api/v1/institution-requests/create` | **MISSING** | institution-requests |
| `/eblood-connect/my-recent-activity` | `/api/v1/activity/recent` or `/api/v1/orders/list-orders?sort=recent` | NEEDS DESIGN | activity |

---

## 5. Cross-Folder Coupling Analysis

### 5.1 Import Graph Summary

Strong coupling detected between these folder pairs (by frequency of cross-imports):

| From | To | Import Count | Nature | Risk |
|---|---|---|---|---|
| `apps/` | `utilisateurs/` | 80+ | Entry point imports auth | HIGH |
| `apps/` | `core/` | 70+ | Config, RBAC, network | HIGH |
| `apps/` | `commande/` | 60+ | Routing, state management | MEDIUM |
| `utilisateurs/` | `core/` | 45+ | RBAC, network, models | MEDIUM |
| `commande/` | `core/` | 40+ | Network, models | MEDIUM |
| `gestionStocks/` | `core/` | 35+ | Network, models | MEDIUM |
| `blood_search_flow/` | `utilisateurs/` | 30+ | Auth state | MEDIUM |
| `delivery/` | `core/` | 25+ | Network, models | LOW |
| `paiement/` | `commande/` | 15+ | Payment flow integration | LOW |

### 5.2 Implications for Restructuring

**Rename Safety:**
- **Highest Risk:** `core/` — renaming breaks 200+ imports across all modules. Do LAST.
- **High Risk:** `utilisateurs/` → `users/` — 80+ apps imports, plus 45+ core imports. Must update systematically.
- **Medium Risk:** `commande/` → `orders/` — 60+ apps imports, 40+ core imports. Coordinated update needed.
- **Lower Risk:** Others (fewer cross-folder dependencies).

**Recommendation:** Rename in this order:
1. `paiement/` → `payments/` (lowest coupling)
2. `gestionStocks/` → `stock_management/` (medium coupling)
3. `commande/` → `orders/` (high coupling; but fewer files than utilisateurs)
4. `qrcode/` → `qr_code/` (trivial; 4 files)
5. `utilisateurs/` → `users/` (last; affects most other modules)
6. `core/` → `core/` (don't rename; infrastructure is stable)

---

## 6. Suggested Target Structure (Post-Restructure)

```
lib/
├── core/                        # ✓ Keep as-is (infrastructure)
│   ├── network/                 # Consolidated DioClient (remove redundancy)
│   ├── config/                  # App configuration
│   ├── rbac/                    # Access control
│   ├── models/                  # Core domain models
│   ├── services/                # Utilities (location, health structures)
│   └── widgets/                 # Reusable UI (single tree_select, single dropdown)
│
├── apps/                        # ✓ Keep as-is (high-level entry points)
│   ├── config/                  # App-wide config
│   ├── services/                # Auth service, error navigation, etc.
│   ├── widgets/                 # Shared UI (ads, icons)
│   ├── donor/                   # Blood donor features
│   ├── volunteer/               # Volunteer management
│   ├── ins/                     # Institution flows
│   ├── home/                    # Dashboard/home
│   └── ...
│
├── users/                       # ← Renamed from utilisateurs/
│   ├── business/
│   │   ├── interactors/         # Auth, password, notification usecases
│   │   ├── models/              # User models (consolidate: remove old/duplicate models)
│   │   ├── providers/           # Riverpod state
│   │   └── service/             # Business logic
│   └── ui/
│       ├── pages/               # Auth, profile, settings
│       │   └── auth/            # CONSOLIDATE: merge authentification/, motdepasse/, auth/ into single auth/
│       ├── framework/           # Network/local service impls
│       └── widgets/
│
├── orders/                      # ← Renamed from commande/
│   ├── business/
│   │   ├── interactors/         # Blood request, delivery, cart, QR usecases
│   │   ├── models/              # Order, delivery, cart models (REMOVE: Suppression*, Recuperer*, etc.)
│   │   └── service/             # Business services
│   └── ui/
│       ├── pages/               # Order flow, delivery, history
│       │   ├── checkout/        # Replaces commande/panier/
│       │   ├── delivery/
│       │   ├── history/         # Replaces historique/
│       │   └── qr_action/
│       ├── framework/           # Service implementations
│       └── widgets/
│
├── stock_management/            # ← Renamed from gestionStocks/
│   ├── business/
│   │   ├── interactors/         # Search, bank, bag, favorites usecases
│   │   ├── models/              # Stock models (REMOVE: Recuperer*, Banque*, etc.)
│   │   └── service/             # Business services
│   └── ui/
│       ├── pages/               # Bank/hospital/CNTS inventory, search, favorites
│       │   ├── inventory/       # CONSOLIDATE: merge banque/, hospital/, blood_bank/, cnts/ into single inventory/
│       │   ├── search/
│       │   └── favorites/
│       ├── framework/           # Service implementations (REMOVE: FavorisServiceLocalImpl, etc.)
│       └── widgets/
│
├── payments/                    # ← Renamed from paiement/
│   ├── business/                # ← Fix typo: business/ (not businness/)
│   │   ├── interactors/
│   │   ├── models/
│   │   └── service/
│   └── ui/
│       ├── pages/               # Invoice, payment status
│       │   ├── invoice/
│       │   └── checkout/        # Payment portion of order
│       ├── framework/
│       └── widgets/
│
├── blood_bank/                  # ✓ Keep mostly as-is (minimal refactor needed)
│   ├── business/
│   │   ├── service/             # Fix: BloodDonorApiService.temp.dart (remove .temp)
│   │   ├── models/
│   │   ├── providers/
│   │   └── interactors/
│   ├── data/
│   └── ui/
│       ├── pages/
│       └── widgets/
│
├── blood_search_flow/           # ✓ Keep as-is (well-organized)
│   ├── data/
│   ├── domain/
│   ├── providers/
│   └── ui/
│
├── delivery/                    # ✓ Keep as-is (active, transitioning)
│   ├── business/
│   ├── ui/
│   └── [add framework/ layer for consistency]
│
├── qr_code/                     # ← Renamed from qrcode/
│   └── [4 files as-is]
│
├── shared/                      # ← NEW: consolidate common utils
│   ├── widgets/                 # Common UI components
│   ├── utilities/               # Helpers, extensions
│   └── constants/               # Shared constants
│
└── main.dart, firebase_options.dart  # Root-level entry points
```

### Key Changes
1. **Consolidate duplicate pages:** Merge `auth/` + `authentification/` + `motdepasse/` into single `users/ui/pages/auth/`
2. **Flatten stock management:** Merge `banque/`, `hospital/`, `blood_bank/`, `cnts/` pages into `stock_management/ui/pages/inventory/`
3. **Remove duplicate framework:** Delete unused `*ServiceLocalImpl.dart` files across all modules
4. **Fix core/:** Remove one of the two DioClient implementations; consolidate tree_select and dropdown widgets
5. **Fix typo:** `paiement/businness/` → `payments/business/`
6. **Extract common:** Create `shared/` folder for truly cross-cutting utilities
7. **Add missing structure:** Create `framework/` layer consistently in `delivery/` module

---

## 7. Effort Estimate for Restructuring (Phase 2)

This audit is **Phase 1 (read-only)**. Execution would be **Phase 2**.

### 7.1 Folder Rename & Import Fixup

| Task | Files Affected | Estimated Hours | Complexity |
|---|---|---|---|
| Rename `utilisateurs/` → `users/` | 114 files + 80 imports | 8–10 | HIGH (many cross-refs) |
| Rename `commande/` → `orders/` | 72 files + 60 imports | 5–7 | MEDIUM |
| Rename `gestionStocks/` → `stock_management/` | 73 files + 35 imports | 5–6 | MEDIUM |
| Rename `paiement/` → `payments/` | 16 files + 15 imports | 2–3 | LOW |
| Rename `qrcode/` → `qr_code/` | 4 files + 5 imports | 0.5–1 | TRIVIAL |
| **Subtotal: Renaming** | **~300 import updates** | **20–27 hours** | |

### 7.2 Dead Code Removal

| Task | Files to Remove | Estimated Hours | Notes |
|---|---|---|---|
| Remove orphaned UI pages (utilisateurs, commande, gestionStocks) | ~30 files | 3–4 | Straightforward file deletion |
| Remove unused model files | ~15 files | 2–3 | Verify no dynamic imports |
| Remove duplicate widgets in core/ | ~5 files | 1–2 | Consolidate tree_select, dropdown logic |
| Remove unused service implementations (*LocalImpl, *ServiceImpl) | ~8 files | 2–3 | Check for any last-minute references |
| **Subtotal: Dead Code Removal** | **~58 files** | **8–12 hours** | |

### 7.3 Dead Code in Apps Module
- `apps/` is complex (137 files); likely contains some unused screens/pages
- **Estimated:** 5–10 additional pages; 4–6 hours to audit + remove

---

### 7.4 API Endpoint Migration

| Task | Endpoints Affected | Estimated Hours | Complexity |
|---|---|---|---|
| Migrate `/eblood-connect/cart/*` → `/api/v1/orders/*` | 4 endpoints | 6–8 | Requires backend coordination |
| Migrate `/eblood-connect/blood-requests/*` → `/api/v1/orders/*` | 5 endpoints | 5–7 | Data model alignment needed |
| Migrate `/eblood-connect/delivery-assignment/*` → `/api/v1/orders/assign-delivery` + `/api/v1/delivery/*` | 8 endpoints | 8–10 | Complex state transitions |
| Migrate `/eblood-connect/blood-bags/*` → `/api/v1/blood-bank/inventory/*`, etc. | 6 endpoints | 4–6 | Three variants (bank, hospital, CNTS) |
| Migrate `/eblood-connect/blood-donors/*` → New `/api/v1/donors/*` (backend missing!) | 8 endpoints | 10–15 | **Backend endpoints need to be created** |
| Migrate `/eblood-connect/users/visitor-*` → `/api/v1/auth/*` | 4 endpoints | 3–4 | OTP flow standardization |
| Migrate `/eblood-connect/ins-request/*` → New `/api/v1/institution-requests/*` | 4 endpoints | 8–12 | **Backend endpoints need to be created** |
| Migrate `/eblood-connect/blood-bank-favory` → TBD (optional feature) | 3 endpoints | 2–4 | Low priority |
| Migrate misc endpoints (pricing, activity, Firebase) | 6 endpoints | 4–5 | Straightforward replacements |
| **Subtotal: API Migration** | **53 legacy endpoints** | **50–70 hours** | **HIGH** (backend dependency) |

### 7.5 Code Organization & Consolidation

| Task | Scope | Estimated Hours |
|---|---|---|
| Consolidate duplicate auth pages (auth/, authentification/, motdepasse/) | ~15 files merged | 6–8 |
| Consolidate duplicate stock inventory pages (banque/, hospital/, blood_bank/, cnts/) | ~20 files merged | 8–10 |
| Refactor `core/` (fix dual DioClient, consolidate widgets) | ~8 files refactored | 4–6 |
| Fix `paiement/businness/` → `paiement/business/` typo | 5 files | 1 |
| Extract `shared/` module from common utilities | ~10 files moved | 3–4 |
| **Subtotal: Organization** | | **22–29 hours** |

---

### 7.6 Testing & Verification

| Task | Scope | Estimated Hours |
|---|---|---|
| Unit test updates (fix import paths in test files) | Estimated 50+ test files | 5–8 |
| Integration testing (verify renamed modules work end-to-end) | 8–10 critical flows | 10–15 |
| Manual testing (QA across all features) | Full app regression | 15–20 |
| **Subtotal: Testing** | | **30–43 hours** |

---

### 7.7 Total Effort Summary

```
┌─────────────────────────────────────────┬──────────────────┐
│ Phase                                   │ Hours (Low–High) │
├─────────────────────────────────────────┼──────────────────┤
│ 1. Folder Rename + Import Fixup         │ 20–27 hours      │
│ 2. Dead Code Removal                    │ 12–18 hours      │
│ 3. API Endpoint Migration               │ 50–70 hours      │
│ 4. Code Organization & Consolidation    │ 22–29 hours      │
│ 5. Testing & Verification               │ 30–43 hours      │
├─────────────────────────────────────────┼──────────────────┤
│ TOTAL (Optimistic)                      │ 134 hours        │
│ TOTAL (Realistic)                       │ 160–180 hours    │
│ TOTAL (With Padding)                    │ 200 hours (max)  │
└─────────────────────────────────────────┘
```

### 7.8 Critical Dependencies
- **Backend Readiness:** New endpoints for `/api/v1/donors/*`, `/api/v1/institution-requests/*`, and refined ordering API must be ready
- **Staging Environment:** Full integration environment needed for end-to-end testing
- **Feature Flags:** Consider shipping code under feature flags to avoid breaking changes mid-migration
- **Rollback Plan:** Each endpoint migration should have a rollback strategy (dual-write, feature toggles)

---

## 8. Recommendations

### Priority 1: Before Restructure
1. **Fix typo:** Rename `paiement/businness/` → `paiement/business/` immediately (5-minute task, reduces confusion)
2. **Consolidate DioClient:** Remove `core/network/dio_client_improved.dart` or `apps/config/api/dio_client.dart` (one is redundant)
3. **Remove obvious dead code:** Delete all unreferenced `_Page.dart` and `_Model.dart` files (low risk)
4. **Create feature branch:** This restructure is a breaking change; use a dedicated branch

### Priority 2: Parallel with Restructure
1. **Coordinate with backend team:** Ensure new `/api/v1/` endpoints are ready before client-side migration
2. **Use IDE refactoring tools:** Tools like Android Studio's "Rename" and "Move" packages can automate much of the import fixing
3. **Create migration checklist:** Track each endpoint migration and its corresponding test cases

### Priority 3: Post-Restructure
1. **Update documentation:** Update README with new folder structure and API endpoint mappings
2. **Create API migration guide:** Document which legacy endpoint maps to which new endpoint
3. **Set up monitoring:** Track usage of legacy endpoints post-migration to ensure clean transition
4. **Plan endpoint deprecation:** Set timeline for removing legacy `/eblood-connect/` endpoints

---

## 9. Files to Review Manually Before Action

Before running any restructuring, manually verify these files:

1. **`core/config/app_config.dart`** — May be imported dynamically (dotenv); don't remove without checking
2. **`core/network/dio_client_improved.dart`** — Verify which DioClient is actually used in production
3. **`blood_bank/business/service/BloodDonorApiService.temp.dart`** — Explicitly marked temp; confirm intent
4. **All `.g.dart` files** — Verify they're generated (should be); don't commit these to source control
5. **`apps/services/AuthService.dart`** — Critical for auth flow; verify no hidden dependencies

---

## 10. Conclusion

This codebase shows signs of **organic growth without centralized architecture governance**. The presence of:
- Dual API schemas (`/eblood-connect/` vs. `/api/v1/`)
- Dual DioClient implementations
- French/English folder name mixing
- Duplicate module structures (auth pages, stock pages)
- Dead code (5–10% of files)

...indicates a transition in progress from a legacy monolith to a modular backend.

**Restructuring this codebase is valuable but requires careful coordination.** The most risky phase is API migration (50–70 hours), which depends entirely on backend readiness. The folder renaming (20–27 hours) and dead code removal (12–18 hours) are low-risk and should be done first.

**Recommendation:** Phase this work:
1. **Phase 2a (Week 1):** Rename folders + fix imports + remove dead code (50 hours)
2. **Phase 2b (Weeks 2–4):** Migrate APIs in sprints, with feature flags (100 hours)
3. **Phase 2c (Ongoing):** Monitor and clean up legacy endpoint usage

---

**Audit Document End**
