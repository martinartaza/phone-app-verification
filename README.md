# 📱 Flutter Login Base - Verificación por SMS

Una aplicación base de Flutter para autenticación por SMS con arquitectura limpia y mejores prácticas. Perfecta como base para múltiples proyectos.

## 🎯 **Funcionalidades**

### ✅ **Login Completo:**
- Entrada de número de teléfono con selección de país
- Verificación por código SMS de 6 dígitos
- Auto-verificación cuando se completa el código
- Timer de reenvío de código (55 segundos)

### ✅ **Gestión de Tokens:**
- **Access Token** y **Refresh Token** guardados localmente
- **Renovación automática** de tokens expirados
- **Refresh token válido por 10 días** (según tu API)
- Re-verificación genera **nuevos tokens** automáticamente

### ✅ **Persistencia Completa:**
- **Número de teléfono** guardado permanentemente
- **Código de verificación** almacenado
- **Tokens JWT** persistentes
- **Datos del usuario** completos
- **Estado de autenticación** mantenido entre sesiones

### ✅ **Arquitectura Profesional:**
- **Provider Pattern** para gestión de estado
- **Separación de responsabilidades** (UI, lógica, servicios)
- **Código reutilizable** y mantenible
- **Testing fácil** (lógica separada de UI)

## 🏗️ **Estructura del Proyecto**

```
lib/
├── main.dart                     # Configuración de providers
├── config/
│   └── api_config.dart          # Configuración de API
├── models/
│   └── auth_response.dart       # Modelos de respuesta
├── providers/                   # 🧠 LÓGICA DE NEGOCIO
│   ├── auth_provider.dart       # Estado global de autenticación
│   ├── phone_input_provider.dart # Lógica del formulario
│   └── verification_provider.dart # Lógica del timer y verificación
├── services/                    # 🌐 SERVICIOS EXTERNOS
│   ├── auth_service.dart        # Comunicación con API
│   └── storage_service.dart     # Persistencia local
└── screens/                     # 🎨 SOLO UI
    ├── phone_input_screen.dart  # Pantalla de teléfono
    ├── verification_screen.dart # Pantalla de código
    └── home_screen.dart         # Pantalla principal
```

## 🔧 **Configuración**

### 1. **API Configuration**
Edita `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://TU-IP:8000';  // ← Cambiar aquí
  
  static const String createUserEndpoint = '/api/auth/request-code/';
  static const String verifyUserEndpoint = '/api/auth/verify-user/';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token/';
}
```

### 2. **Respuesta del API**
La app maneja esta estructura JSON de tu Django API:

```json
{
  "status": "success",
  "message": "Usuario verificado exitosamente",
  "data": {
    "id": 11,
    "username": "+5444556677",
    "is_active": true,
    "profile": {
      "phone_number": "+5444556677",
      "is_verified": true
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

## 🚀 **Instalación y Uso**

### 1. **Instalar dependencias:**
```bash
flutter pub get
```

### 2. **Configurar tu API:**
- Actualiza `baseUrl` en `api_config.dart`
- Asegúrate que tu Django API esté corriendo

### 3. **Ejecutar:**
```bash
flutter run
```

## 📱 **Flujo de la Aplicación**

### **Primera vez:**
1. Usuario ingresa número → **Se guarda automáticamente**
2. Recibe SMS → Ingresa código
3. API responde con tokens → **Todo se guarda localmente**
4. Va al Home → **Sesión persistente**

### **Aperturas posteriores:**
1. App verifica datos guardados
2. **Token válido** → Directo al Home
3. **Token expirado** → Renueva automáticamente
4. **No se puede renovar** → Vuelve al login

### **Re-verificación:**
- Si envías el mismo número + código múltiples veces
- **API devuelve nuevos tokens** (refresh token válido 10 días)
- **App actualiza tokens automáticamente**

## 🔐 **Datos Almacenados**

La app guarda localmente:
- ✅ **Número de teléfono**
- ✅ **Código de verificación**
- ✅ **Access token**
- ✅ **Refresh token** (10 días de validez)
- ✅ **Datos completos del usuario**
- ✅ **Estado de autenticación**

## 🛠️ **Personalización para Nuevos Proyectos**

### **Cambiar países:**
Edita `phone_input_provider.dart`:
```dart
final List<Map<String, String>> _countries = [
  {'name': 'México', 'code': '+52', 'flag': '🇲🇽'},
  // Agregar más países...
];
```

### **Cambiar endpoints:**
Edita `api_config.dart`:
```dart
static const String createUserEndpoint = '/tu/endpoint/';
```

### **Cambiar UI:**
- Colores en cada `screen/`
- Gradientes y estilos
- Iconos y textos

### **Agregar funcionalidades:**
1. Crear nuevo `provider` para la lógica
2. Crear nueva `screen` para la UI
3. Agregar al `MultiProvider` en `main.dart`

## 🧪 **Testing**

La arquitectura permite testing fácil:

```dart
// Testear lógica sin UI
test('should validate phone number', () {
  final provider = PhoneInputProvider();
  provider.setPhoneNumber('123456789');
  expect(provider.isPhoneNumberValid(), true);
});
```

## 📦 **Dependencias**

```yaml
dependencies:
  flutter: sdk
  provider: ^6.1.1        # Gestión de estado
  http: ^1.1.0           # Peticiones HTTP
  shared_preferences: ^2.2.2  # Persistencia local
```

## 🎯 **Casos de Uso**

Esta base es perfecta para:
- 🏪 **Apps de e-commerce** con login por SMS
- 🏦 **Apps financieras** con verificación segura
- 🚗 **Apps de servicios** (Uber, delivery, etc.)
- 📱 **Cualquier app** que necesite autenticación por teléfono

## 🔄 **Próximos Pasos**

Para usar como base en nuevos proyectos:
1. **Clonar** este proyecto
2. **Cambiar** `baseUrl` y endpoints
3. **Personalizar** UI y colores
4. **Agregar** funcionalidades específicas del proyecto
5. **Mantener** la arquitectura limpia

---

**¡Aplicación base lista para ser reutilizada en múltiples proyectos!** 🚀