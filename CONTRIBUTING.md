# Guía de Contribución

¡Gracias por tu interés en contribuir al Sistema de Banco de Preguntas!

## 🤝 Cómo Contribuir

### Reportar Bugs

1. Verifica que el bug no haya sido reportado anteriormente en los [Issues](https://github.com/btoaldas/examen-complexivo/issues)
2. Si no existe, crea un nuevo issue con:
   - Descripción clara del problema
   - Pasos para reproducirlo
   - Comportamiento esperado vs. comportamiento actual
   - Screenshots si es posible
   - Información del sistema (OS, versión de Docker, etc.)

### Sugerir Mejoras

1. Abre un issue con la etiqueta "enhancement"
2. Describe claramente la funcionalidad que propones
3. Explica por qué sería útil para el proyecto

### Pull Requests

1. **Fork** el repositorio
2. **Crea una rama** para tu feature:
   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```
3. **Haz tus cambios** siguiendo las guías de estilo
4. **Commit** con mensajes claros:
   ```bash
   git commit -m "Add: descripción clara del cambio"
   ```
5. **Push** a tu fork:
   ```bash
   git push origin feature/nueva-funcionalidad
   ```
6. Abre un **Pull Request** en el repositorio principal

## 📝 Guías de Estilo

### JavaScript/React
- Usa ES6+ features
- Preferir arrow functions
- Usa `const` y `let` en lugar de `var`
- Nombres descriptivos para variables y funciones
- Comentarios en español para código complejo

### CSS
- Usa variables CSS para colores
- Clases descriptivas con nomenclatura kebab-case
- Mantén la consistencia con los estilos existentes

### Commits
Formato: `Tipo: Descripción breve`

Tipos:
- `Add:` Nueva funcionalidad
- `Fix:` Corrección de bug
- `Update:` Actualización de funcionalidad existente
- `Refactor:` Refactorización de código
- `Docs:` Cambios en documentación
- `Style:` Cambios de formato (no afectan funcionalidad)
- `Test:` Agregar o modificar tests

## 🧪 Testing

Antes de enviar un PR:
1. Prueba localmente con Docker
2. Verifica que no hay errores en consola
3. Prueba en diferentes navegadores si es posible
4. Asegúrate que el build se completa sin errores

## 📄 Documentación

Si agregas nuevas funcionalidades, actualiza:
- README.md con instrucciones de uso
- Comentarios en el código
- Documentación de API si es relevante

## 💬 Comunicación

- Mantén el respeto en todas las interacciones
- Sé claro y conciso
- Responde a los comentarios en tu PR

## ✅ Checklist para PRs

Antes de enviar tu Pull Request:
- [ ] El código funciona localmente
- [ ] No hay errores en consola
- [ ] Seguí las guías de estilo
- [ ] Actualicé la documentación necesaria
- [ ] Los commits tienen mensajes claros
- [ ] Probé en diferentes escenarios

## 🙏 Gracias

Tu contribución hace que este proyecto sea mejor para todos. ¡Gracias por tu tiempo y esfuerzo!
