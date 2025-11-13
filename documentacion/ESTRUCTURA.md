# 📁 Estructura del Proyecto

```
examen_complexivo/
│
├── 📄 README.md                    # Documentación completa del sistema
├── 📄 INICIO_RAPIDO.md            # Guía rápida de inicio
├── 📄 docker-compose.yml          # Orquestación de contenedores
├── 📄 .env.example                # Ejemplo de variables de entorno
├── 📄 .gitignore                  # Archivos ignorados por Git
├── 📄 start.ps1                   # Script de inicio automático (PowerShell)
│
├── 📂 backend/                    # API REST (Node.js + Express)
│   ├── 📄 server.js               # Servidor principal con todos los endpoints
│   ├── 📄 package.json            # Dependencias del backend
│   ├── 📄 Dockerfile              # Imagen Docker del backend
│   └── 📄 .dockerignore           # Archivos ignorados en build
│
├── 📂 frontend/                   # Interfaz Web (React + Vite)
│   ├── 📂 src/
│   │   ├── 📄 main.jsx            # Punto de entrada de React
│   │   ├── 📄 App.jsx             # Componente principal con toda la lógica
│   │   ├── 📄 App.css             # Estilos del componente principal
│   │   └── 📄 index.css           # Estilos globales
│   ├── 📄 index.html              # HTML base
│   ├── 📄 package.json            # Dependencias del frontend
│   ├── 📄 vite.config.js          # Configuración de Vite
│   ├── 📄 Dockerfile              # Imagen Docker del frontend (multi-stage)
│   └── 📄 .dockerignore           # Archivos ignorados en build
│
└── 📂 database/                   # Base de Datos (PostgreSQL)
    └── 📄 init.sql                # Script de inicialización con datos de ejemplo
```

## 🎯 Archivos Principales

### Backend (`backend/server.js`)
- ✅ Endpoints CRUD completos
- ✅ Búsqueda sin tildes usando PostgreSQL `unaccent`
- ✅ Exportación a PDF con `pdfkit`
- ✅ Exportación a Excel con `exceljs`
- ✅ Health check endpoint
- ✅ Manejo de errores

### Frontend (`frontend/src/App.jsx`)
- ✅ Vista de Consulta (Banco de preguntas)
- ✅ Vista de Gestión (CRUD)
- ✅ Búsqueda en tiempo real
- ✅ Reconocimiento de voz (Web Speech API)
- ✅ Modal para crear/editar
- ✅ Exportación directa desde UI

### Base de Datos (`database/init.sql`)
- ✅ Extensión `uuid-ossp` para IDs únicos
- ✅ Extensión `unaccent` para búsqueda sin tildes
- ✅ Tabla `preguntas` con timestamps
- ✅ Índices para búsqueda rápida
- ✅ Triggers para actualización automática
- ✅ 5 preguntas de ejemplo

### Docker (`docker-compose.yml`)
- ✅ PostgreSQL 15 con volumen persistente
- ✅ Backend Node.js 18
- ✅ Frontend con Nginx
- ✅ Red interna para comunicación
- ✅ Health checks
- ✅ Restart policies

## 📊 Flujo de Datos

```
┌─────────────┐
│   Usuario   │
└──────┬──────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Frontend (React - Puerto 5050)    │
│  - Vista Consulta                   │
│  - Vista Gestión                    │
│  - Reconocimiento de voz            │
└────────────┬────────────────────────┘
             │ HTTP/REST
             ↓
┌─────────────────────────────────────┐
│  Backend (Express - Puerto 5051)   │
│  - CRUD de preguntas                │
│  - Búsqueda sin tildes              │
│  - Exportación PDF/Excel            │
└────────────┬────────────────────────┘
             │ SQL
             ↓
┌─────────────────────────────────────┐
│  Database (PostgreSQL - 5432)      │
│  - Tabla preguntas                  │
│  - Extensiones (uuid, unaccent)     │
│  - Volumen persistente              │
└─────────────────────────────────────┘
```

## 🔌 Puertos Expuestos

| Servicio   | Puerto Interno | Puerto Externo | URL                        |
|------------|----------------|----------------|----------------------------|
| Frontend   | 80             | 5050           | http://localhost:5050      |
| Backend    | 5000           | 5051           | http://localhost:5051/api  |
| PostgreSQL | 5432           | 5432           | localhost:5432             |

## 💾 Volúmenes Docker

| Volumen         | Propósito                    | Persistencia |
|-----------------|------------------------------|--------------|
| postgres_data   | Datos de PostgreSQL          | ✅ Sí        |
| backend/app     | Hot reload en desarrollo     | 🔄 Desarrollo |

## 🚀 Tecnologías y Librerías

### Backend
- `express` - Framework web
- `pg` - Cliente de PostgreSQL
- `cors` - Cross-Origin Resource Sharing
- `pdfkit` - Generación de PDFs
- `exceljs` - Generación de Excel
- `dotenv` - Variables de entorno

### Frontend
- `react` - Librería de UI
- `vite` - Build tool
- `axios` - Cliente HTTP
- `react-icons` - Iconos

### Database
- `PostgreSQL 15` - Base de datos relacional
- `uuid-ossp` - Generación de UUIDs
- `unaccent` - Búsqueda sin acentos

## 📝 Notas Importantes

1. **Primer inicio**: La primera vez puede tardar más porque descarga las imágenes Docker
2. **Persistencia**: Los datos se guardan en el volumen `postgres_data`
3. **Hot reload**: El backend se actualiza automáticamente en desarrollo
4. **Producción**: El frontend se construye con Nginx para mejor rendimiento
5. **UTF-8**: Todo el sistema soporta caracteres especiales y tildes
6. **Sin autenticación**: Sistema abierto (agregar auth si es necesario)

## ✨ Características Especiales

- 🔍 **Búsqueda inteligente**: Encuentra "función" escribiendo "funcion"
- 🎤 **Voz a texto**: Busca usando tu voz (Chrome/Edge)
- 📥 **Exportación**: PDF y Excel con un clic
- ⚡ **Tiempo real**: Búsqueda y filtrado instantáneo
- 🎨 **UI moderna**: Diseño responsive con gradientes
- 🐳 **Docker first**: Todo containerizado
- 💾 **Persistente**: Los datos sobreviven a reinicios
