# 🎬 Guía Paso a Paso - Primera Ejecución

## 📋 Pre-requisitos

### ✅ Verificar Docker Desktop

1. Abre **Docker Desktop**
2. Asegúrate de que esté corriendo (icono verde en la barra de tareas)
3. Si no lo tienes instalado: https://www.docker.com/products/docker-desktop

---

## 🚀 Método 1: Inicio Automático (MÁS FÁCIL)

### Paso 1: Abrir PowerShell
```
1. Presiona Windows + X
2. Selecciona "Windows PowerShell" o "Terminal"
```

### Paso 2: Navegar al proyecto
```powershell
cd c:\proyectos\examen_complexivo
```

### Paso 3: Ejecutar script de inicio
```powershell
.\start.ps1
```

### Paso 4: Esperar
```
El script automáticamente:
✅ Verifica Docker
✅ Descarga imágenes (primera vez: 2-5 minutos)
✅ Construye contenedores
✅ Inicia servicios
✅ Te pregunta si quieres abrir el navegador
```

### Paso 5: ¡Usar el sistema!
```
Abre tu navegador en: http://localhost:5050
```

---

## 🛠️ Método 2: Inicio Manual

### Paso 1: Abrir PowerShell
```powershell
cd c:\proyectos\examen_complexivo
```

### Paso 2: Levantar contenedores
```powershell
docker-compose up -d
```

**Verás algo como:**
```
[+] Running 3/3
 ✔ Container examenes_db       Started
 ✔ Container examenes_backend  Started
 ✔ Container examenes_frontend Started
```

### Paso 3: Verificar estado
```powershell
docker-compose ps
```

**Debes ver 3 contenedores "Up":**
```
NAME                  STATUS
examenes_db           Up (healthy)
examenes_backend      Up
examenes_frontend     Up
```

### Paso 4: Ver logs (opcional)
```powershell
docker-compose logs -f
```
*Presiona Ctrl+C para salir*

### Paso 5: Abrir el navegador
```
http://localhost:5050
```

---

## 🎯 Primera Vez Usando el Sistema

### 🔍 Vista de Consulta (Default)

1. **Verás 5 preguntas de ejemplo**
   - Cada una en una tarjeta blanca
   - Con su pregunta y respuesta

2. **Probar la búsqueda:**
   - Escribe "docker" en la barra de búsqueda
   - ✨ Verás solo las preguntas relacionadas con Docker

3. **Probar búsqueda sin tildes:**
   - Escribe "funcion" (sin tilde)
   - ✨ Encontrará "función" (con tilde)

4. **Probar búsqueda por voz:**
   - Haz clic en el botón 🎤 (micrófono)
   - Permite acceso al micrófono
   - Di: "¿Qué es Docker?"
   - ✨ La búsqueda se ejecutará automáticamente

5. **Exportar a PDF:**
   - Haz clic en el botón "📥 PDF"
   - ✨ Se descargará un archivo PDF con todas las preguntas

6. **Exportar a Excel:**
   - Haz clic en el botón "📥 Excel"
   - ✨ Se descargará un archivo XLSX con todas las preguntas

### ⚙️ Vista de Gestión

1. **Cambiar a gestión:**
   - Haz clic en la pestaña "⚙️ Gestionar Preguntas"

2. **Crear una nueva pregunta:**
   - Haz clic en "➕ Nueva Pregunta"
   - Se abrirá un modal
   - Completa:
     ```
     Pregunta: ¿Qué es Git?
     Respuesta: Git es un sistema de control de versiones distribuido...
     ```
   - Haz clic en "Guardar"
   - ✨ La pregunta aparecerá en la lista

3. **Editar una pregunta:**
   - Haz clic en el botón ✏️ de cualquier pregunta
   - Modifica el texto
   - Haz clic en "Guardar"
   - ✨ Los cambios se guardarán inmediatamente

4. **Eliminar una pregunta:**
   - Haz clic en el botón 🗑️ de cualquier pregunta
   - Confirma la eliminación
   - ✨ La pregunta desaparecerá

---

## 🔧 Comandos Útiles

### Ver qué está corriendo
```powershell
docker-compose ps
```

### Ver logs en tiempo real
```powershell
docker-compose logs -f
```

### Ver logs de un servicio específico
```powershell
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f database
```

### Detener todo
```powershell
docker-compose stop
```

### Reiniciar todo
```powershell
docker-compose restart
```

### Detener y eliminar contenedores (mantiene datos)
```powershell
docker-compose down
```

### Eliminar TODO incluyendo datos
```powershell
docker-compose down -v
```

### Reconstruir después de cambios
```powershell
docker-compose up -d --build
```

---

## 🐛 Problemas Comunes

### ❌ "Puerto 5050 ya está en uso"

**Solución:**
1. Abre `docker-compose.yml`
2. Busca esta línea en `frontend`:
   ```yaml
   - "5050:80"
   ```
3. Cámbiala por:
   ```yaml
   - "3000:80"  # o cualquier puerto disponible
   ```
4. Reinicia: `docker-compose up -d`

### ❌ "Cannot connect to database"

**Solución:**
```powershell
# Reiniciar la base de datos
docker-compose restart database

# Esperar 10 segundos
Start-Sleep -Seconds 10

# Reiniciar el backend
docker-compose restart backend
```

### ❌ El frontend muestra pantalla blanca

**Solución:**
```powershell
# Ver logs del frontend
docker-compose logs frontend

# Ver logs del backend
docker-compose logs backend

# Reconstruir
docker-compose up -d --build
```

### ❌ Empezar desde cero

**Solución:**
```powershell
# Eliminar todo
docker-compose down -v
docker rmi examenes_backend examenes_frontend

# Levantar de nuevo
docker-compose up -d --build
```

---

## 📊 Verificar que Todo Funciona

### 1. Health Check del Backend
Abre en el navegador:
```
http://localhost:5051/api/health
```

Debes ver:
```json
{
  "success": true,
  "message": "API funcionando correctamente",
  "database": "Conectada"
}
```

### 2. Ver todas las preguntas (API)
```
http://localhost:5051/api/preguntas
```

### 3. Frontend funcionando
```
http://localhost:5050
```

Debes ver la interfaz con las preguntas de ejemplo.

---

## 🎓 Tips y Trucos

### 💡 Mantener Docker corriendo en segundo plano
```powershell
docker-compose up -d
# La opción -d (detached) lo ejecuta en background
```

### 💡 Ver solo los últimos 100 logs
```powershell
docker-compose logs --tail=100
```

### 💡 Seguir solo los logs del backend
```powershell
docker-compose logs -f backend
```

### 💡 Conectarse a la base de datos
```powershell
docker exec -it examenes_db psql -U admin -d banco_preguntas
```

Dentro de PostgreSQL:
```sql
\dt                    -- Ver tablas
SELECT * FROM preguntas;  -- Ver todas las preguntas
\q                     -- Salir
```

### 💡 Hacer backup de la base de datos
```powershell
docker exec examenes_db pg_dump -U admin banco_preguntas > backup.sql
```

### 💡 Restaurar backup
```powershell
Get-Content backup.sql | docker exec -i examenes_db psql -U admin banco_preguntas
```

---

## 🎉 ¡Todo Listo!

Si llegaste hasta aquí, tu sistema está funcionando perfectamente.

**Próximos pasos:**
1. ✅ Elimina las preguntas de ejemplo
2. ✅ Crea tus propias preguntas
3. ✅ Exporta tu banco a PDF/Excel
4. ✅ Usa búsqueda por voz
5. ✅ Disfruta del sistema

---

## 📞 ¿Necesitas Más Ayuda?

1. Lee el `README.md` completo
2. Revisa `ESTRUCTURA.md` para entender cómo funciona
3. Verifica los logs: `docker-compose logs`
4. Asegúrate de que Docker Desktop esté corriendo

**¡Feliz estudio! 📚**
