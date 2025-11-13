const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const { verificarToken, verificarAdmin, generarToken } = require('./auth');

const app = express();
const PORT = process.env.PORT || 5000;

// Configuración de PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'admin123',
  database: process.env.DB_NAME || 'banco_preguntas',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Middlewares
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Función helper para normalizar búsquedas (sin tildes)
const normalizarTexto = (texto) => {
  return texto
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
};

// Función para registrar en auditoría
const registrarAuditoria = async (usuarioId, accion, tabla, registroId, datosAnteriores, datosNuevos, ip) => {
  try {
    await pool.query(
      `INSERT INTO auditoria (usuario_id, accion, tabla_afectada, registro_id, datos_anteriores, datos_nuevos, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [usuarioId, accion, tabla, registroId, datosAnteriores, datosNuevos, ip]
    );
  } catch (error) {
    console.error('Error al registrar auditoría:', error);
  }
};

// ============================================
// CONFIG / FEATURE FLAGS
// ============================================

// Crear tabla de config si no existe, y helpers para get/set
const ensureConfigTable = async () => {
  try {
    await pool.query(
      `CREATE TABLE IF NOT EXISTS config (
         key TEXT PRIMARY KEY,
         value JSONB,
         created_at TIMESTAMP DEFAULT now()
       )`
    );
  } catch (error) {
    console.error('Error creando tabla config:', error);
  }
};

const getAllConfig = async () => {
  try {
    const res = await pool.query('SELECT key, value FROM config');
    const obj = {};
    res.rows.forEach(r => {
      try {
        obj[r.key] = r.value;
      } catch (e) {
        obj[r.key] = r.value;
      }
    });
    return obj;
  } catch (error) {
    console.error('Error al obtener config:', error);
    return {};
  }
};

const setConfigValue = async (key, value) => {
  try {
    await pool.query(
      `INSERT INTO config (key, value) VALUES ($1, $2)
       ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value`,
      [key, value]
    );
    return true;
  } catch (error) {
    console.error('Error al setear config:', error);
    return false;
  }
};

// Inicializar defaults si es necesario
const ensureDefaultConfigs = async () => {
  try {
    await ensureConfigTable();
    const current = await getAllConfig();
    if (!Object.prototype.hasOwnProperty.call(current, 'export_pdf')) {
      await setConfigValue('export_pdf', { enabled: true });
    }
    if (!Object.prototype.hasOwnProperty.call(current, 'export_excel')) {
      await setConfigValue('export_excel', { enabled: true });
    }
    if (!Object.prototype.hasOwnProperty.call(current, 'edit_enabled')) {
      await setConfigValue('edit_enabled', { enabled: true });
    }
    if (!Object.prototype.hasOwnProperty.call(current, 'delete_enabled')) {
      await setConfigValue('delete_enabled', { enabled: true });
    }
  } catch (error) {
    console.error('Error inicializando configs por defecto:', error);
  }
};


// ============================================
// ENDPOINTS DE AUTENTICACIÓN
// ============================================

// POST - Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Usuario y contraseña requeridos'
      });
    }

    // Buscar usuario
    const result = await pool.query(
      `SELECT id, username, password_hash, nombre_completo, rol, activo 
       FROM usuarios 
       WHERE username = $1`,
      [username]
    );

    if (result.rowCount === 0) {
      return res.status(401).json({
        success: false,
        message: 'Usuario o contraseña incorrectos'
      });
    }

    const usuario = result.rows[0];

    // Verificar si está activo
    if (!usuario.activo) {
      return res.status(401).json({
        success: false,
        message: 'Usuario desactivado'
      });
    }

    // Verificar contraseña con pgcrypto
    const passwordMatch = await pool.query(
      `SELECT (password_hash = crypt($1, password_hash)) as match FROM usuarios WHERE username = $2`,
      [password, username]
    );

    if (!passwordMatch.rows[0].match) {
      return res.status(401).json({
        success: false,
        message: 'Usuario o contraseña incorrectos'
      });
    }

    // Generar token
    const token = generarToken(usuario);

    // Registrar login en auditoría
    await registrarAuditoria(
      usuario.id,
      'LOGIN',
      'usuarios',
      usuario.id,
      null,
      null,
      req.ip
    );

    res.json({
      success: true,
      token,
      usuario: {
        id: usuario.id,
        username: usuario.username,
        nombre_completo: usuario.nombre_completo,
        rol: usuario.rol
      }
    });
  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({
      success: false,
      message: 'Error en el servidor',
      error: error.message
    });
  }
});

// POST - Logout
app.post('/api/auth/logout', verificarToken, async (req, res) => {
  try {
    await registrarAuditoria(
      req.usuario.id,
      'LOGOUT',
      'usuarios',
      req.usuario.id,
      null,
      null,
      req.ip
    );

    res.json({
      success: true,
      message: 'Sesión cerrada exitosamente'
    });
  } catch (error) {
    console.error('Error en logout:', error);
    res.status(500).json({
      success: false,
      message: 'Error al cerrar sesión'
    });
  }
});

// GET - Verificar token y obtener datos del usuario actual
app.get('/api/auth/me', verificarToken, (req, res) => {
  res.json({
    success: true,
    usuario: req.usuario
  });
});

// ============================================
// ENDPOINTS DE GESTIÓN DE USUARIOS (SOLO ADMIN)
// ============================================

// GET - Listar todos los usuarios
app.get('/api/usuarios', verificarToken, verificarAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, username, nombre_completo, rol, activo, created_at, updated_at
       FROM usuarios
       ORDER BY created_at DESC`
    );

    res.json({
      success: true,
      data: result.rows,
      total: result.rowCount
    });
  } catch (error) {
    console.error('Error al listar usuarios:', error);
    res.status(500).json({
      success: false,
      message: 'Error al listar usuarios'
    });
  }
});

// POST - Crear nuevo usuario
app.post('/api/usuarios', verificarToken, verificarAdmin, async (req, res) => {
  try {
    const { username, password, nombre_completo, rol } = req.body;

    if (!username || !password || !nombre_completo || !rol) {
      return res.status(400).json({
        success: false,
        message: 'Todos los campos son requeridos'
      });
    }

    if (!['admin', 'editor'].includes(rol)) {
      return res.status(400).json({
        success: false,
        message: 'Rol inválido. Debe ser admin o editor'
      });
    }

    // Crear usuario con contraseña encriptada
    const result = await pool.query(
      `INSERT INTO usuarios (username, password_hash, nombre_completo, rol)
       VALUES ($1, crypt($2, gen_salt('bf', 10)), $3, $4)
       RETURNING id, username, nombre_completo, rol, activo, created_at`,
      [username, password, nombre_completo, rol]
    );

    const nuevoUsuario = result.rows[0];

    // Registrar en auditoría
    await registrarAuditoria(
      req.usuario.id,
      'CREATE',
      'usuarios',
      nuevoUsuario.id,
      null,
      JSON.stringify(nuevoUsuario),
      req.ip
    );

    res.status(201).json({
      success: true,
      message: 'Usuario creado exitosamente',
      data: nuevoUsuario
    });
  } catch (error) {
    console.error('Error al crear usuario:', error);
    
    if (error.code === '23505') { // Unique violation
      return res.status(400).json({
        success: false,
        message: 'El nombre de usuario ya existe'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Error al crear usuario'
    });
  }
});

// PUT - Actualizar usuario
app.put('/api/usuarios/:id', verificarToken, verificarAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { username, password, nombre_completo, rol, activo } = req.body;

    // Obtener datos anteriores
    const anterior = await pool.query('SELECT * FROM usuarios WHERE id = $1', [id]);
    
    if (anterior.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Usuario no encontrado'
      });
    }

    let query;
    let params;

    if (password) {
      // Si se proporciona nueva contraseña
      query = `UPDATE usuarios 
               SET username = $1, password_hash = crypt($2, gen_salt('bf', 10)), 
                   nombre_completo = $3, rol = $4, activo = $5
               WHERE id = $6
               RETURNING id, username, nombre_completo, rol, activo, updated_at`;
      params = [username, password, nombre_completo, rol, activo, id];
    } else {
      // Sin cambiar contraseña
      query = `UPDATE usuarios 
               SET username = $1, nombre_completo = $2, rol = $3, activo = $4
               WHERE id = $5
               RETURNING id, username, nombre_completo, rol, activo, updated_at`;
      params = [username, nombre_completo, rol, activo, id];
    }

    const result = await pool.query(query, params);

    // Registrar en auditoría
    await registrarAuditoria(
      req.usuario.id,
      'UPDATE',
      'usuarios',
      id,
      JSON.stringify(anterior.rows[0]),
      JSON.stringify(result.rows[0]),
      req.ip
    );

    res.json({
      success: true,
      message: 'Usuario actualizado exitosamente',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error al actualizar usuario:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar usuario'
    });
  }
});

// DELETE - Eliminar usuario
app.delete('/api/usuarios/:id', verificarToken, verificarAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // No permitir eliminar al admin principal
    if (id === req.usuario.id) {
      return res.status(400).json({
        success: false,
        message: 'No puedes eliminar tu propio usuario'
      });
    }

    // Obtener datos antes de eliminar
    const anterior = await pool.query('SELECT * FROM usuarios WHERE id = $1', [id]);
    
    if (anterior.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Usuario no encontrado'
      });
    }

    await pool.query('DELETE FROM usuarios WHERE id = $1', [id]);

    // Registrar en auditoría
    await registrarAuditoria(
      req.usuario.id,
      'DELETE',
      'usuarios',
      id,
      JSON.stringify(anterior.rows[0]),
      null,
      req.ip
    );

    res.json({
      success: true,
      message: 'Usuario eliminado exitosamente'
    });
  } catch (error) {
    console.error('Error al eliminar usuario:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar usuario'
    });
  }
});

// GET - Historial de auditoría
app.get('/api/auditoria', verificarToken, verificarAdmin, async (req, res) => {
  try {
    const { limit = 100, offset = 0 } = req.query;

    const result = await pool.query(
      `SELECT a.*, u.username, u.nombre_completo
       FROM auditoria a
       LEFT JOIN usuarios u ON a.usuario_id = u.id
       ORDER BY a.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    res.json({
      success: true,
      data: result.rows,
      total: result.rowCount
    });
  } catch (error) {
    console.error('Error al obtener auditoría:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener historial'
    });
  }
});

// GET - Estadísticas de usuarios (solo admin)
app.get('/api/usuarios/estadisticas', verificarToken, verificarAdmin, async (req, res) => {
  try {
    // Estadísticas de preguntas por usuario
    const preguntasPorUsuario = await pool.query(
      `SELECT 
        u.id,
        u.username,
        u.nombre_completo,
        COUNT(CASE WHEN a.accion = 'CREATE' THEN 1 END) as creadas,
        COUNT(CASE WHEN a.accion = 'UPDATE' THEN 1 END) as modificadas,
        COUNT(CASE WHEN a.accion = 'DELETE' THEN 1 END) as eliminadas
       FROM usuarios u
       LEFT JOIN auditoria a ON u.id = a.usuario_id AND a.tabla_afectada = 'preguntas'
       GROUP BY u.id, u.username, u.nombre_completo
       ORDER BY creadas DESC`
    );

    // Total de preguntas en el sistema
    const totalPreguntas = await pool.query('SELECT COUNT(*) as total FROM preguntas');
    
    // Actividad reciente (últimos 30 días)
    const actividadReciente = await pool.query(
      `SELECT 
        u.username,
        u.nombre_completo,
        a.accion,
        COUNT(*) as cantidad,
        MAX(a.created_at) as ultima_actividad
       FROM auditoria a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.tabla_afectada = 'preguntas' 
         AND a.created_at >= NOW() - INTERVAL '30 days'
       GROUP BY u.username, u.nombre_completo, a.accion
       ORDER BY ultima_actividad DESC`
    );

    // Preguntas creadas por usuario (solo las que tienen creado_por)
    const distribucionPreguntas = await pool.query(
      `SELECT 
        u.username,
        u.nombre_completo,
        COUNT(p.id) as total_preguntas
       FROM usuarios u
       LEFT JOIN preguntas p ON u.id = p.creado_por
       GROUP BY u.id, u.username, u.nombre_completo
       ORDER BY total_preguntas DESC`
    );

    res.json({
      success: true,
      estadisticas: {
        porUsuario: preguntasPorUsuario.rows,
        totalPreguntas: parseInt(totalPreguntas.rows[0].total),
        actividadReciente: actividadReciente.rows,
        distribucion: distribucionPreguntas.rows
      }
    });
  } catch (error) {
    console.error('Error al obtener estadísticas:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener estadísticas'
    });
  }
});

// ============================================
// ENDPOINTS CRUD
// ============================================

// GET - Listar todas las preguntas
app.get('/api/preguntas', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM preguntas ORDER BY created_at DESC'
    );
    res.json({
      success: true,
      data: result.rows,
      total: result.rowCount
    });
  } catch (error) {
    console.error('Error al obtener preguntas:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener preguntas',
      error: error.message
    });
  }
});

// GET - Obtener una pregunta por ID
app.get('/api/preguntas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT * FROM preguntas WHERE id = $1',
      [id]
    );
    
    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pregunta no encontrada'
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error al obtener pregunta:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener pregunta',
      error: error.message
    });
  }
});

// POST - Crear nueva pregunta (requiere autenticación)
app.post('/api/preguntas', verificarToken, async (req, res) => {
  try {
    const { pregunta, respuesta_correcta } = req.body;
    
    if (!pregunta || !respuesta_correcta) {
      return res.status(400).json({
        success: false,
        message: 'Pregunta y respuesta son requeridas'
      });
    }
    
    // Validar si la pregunta ya existe (sin importar acentos y mayúsculas)
    const preguntaExistente = await pool.query(
      `SELECT id, pregunta FROM preguntas 
       WHERE unaccent(LOWER(TRIM(pregunta))) = unaccent(LOWER(TRIM($1)))`,
      [pregunta]
    );
    
    if (preguntaExistente.rowCount > 0) {
      return res.status(400).json({
        success: false,
        message: 'Esta pregunta ya existe en el sistema',
        pregunta_existente: preguntaExistente.rows[0].pregunta
      });
    }
    
    const result = await pool.query(
      'INSERT INTO preguntas (pregunta, respuesta_correcta, creado_por) VALUES ($1, $2, $3) RETURNING *',
      [pregunta, respuesta_correcta, req.usuario.id]
    );
    
    const nuevaPregunta = result.rows[0];
    
    // Registrar en auditoría
    await registrarAuditoria(
      req.usuario.id,
      'CREATE',
      'preguntas',
      nuevaPregunta.id,
      null,
      JSON.stringify({ pregunta, respuesta_correcta }),
      req.ip
    );
    
    res.status(201).json({
      success: true,
      message: 'Pregunta creada exitosamente',
      data: nuevaPregunta
    });
  } catch (error) {
    console.error('Error al crear pregunta:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear pregunta',
      error: error.message
    });
  }
});

// PUT - Actualizar pregunta (requiere autenticación)
app.put('/api/preguntas/:id', verificarToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { pregunta, respuesta_correcta } = req.body;
    
    if (!pregunta || !respuesta_correcta) {
      return res.status(400).json({
        success: false,
        message: 'Pregunta y respuesta son requeridas'
      });
    }
    
    // Obtener datos anteriores para auditoría
    const anterior = await pool.query('SELECT * FROM preguntas WHERE id = $1', [id]);
    
    if (anterior.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pregunta no encontrada'
      });
    }
    
    // Validar si la pregunta ya existe en otra entrada (sin importar acentos y mayúsculas)
    const preguntaExistente = await pool.query(
      `SELECT id, pregunta FROM preguntas 
       WHERE unaccent(LOWER(TRIM(pregunta))) = unaccent(LOWER(TRIM($1)))
       AND id != $2`,
      [pregunta, id]
    );
    
    if (preguntaExistente.rowCount > 0) {
      return res.status(400).json({
        success: false,
        message: 'Esta pregunta ya existe en el sistema',
        pregunta_existente: preguntaExistente.rows[0].pregunta
      });
    }
    
    const result = await pool.query(
      'UPDATE preguntas SET pregunta = $1, respuesta_correcta = $2, modificado_por = $3 WHERE id = $4 RETURNING *',
      [pregunta, respuesta_correcta, req.usuario.id, id]
    );
    
    // Registrar en auditoría
    await registrarAuditoria(
      req.usuario.id,
      'UPDATE',
      'preguntas',
      id,
      JSON.stringify(anterior.rows[0]),
      JSON.stringify({ pregunta, respuesta_correcta }),
      req.ip
    );
    
    res.json({
      success: true,
      message: 'Pregunta actualizada exitosamente',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error al actualizar pregunta:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar pregunta',
      error: error.message
    });
  }
});

// DELETE - Eliminar pregunta (requiere autenticación)
app.delete('/api/preguntas/:id', verificarToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Obtener datos antes de eliminar para auditoría
    const anterior = await pool.query('SELECT * FROM preguntas WHERE id = $1', [id]);
    
    if (anterior.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pregunta no encontrada'
      });
    }
    
    const result = await pool.query(
      'DELETE FROM preguntas WHERE id = $1 RETURNING *',
      [id]
    );
    
    // Registrar en auditoría
    await registrarAuditoria(
      req.usuario.id,
      'DELETE',
      'preguntas',
      id,
      JSON.stringify(anterior.rows[0]),
      null,
      req.ip
    );
    
    res.json({
      success: true,
      message: 'Pregunta eliminada exitosamente',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error al eliminar pregunta:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar pregunta',
      error: error.message
    });
  }
});

// ============================================
// BÚSQUEDA SIN TILDES
// ============================================

app.get('/api/preguntas/buscar/query', async (req, res) => {
  try {
    const { q, modo = 'cualquier-orden', campo = 'pregunta' } = req.query;
    
    if (!q || q.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Parámetro de búsqueda requerido'
      });
    }
    
    // Limpiar y validar el término de búsqueda
    const terminoBusqueda = q.trim();
    
    // Si el término es muy largo, limitarlo para evitar problemas
    if (terminoBusqueda.length > 500) {
      return res.status(400).json({
        success: false,
        message: 'El término de búsqueda es demasiado largo (máximo 500 caracteres)'
      });
    }
    
    // Función para escapar caracteres especiales en LIKE de PostgreSQL
    const escaparParaLike = (texto) => {
      return texto.replace(/[%_\\]/g, '\\$&');
    };
    
    let condiciones;
    let parametros;
    
    // Modo de búsqueda
    if (modo === 'renglon-seguido') {
      // Búsqueda exacta de la frase completa
      const terminoEscapado = escaparParaLike(terminoBusqueda);
      parametros = [`%${terminoEscapado}%`];
      
      if (campo === 'ambos') {
        condiciones = `(unaccent(LOWER(pregunta)) LIKE unaccent(LOWER($1)) OR unaccent(LOWER(respuesta_correcta)) LIKE unaccent(LOWER($1)))`;
      } else if (campo === 'pregunta') {
        condiciones = `unaccent(LOWER(pregunta)) LIKE unaccent(LOWER($1))`;
      } else if (campo === 'respuesta') {
        condiciones = `unaccent(LOWER(respuesta_correcta)) LIKE unaccent(LOWER($1))`;
      }
    } else {
      // Búsqueda por palabras individuales (cualquier orden)
      const palabras = terminoBusqueda.split(/\s+/).filter(p => p.length > 0);
      
      if (campo === 'ambos') {
        condiciones = palabras.map((_, index) => 
          `(unaccent(LOWER(pregunta)) LIKE unaccent(LOWER($${index + 1})) OR unaccent(LOWER(respuesta_correcta)) LIKE unaccent(LOWER($${index + 1})))`
        ).join(' AND ');
      } else if (campo === 'pregunta') {
        condiciones = palabras.map((_, index) => 
          `unaccent(LOWER(pregunta)) LIKE unaccent(LOWER($${index + 1}))`
        ).join(' AND ');
      } else if (campo === 'respuesta') {
        condiciones = palabras.map((_, index) => 
          `unaccent(LOWER(respuesta_correcta)) LIKE unaccent(LOWER($${index + 1}))`
        ).join(' AND ');
      }
      
      // Escapar cada palabra para LIKE
      parametros = palabras.map(p => `%${escaparParaLike(p)}%`);
    }
    
    // Búsqueda usando unaccent en PostgreSQL para ignorar tildes
    const result = await pool.query(
      `SELECT * FROM preguntas 
       WHERE ${condiciones}
       ORDER BY created_at DESC`,
      parametros
    );
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rowCount,
      query: terminoBusqueda,
      modo: modo,
      campo: campo
    });
  } catch (error) {
    console.error('Error en búsqueda:', error);
    
    // Retornar respuesta vacía en lugar de error 500
    res.status(200).json({
      success: true,
      data: [],
      total: 0,
      query: req.query.q || '',
      modo: req.query.modo || 'cualquier-orden',
      campo: req.query.campo || 'pregunta',
      error: 'No se pudo realizar la búsqueda. Intenta con términos más simples.'
    });
  }
});

// ============================================
// EXPORTACIÓN A PDF
// ============================================

// ============================================
// CONFIG ENDPOINTS
// ============================================

// GET - Obtener todas las configuraciones (útil para que el frontend se entere de los flags)
app.get('/api/config', async (req, res) => {
  try {
    const configs = await getAllConfig();
    return res.json({ success: true, configs });
  } catch (error) {
    console.error('Error GET /api/config:', error);
    return res.status(500).json({ success: false, message: 'Error al obtener configuración' });
  }
});

// PUT - Actualizar una configuración (solo admin)
app.put('/api/config/:key', verificarToken, verificarAdmin, async (req, res) => {
  const key = req.params.key;
  const value = req.body.value;
  if (typeof value === 'undefined') {
    return res.status(400).json({ success: false, message: 'Se requiere el campo value en el cuerpo' });
  }
  try {
    const ok = await setConfigValue(key, value);
    if (!ok) throw new Error('No se pudo guardar configuración');
    // Registrar en auditoría
    const usuarioId = req.usuario ? req.usuario.id : null;
    await registrarAuditoria(usuarioId, 'UPDATE_CONFIG', 'config', null, null, JSON.stringify({ [key]: value }), req.ip);
    return res.json({ success: true, message: 'Configuración actualizada', key, value });
  } catch (error) {
    console.error('Error PUT /api/config/:key', error);
    return res.status(500).json({ success: false, message: 'Error al guardar configuración' });
  }
});

app.get('/api/export/pdf', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM preguntas ORDER BY created_at DESC'
    );
    
    const doc = new PDFDocument({ margin: 50 });
    
    // Configurar headers de respuesta
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=banco-preguntas.pdf');
    
    doc.pipe(res);
    
    // Título
    doc.fontSize(20).font('Helvetica-Bold').text('Banco de Preguntas', { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).font('Helvetica').text(`Total: ${result.rowCount} preguntas`, { align: 'center' });
    doc.moveDown(2);
    
    // Preguntas
    result.rows.forEach((item, index) => {
      doc.fontSize(12).font('Helvetica-Bold').text(`${index + 1}. Pregunta:`, { continued: false });
      doc.fontSize(11).font('Helvetica').text(item.pregunta, { indent: 20 });
      doc.moveDown(0.5);
      
      doc.fontSize(12).font('Helvetica-Bold').text('Respuesta:', { continued: false });
      doc.fontSize(11).font('Helvetica').text(item.respuesta_correcta, { indent: 20 });
      doc.moveDown(1.5);
      
      // Nueva página cada 5 preguntas para mejor legibilidad
      if ((index + 1) % 5 === 0 && index < result.rowCount - 1) {
        doc.addPage();
      }
    });
    
    // Pie de página
    doc.fontSize(8).text(`Generado el: ${new Date().toLocaleString('es-ES')}`, {
      align: 'center'
    });
    
    doc.end();
  } catch (error) {
    console.error('Error al exportar PDF:', error);
    res.status(500).json({
      success: false,
      message: 'Error al exportar PDF',
      error: error.message
    });
  }
});

// ============================================
// EXPORTACIÓN A EXCEL
// ============================================

app.get('/api/export/excel', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM preguntas ORDER BY created_at DESC'
    );
    
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Banco de Preguntas');
    
    // Configurar columnas
    worksheet.columns = [
      { header: 'ID', key: 'id', width: 40 },
      { header: 'Pregunta', key: 'pregunta', width: 50 },
      { header: 'Respuesta Correcta', key: 'respuesta_correcta', width: 50 },
      { header: 'Fecha Creación', key: 'created_at', width: 20 },
      { header: 'Última Actualización', key: 'updated_at', width: 20 }
    ];
    
    // Estilo del header
    worksheet.getRow(1).font = { bold: true, size: 12 };
    worksheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF4472C4' }
    };
    worksheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    
    // Agregar datos
    result.rows.forEach(row => {
      worksheet.addRow({
        id: row.id,
        pregunta: row.pregunta,
        respuesta_correcta: row.respuesta_correcta,
        created_at: new Date(row.created_at).toLocaleString('es-ES'),
        updated_at: new Date(row.updated_at).toLocaleString('es-ES')
      });
    });
    
    // Ajustar altura de filas
    worksheet.eachRow((row, rowNumber) => {
      row.height = 20;
      if (rowNumber > 1) {
        row.alignment = { vertical: 'top', wrapText: true };
      }
    });
    
    // Configurar headers de respuesta
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename=banco-preguntas.xlsx'
    );
    
    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    console.error('Error al exportar Excel:', error);
    res.status(500).json({
      success: false,
      message: 'Error al exportar Excel',
      error: error.message
    });
  }
});

// ============================================
// BACKUP DE BASE DE DATOS (SQL)
// ============================================

app.get('/api/export/backup-sql', verificarToken, verificarAdmin, async (req, res) => {
  try {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').split('T')[0];
    
    // Iniciar el archivo SQL con comentarios y configuraciones
    let sqlContent = `-- =====================================================
-- BACKUP DE BASE DE DATOS - BANCO DE PREGUNTAS
-- Generado: ${new Date().toLocaleString('es-ES')}
-- Usuario: ${req.usuario.username}
-- =====================================================

-- Configurar UTF-8
SET client_encoding = 'UTF8';

-- Crear extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================
-- TABLA DE USUARIOS
-- =====================================================

CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('admin', 'editor')),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA DE AUDITORÍA
-- =====================================================

CREATE TABLE IF NOT EXISTS auditoria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id),
    accion VARCHAR(50) NOT NULL CHECK (accion IN ('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT')),
    tabla_afectada VARCHAR(50),
    registro_id UUID,
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    ip_address VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_auditoria_usuario ON auditoria(usuario_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_fecha ON auditoria(created_at);
CREATE INDEX IF NOT EXISTS idx_auditoria_accion ON auditoria(accion);

-- =====================================================
-- TABLA DE PREGUNTAS
-- =====================================================

CREATE TABLE IF NOT EXISTS preguntas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pregunta TEXT NOT NULL,
    respuesta_correcta TEXT NOT NULL,
    creado_por UUID REFERENCES usuarios(id),
    modificado_por UUID REFERENCES usuarios(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pregunta_search ON preguntas USING gin(to_tsvector('spanish', pregunta));

-- =====================================================
-- TABLA DE CONFIGURACIÓN
-- =====================================================

CREATE TABLE IF NOT EXISTS config (
    key TEXT PRIMARY KEY,
    value JSONB,
    created_at TIMESTAMP DEFAULT now()
);

-- =====================================================
-- FUNCIONES Y TRIGGERS
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_preguntas_updated_at
    BEFORE UPDATE ON preguntas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para asignar admin a datos huérfanos
CREATE OR REPLACE FUNCTION asignar_admin_si_huerfano()
RETURNS TRIGGER AS $$
DECLARE
    admin_id UUID;
BEGIN
    SELECT id INTO admin_id FROM usuarios WHERE rol = 'admin' LIMIT 1;
    
    IF NEW.creado_por IS NULL THEN
        NEW.creado_por := admin_id;
    END IF;
    
    IF NEW.modificado_por IS NULL THEN
        NEW.modificado_por := admin_id;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_asignar_admin
    BEFORE INSERT OR UPDATE ON preguntas
    FOR EACH ROW
    EXECUTE FUNCTION asignar_admin_si_huerfano();

-- =====================================================
-- DATOS DE USUARIOS
-- =====================================================

`;

    // Obtener usuarios
    const usuarios = await pool.query('SELECT * FROM usuarios ORDER BY created_at');
    
    sqlContent += `-- Insertar usuarios\n`;
    for (const user of usuarios.rows) {
      sqlContent += `INSERT INTO usuarios (id, username, password_hash, nombre_completo, rol, activo, created_at, updated_at) VALUES (\n`;
      sqlContent += `    '${user.id}',\n`;
      sqlContent += `    '${user.username.replace(/'/g, "''")}',\n`;
      sqlContent += `    '${user.password_hash}',\n`;
      sqlContent += `    '${user.nombre_completo.replace(/'/g, "''")}',\n`;
      sqlContent += `    '${user.rol}',\n`;
      sqlContent += `    ${user.activo},\n`;
      sqlContent += `    '${user.created_at.toISOString()}',\n`;
      sqlContent += `    '${user.updated_at.toISOString()}'\n`;
      sqlContent += `) ON CONFLICT (id) DO NOTHING;\n\n`;
    }

    // Obtener preguntas
    const preguntas = await pool.query('SELECT * FROM preguntas ORDER BY created_at');
    
    sqlContent += `-- =====================================================\n`;
    sqlContent += `-- DATOS DE PREGUNTAS (${preguntas.rows.length} registros)\n`;
    sqlContent += `-- =====================================================\n\n`;
    
    for (const pregunta of preguntas.rows) {
      const preguntaEscapada = pregunta.pregunta.replace(/'/g, "''");
      const respuestaEscapada = pregunta.respuesta_correcta.replace(/'/g, "''");
      
      sqlContent += `INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (\n`;
      sqlContent += `    '${pregunta.id}',\n`;
      sqlContent += `    '${preguntaEscapada}',\n`;
      sqlContent += `    '${respuestaEscapada}',\n`;
      sqlContent += `    ${pregunta.creado_por ? `'${pregunta.creado_por}'` : 'NULL'},\n`;
      sqlContent += `    ${pregunta.modificado_por ? `'${pregunta.modificado_por}'` : 'NULL'},\n`;
      sqlContent += `    '${pregunta.created_at.toISOString()}',\n`;
      sqlContent += `    '${pregunta.updated_at.toISOString()}'\n`;
      sqlContent += `) ON CONFLICT (id) DO NOTHING;\n\n`;
    }

    // Obtener configuración
    const configs = await pool.query('SELECT * FROM config ORDER BY key');
    
    if (configs.rows.length > 0) {
      sqlContent += `-- =====================================================\n`;
      sqlContent += `-- DATOS DE CONFIGURACIÓN\n`;
      sqlContent += `-- =====================================================\n\n`;
      
      for (const config of configs.rows) {
        const valueJson = JSON.stringify(config.value).replace(/'/g, "''");
        sqlContent += `INSERT INTO config (key, value, created_at) VALUES (\n`;
        sqlContent += `    '${config.key}',\n`;
        sqlContent += `    '${valueJson}'::jsonb,\n`;
        sqlContent += `    '${config.created_at.toISOString()}'\n`;
        sqlContent += `) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;\n\n`;
      }
    }

    // Agregar estadísticas al final
    sqlContent += `-- =====================================================\n`;
    sqlContent += `-- ESTADÍSTICAS DEL BACKUP\n`;
    sqlContent += `-- =====================================================\n`;
    sqlContent += `-- Total de usuarios: ${usuarios.rows.length}\n`;
    sqlContent += `-- Total de preguntas: ${preguntas.rows.length}\n`;
    sqlContent += `-- Total de configuraciones: ${configs.rows.length}\n`;
    sqlContent += `-- Fecha de backup: ${new Date().toISOString()}\n`;
    sqlContent += `-- =====================================================\n\n`;
    sqlContent += `SELECT COUNT(*) as total_usuarios FROM usuarios;\n`;
    sqlContent += `SELECT COUNT(*) as total_preguntas FROM preguntas;\n`;
    sqlContent += `SELECT COUNT(*) as total_configs FROM config;\n`;

    // Configurar headers de respuesta
    res.setHeader('Content-Type', 'application/sql; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename=backup-banco-preguntas-${timestamp}.sql`);
    
    // Enviar el contenido SQL
    res.send(sqlContent);
    
    // Registrar en auditoría
    await registrarAuditoria(
      req.usuario.id,
      'CREATE',
      'backup',
      null,
      null,
      { tipo: 'SQL', fecha: new Date().toISOString(), registros: preguntas.rows.length },
      req.ip
    );
    
  } catch (error) {
    console.error('Error al generar backup SQL:', error);
    res.status(500).json({
      success: false,
      message: 'Error al generar backup de la base de datos',
      error: error.message
    });
  }
});

// ============================================
// HEALTH CHECK
// ============================================

app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      success: true,
      message: 'API funcionando correctamente',
      database: 'Conectada',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error en la API',
      database: 'Desconectada',
      error: error.message
    });
  }
});

// Ruta raíz
app.get('/', (req, res) => {
  res.json({
    message: 'API de Banco de Preguntas',
    version: '1.0.0',
    endpoints: {
      preguntas: '/api/preguntas',
      buscar: '/api/preguntas/buscar/query?q=texto',
      exportPDF: '/api/export/pdf',
      exportExcel: '/api/export/excel',
      health: '/api/health'
    }
  });
});

// Manejo de rutas no encontradas
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Ruta no encontrada'
  });
});

// Iniciar servidor: primero asegurar configs por defecto, luego arrancar
ensureDefaultConfigs().then(() => {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
    console.log(`📊 Base de datos: ${process.env.DB_HOST}:${process.env.DB_PORT}`);
    console.log(`🔍 Health check: http://localhost:${PORT}/api/health`);
  });
}).catch(err => {
  console.error('Error inicializando configs por defecto:', err);
  // Arrancamos el servidor aunque la inicialización falle para no bloquear el servicio
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor corriendo en puerto ${PORT} (inicialización de configs fallida)`);
    console.log(`📊 Base de datos: ${process.env.DB_HOST}:${process.env.DB_PORT}`);
    console.log(`🔍 Health check: http://localhost:${PORT}/api/health`);
  });
});

// Manejo de errores no capturados
process.on('uncaughtException', (error) => {
  console.error('Error no capturado:', error);
});

process.on('unhandledRejection', (error) => {
  console.error('Promesa rechazada no manejada:', error);
});
