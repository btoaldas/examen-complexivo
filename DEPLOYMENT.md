# 🚀 Guía de Despliegue

Esta guía te ayudará a desplegar el Sistema de Banco de Preguntas en diferentes entornos.

## 📋 Tabla de Contenidos
- [Desarrollo Local](#desarrollo-local)
- [Producción con Docker](#producción-con-docker)
- [Variables de Entorno](#variables-de-entorno)
- [Backup y Restauración](#backup-y-restauración)

## 💻 Desarrollo Local

### Prerequisitos
- Docker Desktop 4.0+
- Git 2.30+
- 4GB RAM mínimo
- Puertos disponibles: 5052, 5053, 5433

### Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/btoaldas/examen-complexivo.git
cd examen-complexivo
```

2. **Configurar variables de entorno (opcional)**
```bash
cp .env.example .env
# Edita .env con tus configuraciones personalizadas
```

3. **Iniciar los servicios**
```bash
docker-compose up -d --build
```

4. **Verificar que todo esté corriendo**
```bash
docker-compose ps
```

Deberías ver 3 contenedores en estado "Up" o "healthy":
- `examenes_backend`
- `examenes_frontend`
- `examenes_db`

5. **Acceder a la aplicación**
- Frontend: http://localhost:5053
- API: http://localhost:5052
- Database: localhost:5433

### Credenciales por Defecto
```
Usuario: admin
Contraseña: Admin2025!
```

⚠️ **IMPORTANTE**: Cambia la contraseña del admin después del primer login.

## 🌐 Producción con Docker

### Configuración de Seguridad

1. **Cambiar credenciales de base de datos**

Edita `docker-compose.yml`:
```yaml
database:
  environment:
    POSTGRES_USER: tu_usuario_seguro
    POSTGRES_PASSWORD: tu_contraseña_segura_aqui
    POSTGRES_DB: banco_preguntas
```

2. **Configurar variables de entorno del backend**

Edita `docker-compose.yml`:
```yaml
backend:
  environment:
    DB_HOST: database
    DB_PORT: 5432
    DB_USER: tu_usuario_seguro
    DB_PASSWORD: tu_contraseña_segura_aqui
    DB_NAME: banco_preguntas
    JWT_SECRET: tu_secreto_jwt_super_seguro_y_largo
    NODE_ENV: production
```

3. **Cambiar contraseña del admin**

Después de desplegar, conéctate a la base de datos:
```bash
docker exec -it examenes_db psql -U admin -d banco_preguntas
```

Ejecuta:
```sql
UPDATE usuarios 
SET password_hash = crypt('TuNuevaContraseñaSegura', gen_salt('bf', 10)) 
WHERE username = 'admin';
```

### Configuración de Puertos

Para producción, puedes querer usar puertos estándar:

```yaml
backend:
  ports:
    - "80:5000"  # Puerto 80 en lugar de 5052

frontend:
  ports:
    - "443:80"   # Puerto 443 con SSL (requiere configuración adicional)
```

### SSL/HTTPS (Recomendado para Producción)

Para habilitar HTTPS:

1. **Obtener certificados SSL** (Let's Encrypt recomendado)
2. **Modificar el Dockerfile del frontend** para incluir certificados
3. **Actualizar nginx.conf** para escuchar en puerto 443

Ejemplo de configuración nginx con SSL:
```nginx
server {
    listen 443 ssl;
    server_name tu-dominio.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    location / {
        root /usr/share/nginx/html;
        try_files $uri /index.html;
    }
}
```

## 🔐 Variables de Entorno

### Backend (.env o docker-compose.yml)

```bash
# Base de datos
DB_HOST=database
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=admin123
DB_NAME=banco_preguntas

# JWT
JWT_SECRET=tu_secreto_super_seguro_aqui
JWT_EXPIRES_IN=8h

# Servidor
PORT=5000
NODE_ENV=production

# CORS (opcional)
CORS_ORIGIN=https://tu-dominio.com
```

### Frontend (vite.config.js o .env)

```bash
# URL de la API
VITE_API_URL=https://api.tu-dominio.com/api
```

## 💾 Backup y Restauración

### Backup Manual

**Opción 1: Desde la aplicación (Recomendado)**
1. Login como admin
2. Ir a "Gestión de Usuarios"
3. Hacer clic en "Backup SQL"
4. El archivo se descarga automáticamente

**Opción 2: Desde línea de comandos**
```bash
# Backup completo
docker exec examenes_db pg_dump -U admin banco_preguntas > backup.sql

# Backup solo datos
docker exec examenes_db pg_dump -U admin --data-only banco_preguntas > backup_data.sql

# Backup solo estructura
docker exec examenes_db pg_dump -U admin --schema-only banco_preguntas > backup_schema.sql
```

### Backup Automático

Puedes configurar un cron job para backups automáticos:

```bash
# Editar crontab
crontab -e

# Agregar línea para backup diario a las 2 AM
0 2 * * * docker exec examenes_db pg_dump -U admin banco_preguntas > /backups/banco_$(date +\%Y\%m\%d).sql
```

### Restauración

**Desde archivo SQL:**
```bash
# Detener la aplicación
docker-compose down

# Iniciar solo la base de datos
docker-compose up -d database

# Esperar que esté lista
sleep 10

# Restaurar backup
docker exec -i examenes_db psql -U admin banco_preguntas < backup.sql

# Iniciar todos los servicios
docker-compose up -d
```

**Desde backup generado por la aplicación:**
```bash
docker exec -i examenes_db psql -U admin banco_preguntas < backup-banco-preguntas-2025-11-13.sql
```

## 📊 Monitoreo

### Ver logs en tiempo real

```bash
# Todos los servicios
docker-compose logs -f

# Solo un servicio
docker-compose logs -f backend
```

### Verificar salud de contenedores

```bash
docker-compose ps
```

### Verificar uso de recursos

```bash
docker stats
```

## 🔧 Mantenimiento

### Actualizar la aplicación

```bash
# Detener servicios
docker-compose down

# Obtener últimos cambios
git pull origin main

# Reconstruir y reiniciar
docker-compose up -d --build
```

### Limpiar datos antiguos

```bash
# Eliminar contenedores y volúmenes
docker-compose down -v

# Limpiar imágenes no usadas
docker system prune -a
```

## 🆘 Solución de Problemas

### Error: Puerto ocupado
```bash
# Windows
netstat -ano | findstr :5052

# Linux/Mac
lsof -i :5052

# Cambiar puerto en docker-compose.yml
```

### Error: Base de datos no responde
```bash
# Ver logs
docker-compose logs database

# Reiniciar base de datos
docker-compose restart database
```

### Error: Frontend no carga
```bash
# Reconstruir frontend
docker-compose up -d --build frontend

# Verificar logs
docker-compose logs frontend
```

## 📝 Checklist de Despliegue

Antes de desplegar a producción:

- [ ] Cambiar credenciales de base de datos
- [ ] Configurar JWT_SECRET seguro
- [ ] Cambiar contraseña del admin
- [ ] Configurar SSL/HTTPS
- [ ] Configurar backups automáticos
- [ ] Revisar y ajustar límites de recursos
- [ ] Configurar CORS apropiadamente
- [ ] Probar todas las funcionalidades
- [ ] Documentar configuración específica
- [ ] Configurar monitoreo y alertas

## 🔗 Recursos Adicionales

- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [React Deployment](https://create-react-app.dev/docs/deployment/)

---

¿Problemas? [Abre un issue](https://github.com/btoaldas/examen-complexivo/issues)
