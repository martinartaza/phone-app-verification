# Phone Verification App - Setup Instructions

## 🎯 What's Been Created

A complete Flutter application with 3 main screens for phone verification:

1. **Phone Input Screen** - Enter phone number with country selection
2. **Verification Screen** - Enter 6-digit SMS code with auto-verification
3. **Home Screen** - Welcome screen after successful verification

## 🔧 Configuration Required

### 1. Update API Base URL

Edit `lib/config/api_config.dart` and change:
```dart
static const String baseUrl = 'https://your-api-domain.com';
```

### 2. API Endpoints Used

The app will make these API calls:

**Send Verification Code:**
```
POST https://your-api-domain.com/api/auth/create-user/
Content-Type: application/json

{
  "phone_number": "+51999999992"
}
```

**Verify Code:**
```
POST https://your-api-domain.com/api/auth/verify-user/
Content-Type: application/json

{
  "phone_number": "+51999999992",
  "code": "123456"
}
```

## 🚀 Running the App

1. **Install dependencies:**
   ```bash
   cd phone_verification_app
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 App Flow

1. **Phone Input**: User selects country and enters phone number
2. **API Call**: App calls `/api/auth/create-user/` with phone number
3. **Verification**: User enters 6-digit code received via SMS
4. **Auto-verify**: Code is automatically verified when all 6 digits are entered
5. **API Call**: App calls `/api/auth/verify-user/` with phone and code
6. **Success**: User is taken to the home screen

## 🎨 Features Included

- ✅ Country code selection (Argentina, Peru, Chile, Colombia)
- ✅ Phone number input validation
- ✅ 6-digit code input with auto-focus
- ✅ Resend code functionality with countdown timer
- ✅ Loading states and error handling
- ✅ Beautiful gradient UI matching your design
- ✅ Responsive layout
- ✅ HTTP API integration

## 🔄 Customization

- **Add more countries**: Edit the `_countries` list in `phone_input_screen.dart`
- **Change colors**: Modify the gradient colors in each screen
- **Update API endpoints**: Edit `api_config.dart`
- **Add validation**: Enhance the validation logic in the service files

## 📁 Project Structure

```
lib/
├── config/api_config.dart       # API configuration
├── services/auth_service.dart   # HTTP API calls
├── screens/
│   ├── phone_input_screen.dart  # Screen 1: Phone input
│   ├── verification_screen.dart # Screen 2: Code verification  
│   └── home_screen.dart         # Screen 3: Welcome/success
└── main.dart                    # App entry point
```

The app is ready to run and just needs your API base URL configured!