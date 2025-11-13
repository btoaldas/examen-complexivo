# 📚 Sistema de Banco de Preguntas - Examen Complexivo

Sistema completo y funcional para crear, gestionar y consultar un banco de preguntas para exámenes. Desarrollado con tecnologías open source y listo para ejecutar con Docker.

## 🚀 Características

✅ **CRUD Completo** - Crear, leer, actualizar y eliminar preguntas  
✅ **Búsqueda Inteligente** - Búsqueda sin sensibilidad a tildes/acentos  
✅ **Reconocimiento de Voz** - Buscar usando tu voz  
✅ **Exportación** - Exportar banco a PDF y Excel  
✅ **Docker Ready** - Todo en contenedores, fácil de desplegar  
✅ **Persistencia** - Base de datos con volúmenes persistentes  
✅ **UTF-8** - Soporte completo para caracteres especiales  

## 🛠️ Stack Tecnológico

- **Frontend**: React 18 + Vite
- **Backend**: Node.js + Express
- **Base de Datos**: PostgreSQL 15
- **Containerización**: Docker + Docker Compose

## 📋 Requisitos Previos

- Docker Desktop instalado ([Descargar aquí](https://www.docker.com/products/docker-desktop))
- Git (opcional)

## ⚡ Inicio Rápido

### 1️⃣ Clonar o descargar el proyecto

```bash
cd c:\proyectos\examen_complexivo
```

### 2️⃣ Levantar el sistema completo

```powershell
docker-compose up -d
```

Este comando:
- Descarga las imágenes necesarias
- Construye los contenedores del frontend y backend
- Inicia PostgreSQL con datos de ejemplo
- Expone los servicios en los puertos configurados

### 3️⃣ Acceder al sistema

Una vez que los contenedores estén corriendo:

- **Frontend (Aplicación Web)**: http://localhost:5050
- **Backend (API REST)**: http://localhost:5051/api
- **Base de Datos PostgreSQL**: localhost:5432

**Credenciales de Base de Datos:**
- Usuario: `admin`
- Contraseña: `admin123`
- Base de datos: `banco_preguntas`

## 📖 Uso del Sistema

### Vista de Consulta (Banco de Preguntas)

1. Al abrir la aplicación, verás la pestaña "**Consultar Banco**"
2. Usa la barra de búsqueda para filtrar preguntas
3. **Búsqueda sin tildes**: Escribe "funcion" y encontrará "función"
4. **Búsqueda por voz**: Haz clic en el icono del micrófono 🎤 y habla
5. **Exportar**: Descarga todo el banco en PDF o Excel

### Vista de Gestión (CRUD)

1. Ve a la pestaña "**Gestionar Preguntas**"
2. **Crear**: Haz clic en "Nueva Pregunta" y completa el formulario
3. **Editar**: Haz clic en el botón de editar ✏️ en cualquier pregunta
4. **Eliminar**: Haz clic en el botón de eliminar 🗑️ (pedirá confirmación)

## 🔧 Comandos Docker Útiles

### Ver estado de los contenedores
```powershell
docker-compose ps
```

### Ver logs en tiempo real
```powershell
# Todos los servicios
docker-compose logs -f

# Solo backend
docker-compose logs -f backend

# Solo frontend
docker-compose logs -f frontend

# Solo base de datos
docker-compose logs -f database
```

### Detener el sistema
```powershell
docker-compose stop
```

### Reiniciar el sistema
```powershell
docker-compose restart
```

### Detener y eliminar contenedores (mantiene datos)
```powershell
docker-compose down
```

### Detener y eliminar TODO (incluyendo datos)
```powershell
docker-compose down -v
```

### Reconstruir contenedores después de cambios
```powershell
docker-compose up -d --build
```

## 🗄️ Gestión de Base de Datos

### Conectarse a PostgreSQL desde la terminal

```powershell
docker exec -it examenes_db psql -U admin -d banco_preguntas
```

### Consultas SQL útiles

```sql
-- Ver todas las preguntas
SELECT * FROM preguntas;

-- Contar total de preguntas
SELECT COUNT(*) FROM preguntas;

-- Buscar pregunta específica
SELECT * FROM preguntas WHERE pregunta ILIKE '%docker%';

-- Eliminar todas las preguntas (¡cuidado!)
DELETE FROM preguntas;
```

### Hacer backup de la base de datos

```powershell
docker exec examenes_db pg_dump -U admin banco_preguntas > backup.sql
```

### Restaurar backup

```powershell
docker exec -i examenes_db psql -U admin banco_preguntas < backup.sql
```

## 📡 Endpoints de la API

### Preguntas (CRUD)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/preguntas` | Listar todas las preguntas |
| GET | `/api/preguntas/:id` | Obtener pregunta por ID |
| POST | `/api/preguntas` | Crear nueva pregunta |
| PUT | `/api/preguntas/:id` | Actualizar pregunta |
| DELETE | `/api/preguntas/:id` | Eliminar pregunta |

### Búsqueda

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/preguntas/buscar/query?q=texto` | Buscar sin tildes |

### Exportación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/export/pdf` | Descargar banco en PDF |
| GET | `/api/export/excel` | Descargar banco en Excel |

### Health Check

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/health` | Verificar estado del servidor |

## 🔍 Ejemplos de Uso de la API

### Crear una pregunta

```bash
curl -X POST http://localhost:5051/api/preguntas \
  -H "Content-Type: application/json" \
  -d '{
    "pregunta": "¿Qué es JavaScript?",
    "respuesta_correcta": "JavaScript es un lenguaje de programación interpretado, de alto nivel y multi-paradigma."
  }'
```

### Buscar preguntas

```bash
curl "http://localhost:5051/api/preguntas/buscar/query?q=docker"
```

### Exportar a PDF

```bash
curl http://localhost:5051/api/export/pdf --output banco.pdf
```

## 🎤 Reconocimiento de Voz

El reconocimiento de voz funciona en navegadores modernos (Chrome, Edge):

1. Haz clic en el botón del micrófono 🎤
2. Permite el acceso al micrófono cuando el navegador lo solicite
3. Habla claramente en español
4. La búsqueda se ejecutará automáticamente

**Nota**: Safari y Firefox tienen soporte limitado.

## 🐛 Solución de Problemas

### El frontend no carga

```powershell
# Verificar que el backend esté corriendo
docker-compose logs backend

# Reiniciar el frontend
docker-compose restart frontend
```

### Error de conexión a base de datos

```powershell
# Verificar que PostgreSQL esté saludable
docker-compose ps database

# Ver logs de la base de datos
docker-compose logs database

# Reiniciar la base de datos
docker-compose restart database
```

### Puerto ocupado

Si algún puerto está ocupado (5050, 5051, 5432):

1. Edita `docker-compose.yml`
2. Cambia los puertos en la sección `ports`:
   ```yaml
   ports:
     - "NUEVO_PUERTO:PUERTO_INTERNO"
   ```
3. Reinicia: `docker-compose up -d`

### Reconstruir desde cero

```powershell
# Detener y eliminar todo
docker-compose down -v

# Eliminar imágenes
docker-compose rm -f
docker rmi examenes_backend examenes_frontend

# Reconstruir
docker-compose up -d --build
```

## 📁 Estructura del Proyecto

```
examen_complexivo/
├── backend/
│   ├── server.js           # API REST
│   ├── package.json        # Dependencias Node.js
│   ├── Dockerfile          # Imagen del backend
│   └── .dockerignore
├── frontend/
│   ├── src/
│   │   ├── App.jsx         # Componente principal
│   │   ├── App.css         # Estilos
│   │   ├── main.jsx        # Punto de entrada
│   │   └── index.css       # Estilos globales
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js
│   ├── Dockerfile          # Imagen del frontend
│   └── .dockerignore
├── database/
│   └── init.sql            # Script de inicialización
├── docker-compose.yml      # Orquestación
└── README.md              # Este archivo
```

## 🔒 Seguridad

⚠️ **IMPORTANTE**: Este sistema está configurado para desarrollo/demostración.

Para producción:
- Cambia las credenciales de la base de datos
- Implementa autenticación si es necesario
- Usa HTTPS
- Configura CORS apropiadamente
- Usa variables de entorno para secretos

## 📝 Datos de Ejemplo

El sistema viene con 5 preguntas de ejemplo sobre:
- Docker
- API REST
- PostgreSQL
- React
- Node.js

Puedes eliminarlas desde la vista de gestión o desde la base de datos.

## 🤝 Contribuciones

Este es un proyecto open source. Puedes:
- Agregar más funcionalidades
- Mejorar el diseño
- Optimizar el código
- Reportar bugs

## 📄 Licencia

MIT License - Uso libre para cualquier propósito.

## 🆘 Soporte

Para problemas o preguntas:
1. Revisa la sección de "Solución de Problemas"
2. Verifica los logs: `docker-compose logs`
3. Asegúrate de tener Docker actualizado

## 🎯 Próximas Mejoras Sugeridas

- [ ] Categorización de preguntas
- [ ] Sistema de etiquetas/tags
- [ ] Modo de examen (preguntas aleatorias)
- [ ] Estadísticas de uso
- [ ] Importar preguntas desde Excel/CSV
- [ ] Modo oscuro
- [ ] Múltiples idiomas

---

**¡Listo para usar! 🚀**

Levanta el sistema con `docker-compose up -d` y accede a http://localhost:5050
