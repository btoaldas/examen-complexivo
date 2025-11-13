# Guía de Inicio Rápido - Sistema de Banco de Preguntas

## 🚀 Opción 1: Inicio Automático (Recomendado)

### Windows PowerShell:
```powershell
cd c:\proyectos\examen_complexivo
.\start.ps1
```

El script automáticamente:
- ✅ Verifica que Docker esté instalado
- ✅ Levanta todos los servicios
- ✅ Muestra el estado del sistema
- ✅ Te da la opción de abrir el navegador

---

## 🛠️ Opción 2: Inicio Manual

### 1. Levantar el sistema:
```powershell
cd c:\proyectos\examen_complexivo
docker-compose up -d
```

### 2. Verificar que todo esté corriendo:
```powershell
docker-compose ps
```

Deberías ver 3 contenedores corriendo:
- `examenes_db` (PostgreSQL)
- `examenes_backend` (API)
- `examenes_frontend` (React)

### 3. Abrir en el navegador:
```
http://localhost:5050
```

---

## 📊 Comandos Útiles

### Ver logs en tiempo real:
```powershell
docker-compose logs -f
```

### Detener el sistema:
```powershell
docker-compose stop
```

### Reiniciar el sistema:
```powershell
docker-compose restart
```

### Eliminar todo (incluye datos):
```powershell
docker-compose down -v
```

---

## 🎯 Uso del Sistema

### 1️⃣ Vista de Consulta (Búsqueda)
- Abre http://localhost:5050
- Verás la pestaña "Consultar Banco"
- Usa la barra de búsqueda para filtrar preguntas
- 🎤 Usa el botón de micrófono para buscar por voz
- 📥 Exporta a PDF o Excel

### 2️⃣ Vista de Gestión (CRUD)
- Haz clic en "Gestionar Preguntas"
- ➕ Crea nuevas preguntas
- ✏️ Edita preguntas existentes
- 🗑️ Elimina preguntas

---

## 🔧 Solución de Problemas

### ❌ Puerto ocupado
Edita `docker-compose.yml` y cambia los puertos:
```yaml
ports:
  - "NUEVO_PUERTO:PUERTO_INTERNO"
```

### ❌ Contenedor no inicia
```powershell
# Ver logs del contenedor problemático
docker-compose logs [nombre_servicio]

# Ejemplo:
docker-compose logs backend
```

### ❌ Reconstruir desde cero
```powershell
docker-compose down -v
docker-compose up -d --build
```

---

## 📞 Necesitas Ayuda?

1. Lee el archivo `README.md` completo
2. Revisa los logs: `docker-compose logs`
3. Verifica que Docker Desktop esté corriendo

---

**¡Listo para comenzar! 🎉**

Ejecuta `.\start.ps1` o `docker-compose up -d`
