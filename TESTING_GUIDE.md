# 🧪 Guía de Testing - Fulbito App

## 📱 **Flujo Completo de Testing**

### **1️⃣ Primera Ejecución (Usuario Nuevo)**
```bash
flutter run --debug
```

**Flujo esperado:**
1. **Splash Screen** → Verifica datos locales
2. **Phone Input** → Ingresa número de teléfono argentino
3. **Verification** → Ingresa código de verificación
4. **Profile Screen** → Completa perfil de jugador
5. **Home Screen** → Pantalla principal estilo WhatsApp

### **2️⃣ Segunda Ejecución (Usuario Existente)**
```bash
flutter run --debug
```

**Flujo esperado:**
1. **Splash Screen** → Encuentra datos guardados
2. **Profile Screen** → Si no tiene perfil completo
3. **Home Screen** → Si ya completó el perfil

---

## 🎯 **Testing del Perfil de Usuario**

### **Datos a Probar:**
- **Nombre**: 4-20 caracteres, sin espacios
- **Edad**: Selector numérico (default 30)
- **Foto**: Galería o cámara
- **Habilidades**: 5 sliders (0-100)
  - Velocidad ⚡
  - Resistencia 💪
  - Tiro a arco ⚽
  - Gambeta 🏃
  - Pases 🎯
- **Buen Arquero**: Checkbox

### **Validaciones a Verificar:**
- ❌ Nombre < 4 caracteres
- ❌ Nombre > 20 caracteres  
- ❌ Nombre con espacios
- ✅ Pentágono se actualiza en tiempo real
- ✅ Botón "Finalizar Perfil" habilitado solo con nombre válido

---

## 🏠 **Testing del Home Screen**

### **Elementos a Verificar:**
- **Header verde** con lupa y foto de perfil
- **Título "Fulbito"** en el header
- **2 pestañas**: Fulbitos y Jugadores
- **Navegación**: Click en foto → va al perfil
- **Estados vacíos** con iconos y mensajes

### **Navegación:**
- Home → Profile (click en foto)
- Profile → Home (después de "Finalizar Perfil")

---

## 🔧 **Comandos Útiles**

### **Limpiar y Reinstalar:**
```bash
flutter clean
flutter pub get
flutter run --debug
```

### **Ver Logs Detallados:**
```bash
flutter logs
```

### **Resetear Datos (Testing):**
```bash
# En el emulador: Settings → Apps → Fulbito → Storage → Clear Data
```

### **Hot Reload Durante Testing:**
```bash
# Presiona 'r' en la terminal para hot reload
# Presiona 'R' para hot restart completo
```

---

## 📊 **Logs Esperados**

### **Al Iniciar:**
```
📱 Número de teléfono recuperado: +549...
🔢 Código de verificación recuperado: 123456
🔍 Verificando datos locales:
  - phoneNumber: +549...
  - verificationCode: 123456
  - isLoggedIn: true
```

### **Al Guardar Perfil:**
```
📤 MOCK API CALL - POST /api/profile/create/
📤 Headers: Authorization: Bearer ...
📤 Body: {name: "Juan", age: 25, skills: {...}}
📥 Response: {user_skills: {...}, profile_completed: true}
💾 Profile saved locally
```

### **Al Cargar Perfil:**
```
📥 MOCK API CALL - GET /api/profile/me/
📥 Headers: Authorization: Bearer ...
📥 Response: Profile loaded from local storage
```

---

## 🎨 **Verificación Visual**

### **Colores del Tema:**
- **Verde**: `#059669` (header)
- **Púrpura**: `#8B5CF6` (sliders, botones)
- **Gradientes**: Verde → Verde claro, Púrpura → Rosa

### **Pentágono:**
- **Fondo**: Líneas grises con 5 niveles
- **Datos**: Área púrpura semitransparente
- **Labels**: Velocidad, Resistencia, Tiro a arco, Gambeta, Pases

### **Responsive:**
- Funciona en diferentes tamaños de pantalla
- Scroll cuando el contenido es largo
- Sliders se adaptan al ancho disponible

---

## 🐛 **Problemas Conocidos**

1. **Warnings de deprecated**: `withOpacity` → No afecta funcionalidad
2. **Print statements**: Solo para debugging, se pueden ignorar
3. **OpenGL ES warnings**: Del emulador, no afecta la app

---

## ✅ **Checklist de Testing**

- [ ] App inicia correctamente
- [ ] Navegación login → perfil funciona
- [ ] Todos los campos del perfil funcionan
- [ ] Validación de nombre funciona
- [ ] Pentágono se actualiza en tiempo real
- [ ] Foto de perfil se puede seleccionar
- [ ] Botón "Finalizar Perfil" funciona
- [ ] Navegación perfil → home funciona
- [ ] Header del home se ve correctamente
- [ ] Pestañas del home funcionan
- [ ] Click en foto del home → va al perfil
- [ ] Datos se guardan localmente
- [ ] App recuerda datos al reiniciar

---

## 🚀 **Próximos Pasos**

Una vez que confirmes que todo funciona correctamente, podemos continuar con:

1. **Pantalla de creación de fulbitos**
2. **Sistema de invitaciones**
3. **Armado automático de equipos**
4. **Chat grupal integrado**
5. **Sistema de calificaciones entre jugadores**

¡La base está sólida para construir toda la funcionalidad de la red social de fútbol! ⚽🎯