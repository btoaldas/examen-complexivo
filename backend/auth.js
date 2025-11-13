const jwt = require('jsonwebtoken');

// Secret para JWT (en producción debería estar en variables de entorno)
const JWT_SECRET = process.env.JWT_SECRET || 'tu_secreto_super_seguro_cambiar_en_produccion';

// Middleware para verificar autenticación
const verificarToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Token no proporcionado'
    });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.usuario = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token inválido o expirado'
    });
  }
};

// Middleware para verificar rol admin
const verificarAdmin = (req, res, next) => {
  if (req.usuario.rol !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Acceso denegado. Se requiere rol de administrador.'
    });
  }
  next();
};

// Generar token JWT
const generarToken = (usuario) => {
  return jwt.sign(
    {
      id: usuario.id,
      username: usuario.username,
      rol: usuario.rol,
      nombre_completo: usuario.nombre_completo
    },
    JWT_SECRET,
    { expiresIn: '8h' } // Token válido por 8 horas
  );
};

module.exports = {
  verificarToken,
  verificarAdmin,
  generarToken,
  JWT_SECRET
};
