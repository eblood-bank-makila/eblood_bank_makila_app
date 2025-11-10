# Health Structure Registration Stepper - Visual Guide

## How to Access the Stepper

The stepper is now active at the route `/hospital-registration`. When users select "Health Structure Account" from the account type selection page, they will see the new stepper interface.

## Stepper Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Health Structure Registration                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Step 1: Location Information  ✓                            │
│  Step 2: Health Structure Type                              │
│  Step 3: Structure Information                              │
│  Step 4: Admin Account Information                          │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [Current Step Content Here]                                │
│                                                              │
│  [Form Fields for Current Step]                             │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [Cancel Button]                    [Continue Button]       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Step-by-Step Breakdown

### Step 1: Location Information
```
┌─────────────────────────────────────────────────────────────┐
│  Location Information                                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Select your location:                                       │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Location Tree Select                                 │  │
│  │ ├─ Country 1                                         │  │
│  │ │  ├─ Province 1                                    │  │
│  │ │  │  ├─ Town 1                                     │  │
│  │ │  │  └─ Town 2                                     │  │
│  │ │  └─ Province 2                                    │  │
│  │ ├─ Country 2                                         │  │
│  │ └─ Country 3                                         │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  [Cancel]                              [Continue]           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Step 2: Health Structure Type
```
┌─────────────────────────────────────────────────────────────┐
│  Health Structure Type                                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Select the type of health structure:                        │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ 🩸 Blood  │ │ 🏥 General│ │ 🏥 Clinic│ │ 💊 Pharmacy│      │
│  │  Bank    │ │ Hospital │ │          │ │          │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ 🏥 Health │ │ 👶 Maternity│ │ 🔬 Medical│ │ ♿ Rehab    │      │
│  │ Center   │ │          │ │  Lab     │ │ Center   │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│                                                              │
│  [More types available...]                                   │
│                                                              │
│  [Cancel]                              [Continue]           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Step 3: Structure Information
```
┌─────────────────────────────────────────────────────────────┐
│  Structure Information                                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Structure Name *                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ [Enter structure name]                               │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Email *                                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ [Enter email]                                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Address *                                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ [Enter address]                                      │  │
│  │ [Multi-line input]                                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Longitude              Latitude                             │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ [Enter longitude]│  │ [Enter latitude] │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  [📍 Use Current Location]                                   │
│                                                              │
│  [Cancel]                              [Continue]           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Step 4: Admin Account Information
```
┌─────────────────────────────────────────────────────────────┐
│  Admin Account Information                                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  First Name *              Last Name *                       │
│  ┌──────────────────────┐  ┌──────────────────────┐         │
│  │ [Enter first name]   │  │ [Enter last name]    │         │
│  └──────────────────────┘  └──────────────────────┘         │
│                                                              │
│  Gender *                                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ [Select gender ▼]                                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Email *                                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ [Enter email]                                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Password *                                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ [Enter password] 👁️                                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Confirm Password *                                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ [Confirm password] 👁️                                │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  [Cancel]                              [Submit]             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## User Interactions

### Navigation Between Steps
- **Continue Button**: Validates current step and moves to next step
- **Cancel Button**: Returns to previous step (disabled on Step 1)
- **Step Headers**: Click any step header to jump directly to that step
- **Validation**: Each step must be valid before proceeding

### Data Preservation
- All entered data is preserved when navigating between steps
- Users can go back and edit previous steps
- Form data is only submitted after final step validation

### On Final Submission
1. All steps are validated
2. Registration payload is created
3. User is navigated to email verification page
4. Email verification is required before account creation

## Features Highlighted

✅ **Progressive Disclosure** - Users see one section at a time
✅ **Clear Progress** - Step indicators show where they are
✅ **Flexible Navigation** - Can move between steps easily
✅ **Data Persistence** - No data loss when navigating
✅ **Comprehensive Validation** - Each step validates before proceeding
✅ **Mobile Friendly** - Smaller form sections fit mobile screens
✅ **Accessibility** - Clear labels and error messages

## Testing the Stepper

1. Navigate to `/account-type-selection`
2. Click "Health Structure Account"
3. Choose registration method (Email or Google)
4. You should see the 4-step stepper form
5. Fill in each step and click Continue
6. On the final step, click Submit to proceed to email verification

## Troubleshooting

If you don't see the stepper:
1. Make sure you're on the `/hospital-registration` route
2. Check that `HealthStructureRegistrationStepperPage.dart` is imported in `GoRouter.dart`
3. Verify the route is using `HealthStructureRegistrationStepperPage` (not the old page)
4. Run `flutter clean && flutter pub get` to refresh dependencies
5. Restart the app

