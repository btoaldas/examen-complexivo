# Changelog

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Versionado Semántico](https://semver.org/lang/es/).

## [1.0.0] - 2025-11-13

### 🎉 Versión Inicial

#### ✨ Agregado
- Sistema completo de autenticación con JWT
  - Login con usuario y contraseña
  - Tokens de 8 horas de duración
  - Roles: Admin y Editor
- CRUD completo de preguntas
  - Crear, leer, actualizar y eliminar preguntas
  - Interfaz intuitiva con modales
- Sistema de búsqueda inteligente
  - Búsqueda sin tildes/acentos
  - Dos modos: coincidencia exacta o palabras sueltas
  - Búsqueda en pregunta, respuesta o ambos
  - Resaltado de resultados
  - Búsqueda por voz (Web Speech API)
- Sistema de ordenamiento
  - Por fecha de creación
  - Alfabético A-Z / Z-A para preguntas
  - Alfabético A-Z / Z-A para respuestas
- Gestión de usuarios (solo Admin)
  - Crear, editar y eliminar usuarios
  - Control de estado activo/inactivo
  - Asignación de roles
- Sistema de auditoría completo
  - Registro de todas las operaciones CRUD
  - Tracking de creador y modificador
  - Registro de login/logout
  - Almacenamiento de IP y timestamp
  - Datos anteriores y nuevos en formato JSON
- Estadísticas del sistema
  - Dashboard con tarjetas informativas
  - Gráficas de pastel interactivas (Recharts)
  - Contribuciones por usuario (creación, modificación, eliminación)
  - Tabla con porcentajes de aportación
  - Actividad de últimos 30 días
- Controles de administración
  - Toggle para habilitar/deshabilitar exportación PDF
  - Toggle para habilitar/deshabilitar exportación Excel
  - Toggle para habilitar/deshabilitar botón Editar
  - Toggle para habilitar/deshabilitar botón Borrar
  - Configuraciones persistentes en base de datos
- Sistema de exportación
  - Exportar preguntas a PDF con formato profesional
  - Exportar preguntas a Excel (XLSX) con estilos
  - Backup completo SQL con estructura, datos y triggers
- Asignación automática de datos huérfanos
  - Trigger para asignar admin a preguntas sin creador
  - Prevención de datos huérfanos en el futuro
- Dockerización completa
  - Backend en Node.js 18 Alpine
  - Frontend en React con Nginx
  - PostgreSQL 15 con extensiones (uuid-ossp, unaccent, pgcrypto)
  - Docker Compose para orquestación
  - Health checks configurados
- Base de datos PostgreSQL
  - 4 tablas: usuarios, preguntas, auditoria, config
  - 37 preguntas de ejemplo de examen complexivo
  - Índices para optimización
  - Funciones y triggers personalizados
- Interfaz responsive
  - Adaptada para desktop, tablet y móvil
  - Animaciones y transiciones suaves
  - Diseño moderno con gradientes
  - Iconografía con React Icons

#### 🔒 Seguridad
- Contraseñas hasheadas con bcrypt (10 rondas)
- Autenticación JWT obligatoria
- Middleware de verificación de roles
- Validación de permisos en endpoints críticos
- Protección contra SQL injection (consultas parametrizadas)
- CORS configurado

#### 📚 Documentación
- README completo con instrucciones de instalación
- Guía de uso del sistema
- Documentación de endpoints de API
- Comandos útiles de Docker
- Ejemplos de uso
- Guía de contribución
- Licencia MIT

#### 🐳 Infraestructura
- 3 contenedores Docker: backend, frontend, database
- Volumen persistente para PostgreSQL
- Red interna para comunicación entre servicios
- Variables de entorno configurables
- Scripts de inicialización de base de datos

### 🎯 Funcionalidades Destacadas

1. **Sistema de Auditoría Completo**: Cada acción queda registrada con usuario, fecha, IP y datos modificados
2. **Estadísticas Visuales**: Gráficas de pastel mostrando contribuciones por usuario
3. **Backup SQL Completo**: Exportación de toda la estructura y datos en un solo archivo SQL ejecutable
4. **Controles de Admin**: Sistema de toggles para habilitar/deshabilitar funcionalidades desde la UI
5. **Búsqueda Inteligente**: Sin preocuparse por tildes, con resaltado de resultados
6. **Responsive**: Funciona perfectamente en cualquier dispositivo

### 📊 Estadísticas del Proyecto
- **Líneas de código**: ~8,300+
- **Archivos**: 32
- **Preguntas de ejemplo**: 37
- **Endpoints API**: 25+
- **Tablas BD**: 4
- **Extensiones PostgreSQL**: 3

---

## Tipos de cambios

- `Agregado` para nuevas funcionalidades
- `Cambiado` para cambios en funcionalidad existente
- `Deprecado` para funcionalidades que se eliminarán pronto
- `Eliminado` para funcionalidades eliminadas
- `Corregido` para corrección de bugs
- `Seguridad` para vulnerabilidades corregidas
