# MatchDay ⚽

**Red social para organizar fulbitos semanales**

MatchDay es una aplicación móvil que conecta jugadores de fútbol amateur para organizar partidos semanales de manera fácil y divertida.

## 🎯 **Características Principales**

- **📱 Autenticación por SMS**: Login seguro con verificación telefónica
- **👤 Perfiles de Jugador**: Sistema de habilidades con pentágono dinámico
- **⚽ Organización de Fulbitos**: Crea y únete a partidos semanales
- **👥 Armado de Equipos**: Algoritmo inteligente para equipos balanceados
- **📊 Sistema de Calificaciones**: Los jugadores se califican entre sí
- **💬 Chat Integrado**: Comunicación fluida entre jugadores

## 🚀 **Tecnologías**

- **Frontend**: Flutter (Dart)
- **Backend**: Django REST Framework
- **Base de Datos**: PostgreSQL
- **Autenticación**: JWT + SMS
- **Arquitectura**: Provider Pattern (Clean Architecture)

## 📱 **Instalación**

```bash
# Clonar repositorio
git clone [repository-url]
cd phone_verification_app

# Instalar dependencias
flutter pub get

# Ejecutar en desarrollo
flutter run

# Generar APK
flutter build apk --debug
```

## 🎨 **Diseño**

- **Paleta de colores**: Verde y azul (inspirado en el fútbol)
- **UI/UX**: Diseño moderno y intuitivo
- **Responsive**: Adaptado para diferentes tamaños de pantalla

## 🏗️ **Arquitectura**

```
lib/
├── models/          # Modelos de datos
├── providers/       # Estado global (Provider)
├── screens/         # Pantallas de la app
├── services/        # Servicios API
├── widgets/         # Componentes reutilizables
└── config/          # Configuraciones
```

## 🔧 **Configuración de Red Local**

### **Para APK en dispositivo físico:**

1. **Configurar Django:**
   ```bash
   python manage.py runserver 192.168.100.150:8000
   ```

2. **Generar APK:**
   ```bash
   flutter build apk --debug
   ```

3. **Servir APK por HTTP:**
   ```bash
   cd build/app/outputs/flutter-apk/
   python3 -m http.server 8080
   ```

4. **Desde el celular:**
   - Ve a: `http://192.168.100.150:8080`
   - Descarga `app-debug.apk`
   - Instala la aplicación

## 🎮 **Funcionalidades Implementadas**

### ✅ **Sistema de Autenticación**
- Login por SMS con códigos de verificación
- Persistencia de sesión
- Renovación automática de tokens

### ✅ **Perfiles de Jugador**
- Datos básicos (nombre, edad, foto)
- Pentágono de habilidades dinámico
- Auto-percepción vs calificaciones promedio
- Checkbox "Buen Arquero"

### ✅ **Interfaz Principal**
- Home estilo WhatsApp
- Pestañas Fulbitos y Jugadores
- Navegación fluida entre pantallas

## 🤝 **Contribuir**

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 **Licencia**

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

**¡Organiza tu fulbito semanal con MatchDay!** ⚽🎉