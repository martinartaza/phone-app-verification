# Phone Verification App

A Flutter application with phone number verification flow using SMS codes.

## Features

- **Phone Input Screen**: Enter phone number with country selection
- **Verification Screen**: Enter 6-digit SMS verification code
- **Home Screen**: Welcome screen after successful verification

## API Integration

The app integrates with your backend API for phone verification:

### Endpoints Used:
1. `POST /api/auth/create-user/` - Send verification code
2. `POST /api/auth/verify-user/` - Verify the code

### Configuration

Update the API base URL in `lib/config/api_config.dart`:

```dart
static const String baseUrl = 'https://your-api-domain.com';
```

Or modify the settings file at `assets/config/settings.json`.

## API Request Examples

### Create User (Send Code)
```json
POST https://your-api-domain.com/api/auth/create-user/
{
  "phone_number": "+51999999992"
}
```

### Verify User
```json
POST https://your-api-domain.com/api/auth/verify-user/
{
  "phone_number": "+51999999992",
  "code": "123456"
}
```

## Getting Started

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Update the API base URL in the configuration files

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── config/
│   └── api_config.dart          # API configuration
├── screens/
│   ├── phone_input_screen.dart  # Phone number input
│   ├── verification_screen.dart # Code verification
│   └── home_screen.dart         # Welcome/home screen
├── services/
│   └── auth_service.dart        # API service calls
└── main.dart                    # App entry point
```

## Customization

- Update country codes in `phone_input_screen.dart`
- Modify UI colors and styling in each screen
- Change API endpoints in `api_config.dart`
- Add additional validation or features as needed

## Dependencies

- `http: ^1.1.0` - For API calls
- `flutter/material.dart` - Material Design components