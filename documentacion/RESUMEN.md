# 🎯 RESUMEN EJECUTIVO - Sistema de Banco de Preguntas

## ✨ ¿Qué es este sistema?

Un sistema web completo para crear, gestionar y consultar un banco de preguntas para exámenes complexivos. Todo containerizado con Docker para despliegue instantáneo.

---

## 🚀 Inicio Ultra-Rápido

### 1 comando para levantar todo:
```powershell
cd c:\proyectos\examen_complexivo
.\start.ps1
```

### O manualmente:
```powershell
docker-compose up -d
```

### Acceder:
```
http://localhost:5050
```

---

## 📦 ¿Qué incluye?

✅ **Frontend moderno** (React + Vite)  
✅ **Backend robusto** (Node.js + Express)  
✅ **Base de datos** (PostgreSQL 15)  
✅ **Todo en Docker** (docker-compose.yml)  
✅ **Datos de ejemplo** (5 preguntas iniciales)  
✅ **Documentación completa**  

---

## 🎯 Características Principales

### 🔍 Vista de Consulta
- Búsqueda en tiempo real
- Búsqueda sin tildes ("funcion" encuentra "función")
- 🎤 Reconocimiento de voz
- 📥 Exportar a PDF
- 📥 Exportar a Excel
- Visualización tipo tarjetas

### ⚙️ Vista de Gestión
- ➕ Crear preguntas
- ✏️ Editar preguntas
- 🗑️ Eliminar preguntas
- Modal amigable
- Lista completa

---

## 🛠️ Tecnologías

| Componente | Tecnología | Puerto |
|------------|------------|--------|
| Frontend | React 18 + Vite | 5050 |
| Backend | Node.js + Express | 5051 |
| Database | PostgreSQL 15 | 5432 |

**Todo open source y gratuito.**

---

## 📁 Archivos Importantes

| Archivo | Descripción |
|---------|-------------|
| `README.md` | Documentación completa |
| `INICIO_RAPIDO.md` | Guía rápida |
| `PASO_A_PASO.md` | Tutorial detallado |
| `ESTRUCTURA.md` | Arquitectura del sistema |
| `docker-compose.yml` | Configuración Docker |
| `start.ps1` | Script de inicio automático |

---

## 🎬 Cómo Usar

### Primera vez:
1. Abre PowerShell
2. `cd c:\proyectos\examen_complexivo`
3. `.\start.ps1`
4. Abre http://localhost:5050
5. ¡Listo!

### Uso diario:
- **Iniciar**: `docker-compose up -d`
- **Detener**: `docker-compose stop`
- **Ver logs**: `docker-compose logs -f`
- **Reiniciar**: `docker-compose restart`

---

## 💾 Persistencia de Datos

✅ **Los datos NO se pierden** al detener los contenedores  
✅ Volumen Docker: `postgres_data`  
✅ Backup manual: `docker exec examenes_db pg_dump...`  

---

## 🔧 Mantenimiento

### Ver estado:
```powershell
docker-compose ps
```

### Ver logs:
```powershell
docker-compose logs -f [servicio]
```

### Reconstruir:
```powershell
docker-compose up -d --build
```

### Reset completo:
```powershell
docker-compose down -v
docker-compose up -d --build
```

---

## 🌟 Casos de Uso

1. **Estudiante**: Crea tu banco de preguntas personal
2. **Profesor**: Gestiona preguntas para exámenes
3. **Institución**: Banco centralizado de preguntas
4. **Preparación**: Estudia con búsqueda rápida
5. **Exportación**: Genera PDFs para imprimir

---

## 🎯 Ventajas Clave

✅ **Instalación simple** - 1 comando  
✅ **Sin dependencias locales** - Todo en Docker  
✅ **Portable** - Corre en cualquier máquina con Docker  
✅ **Persistente** - Los datos no se pierden  
✅ **Rápido** - Búsqueda instantánea  
✅ **Moderno** - UI atractiva y responsive  
✅ **Accesible** - Búsqueda por voz  
✅ **Exportable** - PDF y Excel  

---

## 📊 Endpoints API

### CRUD
- `GET /api/preguntas` - Listar todas
- `POST /api/preguntas` - Crear
- `PUT /api/preguntas/:id` - Actualizar
- `DELETE /api/preguntas/:id` - Eliminar

### Búsqueda
- `GET /api/preguntas/buscar/query?q=texto`

### Exportación
- `GET /api/export/pdf` - Descargar PDF
- `GET /api/export/excel` - Descargar Excel

---

## 🐛 Solución Rápida de Problemas

| Problema | Solución |
|----------|----------|
| Puerto ocupado | Cambiar puerto en `docker-compose.yml` |
| Contenedor no inicia | `docker-compose logs [servicio]` |
| Error de BD | `docker-compose restart database` |
| Pantalla blanca | `docker-compose up -d --build` |
| Empezar de cero | `docker-compose down -v` luego `up -d` |

---

## 📚 Archivos de Ayuda

1. **¿Primera vez?** → Lee `PASO_A_PASO.md`
2. **¿Inicio rápido?** → Lee `INICIO_RAPIDO.md`
3. **¿Documentación completa?** → Lee `README.md`
4. **¿Entender arquitectura?** → Lee `ESTRUCTURA.md`

---

## 🔐 Credenciales (Desarrollo)

**Base de Datos:**
- Usuario: `admin`
- Password: `admin123`
- Database: `banco_preguntas`
- Puerto: `5432`

⚠️ **IMPORTANTE**: Cambia estas credenciales en producción

---

## 📈 Estadísticas del Sistema

- **Archivos creados**: 20+
- **Líneas de código**: ~2,500
- **Dependencias**: Mínimas y estables
- **Tiempo de inicio**: < 30 segundos
- **Tamaño total**: ~500MB (con imágenes Docker)

---

## 🎓 Próximos Pasos Sugeridos

1. ✅ Elimina las preguntas de ejemplo
2. ✅ Crea tu primer banco de preguntas
3. ✅ Prueba la búsqueda por voz
4. ✅ Exporta a PDF para practicar
5. ✅ Personaliza los estilos (opcional)
6. ✅ Agrega autenticación (si es necesario)

---

## 🤝 Contribuir

El sistema es completamente open source:
- Modifica lo que necesites
- Agrega nuevas funcionalidades
- Mejora el diseño
- Comparte con otros

---

## 📞 Soporte

### Auto-ayuda:
1. Lee la documentación
2. Revisa logs: `docker-compose logs`
3. Verifica Docker Desktop esté corriendo
4. Prueba reiniciar: `docker-compose restart`

### Comandos de diagnóstico:
```powershell
docker --version              # Verificar Docker
docker-compose --version      # Verificar Compose
docker-compose ps             # Estado de contenedores
docker-compose logs backend   # Logs del backend
docker stats                  # Uso de recursos
```

---

## 🎉 ¡Éxito!

Si puedes ver esto en el navegador: **http://localhost:5050**

**¡El sistema está funcionando perfectamente!** 🚀

---

## 📝 Checklist Final

- [ ] Docker Desktop instalado y corriendo
- [ ] PowerShell abierto
- [ ] Navegado a `c:\proyectos\examen_complexivo`
- [ ] Ejecutado `.\start.ps1` o `docker-compose up -d`
- [ ] Esperado 30 segundos
- [ ] Abierto http://localhost:5050
- [ ] Visto las 5 preguntas de ejemplo
- [ ] Probado crear una pregunta nueva
- [ ] Probado la búsqueda
- [ ] Probado exportar a PDF

**Si todos estos pasos funcionan: ✅ Sistema 100% operativo**

---

**Versión**: 1.0.0  
**Fecha**: Noviembre 2025  
**Licencia**: MIT  
**Autor**: Sistema Open Source  

🎯 **¡A conquistar ese examen complexivo!** 📚✨
