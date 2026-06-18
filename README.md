# BusQalo

Aplicación móvil de Android para el seguimiento en tiempo real de rutas de transporte público en el área de Barranquilla, Colombia.

## Descripción

BusQalo permite a los usuarios visualizar rutas de bus en un mapa interactivo, buscar destinos, rastrear la ubicación en tiempo real de los buses y gestionar sus viajes diarios de forma más eficiente. La aplicación cuenta con un panel de administración para que las empresas de transporte puedan gestionar rutas, paradas, buses, conductores y proveedores.

## Características Principales

### Para Usuarios
- **Mapa Interactivo**: Visualiza rutas de bus como polilíneas y buses cercanos como marcadores en tiempo real
- **Búsqueda de Destinos**: Autocompletado de ubicaciones con coincidencia de rutas
- **Rastreo en Vivo**: Ubicación actualizada de buses dentro de un radio de 200 metros
- **Gestión de Rutas**: Explora todas las rutas disponibles con horarios y paradas
- **Favoritos y Recordatorios**: Guarda rutas frecuentes y configura alertas (característica Premium)
- **PQRS**: Envía peticiones, quejas, reclamos y sugerencias
- **Suscripción Premium**: Acceso a características avanzadas por COP $9,900/mes

### Panel de Administración
- **Gestión de Conductores**: Agregar, editar y eliminar conductores (nombre, cédula, salario, teléfono, fecha de nacimiento)
- **Gestión de Buses**: Administración de flota con conductores y proveedores asignados
- **Gestión de Proveedores**: Control de empresas de transporte con comisiones y fechas de contrato
- **Gestión de Rutas**: Creación y edición de rutas con paradas y buses asignados
- **Gestión de Paradas**: Creación y edición de paradas con ubicación geográfica
- **Emisión de Ubicación en Vivo**: Broadcasting de ubicación en tiempo real para buses

## Tecnologías

| Componente | Tecnología |
|------------|------------|
| Frontend | Flutter (Dart) |
| Backend | Firebase (Firestore, Authentication) |
| Mapas | Google Maps Flutter SDK |
| Ubicación | Geolocator, Google Places SDK |
| Autenticación | Firebase Auth + Google Sign-In |
| API | Google Directions API |

## Requisitos

- **Android mínimo**: API nivel 23 (Android 6.0 Marshmallow)
- **Flutter SDK**: ^3.8.1

## Estructura de la Base de Datos (Firestore)

- `users` - Perfiles de usuarios
- `rutas` - Rutas de buses (nombre, horarios, puntos, buses)
- `paradas` - Paradas de bus (nombre, coordenadas)
- `buses` - Flota de buses (placa, tipo, conductor, proveedor)
- `conductores` - Información de conductores
- `proveedores` - Empresas de transporte
- `emisiones` - Ubicaciones en tiempo real
- `favoritos/{uid}/lista` - Rutas favoritas por usuario
- `recordatorio/{uid}/lista` - Recordatorios por usuario
- `Suscripciones` - Suscripciones premium
- `pqrs` - Peticiones, quejas, reclamos y sugerencias

## Configuración

1. Clonar el repositorio
2. Ejecutar `flutter pub get` para instalar dependencias
3. Configurar un proyecto Firebase y agregar el archivo `google-services.json` en `android/app/`
4. Obtener una API key de Google Cloud y configurar en el proyecto
5. Ejecutar `flutter run` para iniciar la aplicación

## Estructura del Proyecto

```
lib/
├── main.dart              # Punto de entrada
├── wrapper.dart           # Control de autenticación
├── admin/                 # Panel de administración
│   ├── ruta_admin_page.dart
│   ├── routes_admin.dart
│   ├── car_admin.dart
│   ├── worker_admin.dart
│   └── live_emition.dart
├── home/                  # Páginas para usuarios
│   ├── home_page.dart
│   ├── body.dart
│   ├── profile.dart
│   ├── todas_las_rutas.dart
│   ├── rutas_favoritas.dart
│   └── recordatorios.dart
├── login/                 # Autenticación
│   └── login_page.dart
├── register/              # Registro
│   └── register_page.dart
└── utils/                 # Utilidades y servicios
    ├── google_directions_services.dart
    ├── polilynes_routes.dart
    └── proximidad_rutas.dart
```

## Licencia

Este proyecto fue desarrollado como proyecto final de bases de datos.