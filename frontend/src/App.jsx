import { useState, useEffect, useCallback } from 'react'
import axios from 'axios'
import { FiPlus, FiEdit2, FiTrash2, FiSearch, FiMic, FiDownload, FiBook, FiSettings, FiX, FiLogOut, FiUser, FiBarChart2, FiActivity, FiTrendingUp } from 'react-icons/fi'
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts'
import Login from './Login'
import './App.css'

// Usar la URL actual del navegador para construir la URL de la API
const getApiUrl = () => {
  const host = window.location.hostname;
  const protocol = window.location.protocol;
  // Si es localhost, usar el puerto 5052, si no, usar el mismo host pero puerto 5052
  if (host === 'localhost' || host === '127.0.0.1') {
    return 'http://localhost:5052/api';
  }
  // Para producción, usar el mismo host pero puerto 5052
  return `${protocol}//${host}:5052/api`;
};

const API_URL = import.meta.env.VITE_API_URL || getApiUrl();

// Función para resaltar texto encontrado
const resaltarTexto = (texto, busqueda) => {
  // Validar que texto y búsqueda existan
  if (!texto || !busqueda || !busqueda.trim()) return texto
  
  // Dividir la búsqueda en palabras individuales
  const palabras = busqueda.toLowerCase().trim().split(/\s+/).filter(p => p.length > 0)
  
  if (palabras.length === 0) return texto
  
  // Crear un patrón regex que busque cualquiera de las palabras
  // Escapar caracteres especiales de regex
  const palabrasEscapadas = palabras.map(p => p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
  const patron = palabrasEscapadas.join('|')
  const regex = new RegExp(`(${patron})`, 'gi')
  
  // Dividir el texto en partes, manteniendo las coincidencias
  const partes = texto.split(regex)
  
  return partes.map((parte, index) => {
    // Validar que parte exista y no sea vacía
    if (!parte || parte.length === 0) return parte
    
    // Si la parte coincide con alguna palabra buscada, resaltarla
    if (palabras.some(palabra => parte.toLowerCase() === palabra.toLowerCase())) {
      return <mark key={index} className="highlight">{parte}</mark>
    }
    return parte
  })
}

function App() {
  const [usuario, setUsuario] = useState(null)
  const [preguntas, setPreguntas] = useState([])
  const [preguntasFiltradas, setPreguntasFiltradas] = useState([])
  const [loading, setLoading] = useState(false)
  const [vistaActual, setVistaActual] = useState('banco') // 'banco', 'gestion' o 'usuarios'
  const [busqueda, setBusqueda] = useState('')
  const [escuchandoVoz, setEscuchandoVoz] = useState(false)
  
  // Opciones de búsqueda
  const [modoBusqueda, setModoBusqueda] = useState('cualquier-orden') // 'cualquier-orden' o 'renglon-seguido'
  const [buscarEn, setBuscarEn] = useState('pregunta') // 'pregunta', 'respuesta', 'ambos'

  // Estados de ordenación
  const [ordenActual, setOrdenActual] = useState('ninguno') // 'ninguno', 'pregunta-asc', 'pregunta-desc', 'respuesta-asc', 'respuesta-desc'

  // Flags de export y acciones (se obtendrán del backend)
  const [exportPdfEnabled, setExportPdfEnabled] = useState(true)
  const [exportExcelEnabled, setExportExcelEnabled] = useState(true)
  const [editEnabled, setEditEnabled] = useState(true)
  const [deleteEnabled, setDeleteEnabled] = useState(true)
  
  // Estados para formulario de preguntas
  const [mostrarModal, setMostrarModal] = useState(false)
  const [modoEdicion, setModoEdicion] = useState(false)
  const [preguntaActual, setPreguntaActual] = useState({
    id: null,
    pregunta: '',
    respuesta_correcta: ''
  })

  // Estados para gestión de usuarios
  const [usuarios, setUsuarios] = useState([])
  const [estadisticas, setEstadisticas] = useState(null)
  const [mostrarModalUsuario, setMostrarModalUsuario] = useState(false)
  const [modoEdicionUsuario, setModoEdicionUsuario] = useState(false)
  const [usuarioActual, setUsuarioActual] = useState({
    id: null,
    username: '',
    password: '',
    nombre_completo: '',
    rol: 'editor',
    activo: true
  })

  // Verificar autenticación al cargar
  useEffect(() => {
    const token = localStorage.getItem('token')
    const usuarioGuardado = localStorage.getItem('usuario')
    
    if (token && usuarioGuardado) {
      setUsuario(JSON.parse(usuarioGuardado))
    }
  }, [])

  // Configurar axios con token
  const getAuthHeaders = useCallback(() => {
    const token = localStorage.getItem('token')
    return token ? { Authorization: `Bearer ${token}` } : {}
  }, [])

  // Manejar login
  const handleLogin = (usuarioData) => {
    setUsuario(usuarioData)
  }

  // Manejar logout
  const handleLogout = async () => {
    try {
      await axios.post(`${API_URL}/auth/logout`, {}, {
        headers: getAuthHeaders()
      })
    } catch (err) {
      console.error('Error al cerrar sesión:', err)
    } finally {
      localStorage.removeItem('token')
      localStorage.removeItem('usuario')
      setUsuario(null)
    }
  }

  // Cargar todas las preguntas
  const cargarPreguntas = useCallback(async () => {
    setLoading(true)
    try {
      const response = await axios.get(`${API_URL}/preguntas`)
      setPreguntas(response.data.data)
      setPreguntasFiltradas(response.data.data)
    } catch (error) {
      console.error('Error al cargar preguntas:', error)
      alert('Error al cargar preguntas')
    } finally {
      setLoading(false)
    }
  }, [])

  // Buscar preguntas (sin tildes)
  const buscarPreguntas = useCallback(async (termino) => {
    if (!termino.trim()) {
      setPreguntasFiltradas(preguntas)
      return
    }
    
    try {
      // Limpiar el término de búsqueda de caracteres problemáticos
      const terminoLimpio = termino.trim()
      
      // Construir parámetros según las opciones seleccionadas
      const params = new URLSearchParams({
        q: terminoLimpio,
        modo: modoBusqueda,
        campo: buscarEn
      })
      
      const response = await axios.get(`${API_URL}/preguntas/buscar/query?${params.toString()}`)
      
      if (response.data && response.data.data) {
        setPreguntasFiltradas(response.data.data)
      } else {
        setPreguntasFiltradas([])
      }
    } catch (error) {
      console.error('Error en búsqueda:', error)
      setPreguntasFiltradas([])
    }
  }, [preguntas, modoBusqueda, buscarEn])

  // Cargar preguntas al inicio (solo cuando hay usuario)
  useEffect(() => {
    if (usuario) {
      cargarPreguntas()
    }
    // También cargar la configuración de flags de export y acciones si el usuario está presente
    const fetchConfig = async () => {
      try {
        const resp = await axios.get(`${API_URL}/config`, { headers: getAuthHeaders() })
        const configs = resp.data?.configs || {}
        if (configs.export_pdf && typeof configs.export_pdf.enabled !== 'undefined') {
          setExportPdfEnabled(!!configs.export_pdf.enabled)
        }
        if (configs.export_excel && typeof configs.export_excel.enabled !== 'undefined') {
          setExportExcelEnabled(!!configs.export_excel.enabled)
        }
        if (configs.edit_enabled && typeof configs.edit_enabled.enabled !== 'undefined') {
          setEditEnabled(!!configs.edit_enabled.enabled)
        }
        if (configs.delete_enabled && typeof configs.delete_enabled.enabled !== 'undefined') {
          setDeleteEnabled(!!configs.delete_enabled.enabled)
        }
      } catch (err) {
        // Silenciar errores: el endpoint puede requerir auth o no estar disponible durante pruebas
        console.debug('No se pudo obtener configuración de export:', err?.message || err)
      }
    }

    if (usuario) fetchConfig()
  }, [usuario, cargarPreguntas])

  // Filtrar preguntas cuando cambia la búsqueda o las opciones
  useEffect(() => {
    if (busqueda.trim() === '') {
      setPreguntasFiltradas(preguntas)
    } else {
      buscarPreguntas(busqueda)
    }
  }, [busqueda, preguntas, buscarPreguntas])

  // Crear o actualizar pregunta
  const guardarPregunta = async (e) => {
    e.preventDefault()
    
    if (!preguntaActual.pregunta.trim() || !preguntaActual.respuesta_correcta.trim()) {
      alert('Por favor completa todos los campos')
      return
    }
    
    setLoading(true)
    try {
      if (modoEdicion) {
        await axios.put(`${API_URL}/preguntas/${preguntaActual.id}`, {
          pregunta: preguntaActual.pregunta,
          respuesta_correcta: preguntaActual.respuesta_correcta
        }, {
          headers: getAuthHeaders()
        })
        alert('✅ Pregunta actualizada exitosamente')
      } else {
        await axios.post(`${API_URL}/preguntas`, {
          pregunta: preguntaActual.pregunta,
          respuesta_correcta: preguntaActual.respuesta_correcta
        }, {
          headers: getAuthHeaders()
        })
        alert('✅ Pregunta creada exitosamente')
      }
      
      cerrarModal()
      cargarPreguntas()
    } catch (error) {
      console.error('Error completo:', error)
      
      // Extraer el mensaje de error del backend
      const errorData = error.response?.data
      const errorStatus = error.response?.status
      
      console.log('Estado HTTP:', errorStatus)
      console.log('Datos del error:', errorData)
      
      // Manejar errores según el código HTTP
      if (errorStatus === 400 && errorData) {
        // Error de validación (400 Bad Request)
        if (errorData.message && errorData.message.toLowerCase().includes('ya existe')) {
          // Pregunta duplicada
          const preguntaDuplicada = errorData.pregunta_existente || preguntaActual.pregunta
          alert(`⚠️ PREGUNTA DUPLICADA\n\n"${preguntaDuplicada}"\n\nEsta pregunta ya existe en el sistema. Por favor verifica el contenido.`)
        } else {
          // Otro error de validación
          alert(`❌ ${errorData.message || 'Error de validación'}`)
        }
      } else if (errorStatus === 401) {
        // Token expirado o inválido
        alert('❌ Sesión expirada. Por favor inicia sesión nuevamente.')
        cerrarSesion()
      } else {
        // Error genérico
        const mensaje = errorData?.message || error.message || 'Error al guardar pregunta'
        alert(`❌ Error: ${mensaje}`)
      }
    } finally {
      setLoading(false)
    }
  }

  // Eliminar pregunta
  const eliminarPregunta = async (id) => {
    if (!confirm('¿Estás seguro de eliminar esta pregunta?')) return
    
    setLoading(true)
    try {
      await axios.delete(`${API_URL}/preguntas/${id}`, {
        headers: getAuthHeaders()
      })
      alert('Pregunta eliminada exitosamente')
      cargarPreguntas()
    } catch (error) {
      console.error('Error al eliminar pregunta:', error)
      const mensaje = error.response?.data?.error || 'Error al eliminar pregunta'
      alert(mensaje)
    } finally {
      setLoading(false)
    }
  }

  // Abrir modal para crear
  const abrirModalCrear = () => {
    setPreguntaActual({ id: null, pregunta: '', respuesta_correcta: '' })
    setModoEdicion(false)
    setMostrarModal(true)
  }

  // Abrir modal para editar
  const abrirModalEditar = (pregunta) => {
    setPreguntaActual(pregunta)
    setModoEdicion(true)
    setMostrarModal(true)
  }

  // Cerrar modal
  const cerrarModal = () => {
    setMostrarModal(false)
    setPreguntaActual({ id: null, pregunta: '', respuesta_correcta: '' })
    setModoEdicion(false)
  }

  // ========== FUNCIONES DE GESTIÓN DE USUARIOS ==========
  
  // Cargar usuarios
  const cargarUsuarios = useCallback(async () => {
    if (usuario?.rol !== 'admin') return
    
    setLoading(true)
    try {
      const response = await axios.get(`${API_URL}/usuarios`, {
        headers: getAuthHeaders()
      })
      setUsuarios(response.data.data || [])
    } catch (error) {
      console.error('Error al cargar usuarios:', error)
      const mensaje = error.response?.data?.message || error.message || 'Error al cargar usuarios'
      alert(`Error al cargar usuarios: ${mensaje}`)
    } finally {
      setLoading(false)
    }
  }, [usuario, getAuthHeaders])

  // Cargar estadísticas
  const cargarEstadisticas = useCallback(async () => {
    if (usuario?.rol !== 'admin') return
    
    try {
      const response = await axios.get(`${API_URL}/usuarios/estadisticas`, {
        headers: getAuthHeaders()
      })
      setEstadisticas(response.data.estadisticas)
    } catch (error) {
      console.error('Error al cargar estadísticas:', error)
    }
  }, [usuario, getAuthHeaders])

  // Guardar usuario
  const guardarUsuario = async (e) => {
    e.preventDefault()
    
    if (!usuarioActual.username.trim() || !usuarioActual.nombre_completo.trim()) {
      alert('Por favor completa los campos obligatorios')
      return
    }

    if (!modoEdicionUsuario && !usuarioActual.password.trim()) {
      alert('La contraseña es obligatoria para nuevos usuarios')
      return
    }

    setLoading(true)
    try {
      const datos = {
        username: usuarioActual.username,
        nombre_completo: usuarioActual.nombre_completo,
        rol: usuarioActual.rol,
        activo: usuarioActual.activo
      }

      if (usuarioActual.password.trim()) {
        datos.password = usuarioActual.password
      }

      if (modoEdicionUsuario) {
        await axios.put(`${API_URL}/usuarios/${usuarioActual.id}`, datos, {
          headers: getAuthHeaders()
        })
        alert('Usuario actualizado exitosamente')
      } else {
        await axios.post(`${API_URL}/usuarios`, datos, {
          headers: getAuthHeaders()
        })
        alert('Usuario creado exitosamente')
      }
      
      cerrarModalUsuario()
      cargarUsuarios()
    } catch (error) {
      console.error('Error al guardar usuario:', error)
      const mensaje = error.response?.data?.message || error.message || 'Error al guardar usuario'
      alert(mensaje)
    } finally {
      setLoading(false)
    }
  }

  // Eliminar usuario
  const eliminarUsuario = async (id) => {
    if (!confirm('¿Estás seguro de eliminar este usuario?')) return
    
    setLoading(true)
    try {
      await axios.delete(`${API_URL}/usuarios/${id}`, {
        headers: getAuthHeaders()
      })
      alert('Usuario eliminado exitosamente')
      cargarUsuarios()
    } catch (error) {
      console.error('Error al eliminar usuario:', error)
      const mensaje = error.response?.data?.message || error.message || 'Error al eliminar usuario'
      alert(mensaje)
    } finally {
      setLoading(false)
    }
  }

  // Abrir modal para crear usuario
  const abrirModalCrearUsuario = () => {
    setUsuarioActual({
      id: null,
      username: '',
      password: '',
      nombre_completo: '',
      rol: 'editor',
      activo: true
    })
    setModoEdicionUsuario(false)
    setMostrarModalUsuario(true)
  }

  // Abrir modal para editar usuario
  const abrirModalEditarUsuario = (usr) => {
    setUsuarioActual({
      ...usr,
      password: '' // No mostramos la contraseña
    })
    setModoEdicionUsuario(true)
    setMostrarModalUsuario(true)
  }

  // Cerrar modal de usuario
  const cerrarModalUsuario = () => {
    setMostrarModalUsuario(false)
    setUsuarioActual({
      id: null,
      username: '',
      password: '',
      nombre_completo: '',
      rol: 'editor',
      activo: true
    })
    setModoEdicionUsuario(false)
  }

  // Cargar usuarios y estadísticas cuando se accede a la vista
  useEffect(() => {
    if (vistaActual === 'usuarios' && usuario?.rol === 'admin') {
      cargarUsuarios()
      cargarEstadisticas()
    }
  }, [vistaActual, usuario, cargarUsuarios, cargarEstadisticas])

  // Reconocimiento de voz
  const iniciarReconocimientoVoz = () => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      alert('Tu navegador no soporta reconocimiento de voz. Usa Chrome o Edge.')
      return
    }

    // Limpiar búsqueda anterior antes de iniciar nueva grabación
    setBusqueda('')

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    const recognition = new SpeechRecognition()
    
    // Español latinoamericano (mejor reconocimiento para América Latina)
    recognition.lang = 'es-419'
    recognition.continuous = false
    recognition.interimResults = false

    recognition.onstart = () => {
      setEscuchandoVoz(true)
    }

    recognition.onresult = (event) => {
      let transcript = event.results[0][0].transcript
      // Eliminar punto final, signos de interrogación y admiración
      transcript = transcript
        .replace(/\.$/g, '')           // Eliminar punto final
        .replace(/[¿?¡!]/g, '')        // Eliminar ¿ ? ¡ !
        .trim()
      setBusqueda(transcript)
      setEscuchandoVoz(false)
    }

    recognition.onerror = (event) => {
      console.error('Error en reconocimiento de voz:', event.error)
      setEscuchandoVoz(false)
      alert('Error en reconocimiento de voz')
    }

    recognition.onend = () => {
      setEscuchandoVoz(false)
    }

    recognition.start()
  }

  // Limpiar búsqueda
  const limpiarBusqueda = () => {
    setBusqueda('')
  }

  // Seleccionar todo el texto al hacer clic en el input
  const seleccionarTexto = (e) => {
    e.target.select()
  }

  // Exportar a PDF
  const exportarPDF = () => {
    if (!exportPdfEnabled) {
      alert('La exportación a PDF está deshabilitada por el administrador.')
      return
    }
    window.open(`${API_URL}/export/pdf`, '_blank')
  }

  // Exportar a Excel
  const exportarExcel = () => {
    if (!exportExcelEnabled) {
      alert('La exportación a Excel está deshabilitada por el administrador.')
      return
    }
    window.open(`${API_URL}/export/excel`, '_blank')
  }

  // Toggle de flags (solo admin) desde frontend - llaman al backend
  const toggleExportPdf = async () => {
    try {
      const nuevo = !exportPdfEnabled
      await axios.put(`${API_URL}/config/export_pdf`, { value: { enabled: nuevo } }, { headers: getAuthHeaders() })
      setExportPdfEnabled(nuevo)
      alert(`Exportación a PDF ${nuevo ? 'habilitada' : 'deshabilitada'}`)
    } catch (err) {
      console.error('Error toggling export_pdf:', err)
      alert('Error al cambiar la configuración de exportación PDF')
    }
  }

  const toggleExportExcel = async () => {
    try {
      const nuevo = !exportExcelEnabled
      await axios.put(`${API_URL}/config/export_excel`, { value: { enabled: nuevo } }, { headers: getAuthHeaders() })
      setExportExcelEnabled(nuevo)
      alert(`Exportación a Excel ${nuevo ? 'habilitada' : 'deshabilitada'}`)
    } catch (err) {
      console.error('Error toggling export_excel:', err)
      alert('Error al cambiar la configuración de exportación Excel')
    }
  }

  const toggleEdit = async () => {
    try {
      const nuevo = !editEnabled
      await axios.put(`${API_URL}/config/edit_enabled`, { value: { enabled: nuevo } }, { headers: getAuthHeaders() })
      setEditEnabled(nuevo)
      alert(`Botón Editar ${nuevo ? 'habilitado' : 'deshabilitado'}`)
    } catch (err) {
      console.error('Error toggling edit_enabled:', err)
      alert('Error al cambiar la configuración del botón Editar')
    }
  }

  const toggleDelete = async () => {
    try {
      const nuevo = !deleteEnabled
      await axios.put(`${API_URL}/config/delete_enabled`, { value: { enabled: nuevo } }, { headers: getAuthHeaders() })
      setDeleteEnabled(nuevo)
      alert(`Botón Borrar ${nuevo ? 'habilitado' : 'deshabilitado'}`)
    } catch (err) {
      console.error('Error toggling delete_enabled:', err)
      alert('Error al cambiar la configuración del botón Borrar')
    }
  }

  // Función para descargar backup SQL
  const descargarBackupSQL = async () => {
    try {
      const token = localStorage.getItem('token')
      if (!token) {
        alert('No estás autenticado')
        return
      }

      // Mostrar mensaje de preparación
      const confirmar = window.confirm(
        '¿Deseas generar un respaldo completo de la base de datos?\n\n' +
        'Este archivo SQL incluirá:\n' +
        '✓ Estructura de todas las tablas\n' +
        '✓ Todos los usuarios\n' +
        '✓ Todas las preguntas y respuestas\n' +
        '✓ Configuraciones del sistema\n' +
        '✓ Funciones y triggers\n\n' +
        'El proceso puede tardar unos segundos...'
      )

      if (!confirmar) return

      // Hacer la petición con blob response
      const response = await axios.get(`${API_URL}/export/backup-sql`, {
        headers: {
          Authorization: `Bearer ${token}`
        },
        responseType: 'blob' // Importante para descargar archivos
      })

      // Crear un blob y descargarlo
      const blob = new Blob([response.data], { type: 'application/sql' })
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      
      // Generar nombre de archivo con fecha
      const fecha = new Date().toISOString().split('T')[0]
      link.download = `backup-banco-preguntas-${fecha}.sql`
      
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.URL.revokeObjectURL(url)

      alert('✅ Backup SQL descargado exitosamente')
    } catch (err) {
      console.error('Error al descargar backup SQL:', err)
      alert('❌ Error al generar el backup de la base de datos: ' + (err.response?.data?.message || err.message))
    }
  }

  // Función para ordenar preguntas
  const ordenarPreguntas = (tipo) => {
    let preguntasOrdenadas = [...preguntasFiltradas]
    
    switch(tipo) {
      case 'pregunta-asc':
        preguntasOrdenadas.sort((a, b) => a.pregunta.localeCompare(b.pregunta, 'es', { sensitivity: 'base' }))
        setOrdenActual('pregunta-asc')
        break
      case 'pregunta-desc':
        preguntasOrdenadas.sort((a, b) => b.pregunta.localeCompare(a.pregunta, 'es', { sensitivity: 'base' }))
        setOrdenActual('pregunta-desc')
        break
      case 'respuesta-asc':
        preguntasOrdenadas.sort((a, b) => a.respuesta_correcta.localeCompare(b.respuesta_correcta, 'es', { sensitivity: 'base' }))
        setOrdenActual('respuesta-asc')
        break
      case 'respuesta-desc':
        preguntasOrdenadas.sort((a, b) => b.respuesta_correcta.localeCompare(a.respuesta_correcta, 'es', { sensitivity: 'base' }))
        setOrdenActual('respuesta-desc')
        break
      default:
        // Restaurar orden original (por fecha de creación)
        preguntasOrdenadas = [...preguntas]
        setOrdenActual('ninguno')
    }
    
    setPreguntasFiltradas(preguntasOrdenadas)
  }

  // Si no hay usuario logueado, mostrar login
  if (!usuario) {
    return <Login onLogin={handleLogin} />
  }

  return (
    <div className="app">
      {/* Header */}
      <header className="header">
        <div className="header-content">
          <div className="logo">
            <FiBook size={32} />
            <h1>Banco de Preguntas</h1>
          </div>
          <div className="stats">
            <div className="user-info">
              <FiUser size={18} />
              <span className="user-name">{usuario.nombre_completo}</span>
              <span className="user-role">{usuario.rol === 'admin' ? '👑 Admin' : '✏️ Editor'}</span>
            </div>
            <span className="stat-badge">
              Total: {preguntas.length} preguntas
            </span>
            {busqueda && (
              <span className="stat-badge highlight">
                Filtradas: {preguntasFiltradas.length}
              </span>
            )}
            <button onClick={handleLogout} className="logout-btn" title="Cerrar sesión">
              <FiLogOut size={18} />
            </button>
          </div>
        </div>
      </header>

      {/* Navegación */}
      <nav className="nav">
        <button
          className={`nav-btn ${vistaActual === 'banco' ? 'active' : ''}`}
          onClick={() => setVistaActual('banco')}
        >
          <FiBook /> Banco de Preguntas
        </button>
        {usuario.rol === 'admin' && (
          <button
            className={`nav-btn ${vistaActual === 'usuarios' ? 'active' : ''}`}
            onClick={() => setVistaActual('usuarios')}
          >
            <FiUser /> Gestionar Usuarios
          </button>
        )}
        {vistaActual === 'banco' && (
          <button onClick={abrirModalCrear} className="btn-crear nav-btn-crear">
            <FiPlus /> Nueva Pregunta
          </button>
        )}
      </nav>

      {/* Contenido Principal */}
      <main className="main-content">
        {/* Vista Única Unificada - Banco de Preguntas */}
        {vistaActual === 'banco' && (
          <div className="vista-banco fade-in">
            {/* Header con búsqueda, filtros y acciones */}
            <div className="search-section">
              <div className="header-actions">
                <h2><FiBook /> Banco de Preguntas</h2>
                <button onClick={abrirModalCrear} className="btn-crear">
                  <FiPlus /> Nueva Pregunta
                </button>
              </div>

              <div className="search-container">
                <FiSearch className="search-icon" />
                <input
                  type="text"
                  placeholder="Buscar preguntas... (con o sin tildes)"
                  value={busqueda}
                  onChange={(e) => setBusqueda(e.target.value)}
                  onClick={seleccionarTexto}
                  className="search-input"
                />
                {busqueda && (
                  <button
                    onClick={limpiarBusqueda}
                    className="clear-btn"
                    title="Limpiar búsqueda"
                  >
                    <FiX size={20} />
                  </button>
                )}
                <button
                  onClick={iniciarReconocimientoVoz}
                  className={`voice-btn ${escuchandoVoz ? 'listening' : ''}`}
                  title="Buscar por voz"
                >
                  <FiMic size={20} />
                  {escuchandoVoz && <span className="pulse-dot"></span>}
                </button>
              </div>
              
              {/* Opciones de búsqueda y exportación en una fila */}
              <div className="controls-row">
                <div className="search-options">
                  <div className="option-group">
                    <label className="option-label">Modo:</label>
                    <select 
                      value={modoBusqueda} 
                      onChange={(e) => setModoBusqueda(e.target.value)}
                      className="option-select"
                    >
                      <option value="cualquier-orden">Cualquier orden</option>
                      <option value="renglon-seguido">Renglón seguido</option>
                    </select>
                  </div>
                  
                  <div className="option-group">
                    <label className="option-label">Buscar en:</label>
                    <select 
                      value={buscarEn} 
                      onChange={(e) => setBuscarEn(e.target.value)}
                      className="option-select"
                    >
                      <option value="pregunta">Solo pregunta</option>
                      <option value="respuesta">Solo respuesta</option>
                      <option value="ambos">Pregunta y respuesta</option>
                    </select>
                  </div>
                </div>
                
                <div className="sort-options">
                  <div className="option-group">
                    <label className="option-label">Ordenar:</label>
                    <select 
                      value={ordenActual} 
                      onChange={(e) => ordenarPreguntas(e.target.value)}
                      className="option-select"
                    >
                      <option value="ninguno">Por fecha</option>
                      <option value="pregunta-asc">Pregunta A→Z</option>
                      <option value="pregunta-desc">Pregunta Z→A</option>
                      <option value="respuesta-asc">Respuesta A→Z</option>
                      <option value="respuesta-desc">Respuesta Z→A</option>
                    </select>
                  </div>
                </div>
                
                <div className="export-buttons">
                  <button
                    onClick={exportarPDF}
                    className={`export-btn pdf ${!exportPdfEnabled ? 'disabled' : ''}`}
                    title={exportPdfEnabled ? 'Exportar PDF' : 'Exportación a PDF deshabilitada'}
                    disabled={!exportPdfEnabled}
                  >
                    <FiDownload /> PDF
                  </button>
                  <button
                    onClick={exportarExcel}
                    className={`export-btn excel ${!exportExcelEnabled ? 'disabled' : ''}`}
                    title={exportExcelEnabled ? 'Exportar Excel' : 'Exportación a Excel deshabilitada'}
                    disabled={!exportExcelEnabled}
                  >
                    <FiDownload /> Excel
                  </button>
                </div>
              </div>
            </div>

            {loading ? (
              <div className="loading">Cargando...</div>
            ) : (
              <div className="preguntas-grid">
                {preguntasFiltradas.length === 0 ? (
                  <div className="empty-state">
                    <FiSearch size={64} />
                    <h3>No se encontraron preguntas</h3>
                    <p>Intenta con otros términos de búsqueda</p>
                  </div>
                ) : (
                  preguntasFiltradas.map((item, index) => (
                    <div key={item.id} className="pregunta-card">
                      <div className="pregunta-numero">#{index + 1}</div>
                      <div className="pregunta-content">
                        <div className="pregunta-texto">
                          <strong>P:</strong> {resaltarTexto(item.pregunta, busqueda)}
                        </div>
                        <div className="respuesta-texto">
                          <strong>R:</strong> {item.respuesta_correcta}
                        </div>
                      </div>
                      <div className="pregunta-card-actions">
                        <button
                          onClick={() => editEnabled && abrirModalEditar(item)}
                          className={`btn-action edit ${!editEnabled ? 'disabled' : ''}`}
                          title={editEnabled ? "Editar pregunta" : "Editar deshabilitado por el administrador"}
                          disabled={!editEnabled}
                        >
                          <FiEdit2 />
                        </button>
                        <button
                          onClick={() => deleteEnabled && eliminarPregunta(item.id)}
                          className={`btn-action delete ${!deleteEnabled ? 'disabled' : ''}`}
                          title={deleteEnabled ? "Eliminar pregunta" : "Borrar deshabilitado por el administrador"}
                          disabled={!deleteEnabled}
                        >
                          <FiTrash2 />
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            )}
          </div>
        )}

        {/* Vista Gestión de Usuarios (Solo Admin) */}
        {vistaActual === 'usuarios' && usuario.rol === 'admin' && (
          <div className="vista-gestion fade-in">
            <div className="gestion-header">
              <h2>👥 Gestión de Usuarios</h2>
              <button onClick={abrirModalCrearUsuario} className="btn-crear">
                <FiPlus /> Crear Usuario
              </button>
              <div className="config-toggles">
                <button
                  className={`toggle-btn pdf-toggle ${exportPdfEnabled ? 'on' : 'off'}`}
                  onClick={toggleExportPdf}
                  title={exportPdfEnabled ? 'Deshabilitar export PDF' : 'Habilitar export PDF'}
                >
                  PDF: {exportPdfEnabled ? 'ON' : 'OFF'}
                </button>
                <button
                  className={`toggle-btn excel-toggle ${exportExcelEnabled ? 'on' : 'off'}`}
                  onClick={toggleExportExcel}
                  title={exportExcelEnabled ? 'Deshabilitar export Excel' : 'Habilitar export Excel'}
                >
                  Excel: {exportExcelEnabled ? 'ON' : 'OFF'}
                </button>
                <button
                  className={`toggle-btn edit-toggle ${editEnabled ? 'on' : 'off'}`}
                  onClick={toggleEdit}
                  title={editEnabled ? 'Deshabilitar botón Editar' : 'Habilitar botón Editar'}
                >
                  Editar: {editEnabled ? 'ON' : 'OFF'}
                </button>
                <button
                  className={`toggle-btn delete-toggle ${deleteEnabled ? 'on' : 'off'}`}
                  onClick={toggleDelete}
                  title={deleteEnabled ? 'Deshabilitar botón Borrar' : 'Habilitar botón Borrar'}
                >
                  Borrar: {deleteEnabled ? 'ON' : 'OFF'}
                </button>
              </div>
              <button 
                onClick={descargarBackupSQL}
                className="btn-backup-sql"
                title="Descargar respaldo completo de la base de datos en formato SQL"
              >
                <FiDownload /> Backup SQL
              </button>
            </div>

            {/* Sección de Estadísticas */}
            {estadisticas && (
              <div className="estadisticas-container">
                <h3 className="estadisticas-titulo"><FiBarChart2 /> Estadísticas del Sistema</h3>
                
                <div className="estadisticas-grid">
                  {/* Tarjeta: Total de Preguntas */}
                  <div className="estadistica-card">
                    <div className="estadistica-icon total">
                      <FiBook size={32} />
                    </div>
                    <div className="estadistica-info">
                      <div className="estadistica-valor">{estadisticas.totalPreguntas}</div>
                      <div className="estadistica-label">Total Preguntas</div>
                    </div>
                  </div>

                  {/* Tarjeta: Usuario Más Activo */}
                  {estadisticas.porUsuario.length > 0 && (
                    <div className="estadistica-card">
                      <div className="estadistica-icon activo">
                        <FiTrendingUp size={32} />
                      </div>
                      <div className="estadistica-info">
                        <div className="estadistica-valor">{estadisticas.porUsuario[0].nombre_completo}</div>
                        <div className="estadistica-label">Usuario Más Activo</div>
                        <div className="estadistica-detalle">
                          {estadisticas.porUsuario[0].creadas} creadas, {estadisticas.porUsuario[0].modificadas} modificadas
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Tarjeta: Actividad Reciente */}
                  {estadisticas.actividadReciente.length > 0 && (
                    <div className="estadistica-card">
                      <div className="estadistica-icon reciente">
                        <FiActivity size={32} />
                      </div>
                      <div className="estadistica-info">
                        <div className="estadistica-valor">{estadisticas.actividadReciente.reduce((sum, a) => sum + parseInt(a.cantidad), 0)}</div>
                        <div className="estadistica-label">Acciones (30 días)</div>
                      </div>
                    </div>
                  )}
                </div>

                {/* Tabla de Contribuciones por Usuario */}
                <div className="contribuciones-tabla">
                  <h4>📊 Contribuciones por Usuario</h4>
                  <table className="tabla-contribuciones">
                    <thead>
                      <tr>
                        <th>Usuario</th>
                        <th>Creadas</th>
                        <th>Modificadas</th>
                        <th>Eliminadas</th>
                        <th>Total Acciones</th>
                        <th>% Aportación</th>
                      </tr>
                    </thead>
                    <tbody>
                      {estadisticas.porUsuario.map((usr) => {
                        const totalAcciones = parseInt(usr.creadas) + parseInt(usr.modificadas) + parseInt(usr.eliminadas);
                        const totalSistema = estadisticas.porUsuario.reduce((sum, u) => 
                          sum + parseInt(u.creadas) + parseInt(u.modificadas) + parseInt(u.eliminadas), 0
                        );
                        const porcentaje = totalSistema > 0 ? ((totalAcciones / totalSistema) * 100).toFixed(1) : 0;
                        
                        return (
                          <tr key={usr.id}>
                            <td><strong>{usr.nombre_completo}</strong></td>
                            <td className="numero-creadas">{usr.creadas}</td>
                            <td className="numero-modificadas">{usr.modificadas}</td>
                            <td className="numero-eliminadas">{usr.eliminadas}</td>
                            <td className="numero-total"><strong>{totalAcciones}</strong></td>
                            <td>
                              <div className="porcentaje-container">
                                <div className="porcentaje-barra">
                                  <div 
                                    className="porcentaje-fill" 
                                    style={{width: `${porcentaje}%`}}
                                  ></div>
                                </div>
                                <span className="porcentaje-texto">{porcentaje}%</span>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>

                {/* Gráficos de Pastel */}
                <div className="graficos-pastel-container">
                  <h4>📈 Distribución de Contribuciones</h4>
                  
                  <div className="graficos-grid">
                    {/* Gráfico de Creación */}
                    <div className="grafico-card">
                      <h5>Preguntas Creadas</h5>
                      <ResponsiveContainer width="100%" height={300}>
                        <PieChart>
                          <Pie
                            data={estadisticas.porUsuario.map(usr => ({
                              name: usr.nombre_completo,
                              value: parseInt(usr.creadas),
                              porcentaje: ((parseInt(usr.creadas) / estadisticas.porUsuario.reduce((sum, u) => sum + parseInt(u.creadas), 0)) * 100).toFixed(1)
                            })).filter(d => d.value > 0)}
                            cx="50%"
                            cy="50%"
                            labelLine={false}
                            label={({name, porcentaje}) => `${name}: ${porcentaje}%`}
                            outerRadius={80}
                            fill="#8884d8"
                            dataKey="value"
                          >
                            {estadisticas.porUsuario.map((entry, index) => (
                              <Cell key={`cell-${index}`} fill={['#22c55e', '#3b82f6', '#a855f7', '#f59e0b', '#ef4444', '#06b6d4'][index % 6]} />
                            ))}
                          </Pie>
                          <Tooltip formatter={(value, name, props) => [`${value} (${props.payload.porcentaje}%)`, props.payload.name]} />
                          <Legend />
                        </PieChart>
                      </ResponsiveContainer>
                    </div>

                    {/* Gráfico de Modificación */}
                    <div className="grafico-card">
                      <h5>Preguntas Modificadas</h5>
                      <ResponsiveContainer width="100%" height={300}>
                        <PieChart>
                          <Pie
                            data={estadisticas.porUsuario.map(usr => ({
                              name: usr.nombre_completo,
                              value: parseInt(usr.modificadas),
                              porcentaje: ((parseInt(usr.modificadas) / estadisticas.porUsuario.reduce((sum, u) => sum + parseInt(u.modificadas), 0)) * 100).toFixed(1)
                            })).filter(d => d.value > 0)}
                            cx="50%"
                            cy="50%"
                            labelLine={false}
                            label={({name, porcentaje}) => `${name}: ${porcentaje}%`}
                            outerRadius={80}
                            fill="#8884d8"
                            dataKey="value"
                          >
                            {estadisticas.porUsuario.map((entry, index) => (
                              <Cell key={`cell-${index}`} fill={['#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#06b6d4'][index % 6]} />
                            ))}
                          </Pie>
                          <Tooltip formatter={(value, name, props) => [`${value} (${props.payload.porcentaje}%)`, props.payload.name]} />
                          <Legend />
                        </PieChart>
                      </ResponsiveContainer>
                    </div>

                    {/* Gráfico de Eliminación */}
                    <div className="grafico-card">
                      <h5>Preguntas Eliminadas</h5>
                      <ResponsiveContainer width="100%" height={300}>
                        <PieChart>
                          <Pie
                            data={estadisticas.porUsuario.map(usr => ({
                              name: usr.nombre_completo,
                              value: parseInt(usr.eliminadas),
                              porcentaje: ((parseInt(usr.eliminadas) / estadisticas.porUsuario.reduce((sum, u) => sum + parseInt(u.eliminadas), 0)) * 100).toFixed(1)
                            })).filter(d => d.value > 0)}
                            cx="50%"
                            cy="50%"
                            labelLine={false}
                            label={({name, porcentaje}) => `${name}: ${porcentaje}%`}
                            outerRadius={80}
                            fill="#8884d8"
                            dataKey="value"
                          >
                            {estadisticas.porUsuario.map((entry, index) => (
                              <Cell key={`cell-${index}`} fill={['#ef4444', '#f97316', '#f59e0b', '#eab308', '#84cc16', '#22c55e'][index % 6]} />
                            ))}
                          </Pie>
                          <Tooltip formatter={(value, name, props) => [`${value} (${props.payload.porcentaje}%)`, props.payload.name]} />
                          <Legend />
                        </PieChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {loading ? (
              <div className="loading">Cargando usuarios...</div>
            ) : (
              <div className="tabla-container">
                <table className="tabla-preguntas">
                  <thead>
                    <tr>
                      <th>Usuario</th>
                      <th>Nombre Completo</th>
                      <th>Rol</th>
                      <th>Estado</th>
                      <th>Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {usuarios.map((usr) => (
                      <tr key={usr.id}>
                        <td><strong>{usr.username}</strong></td>
                        <td>{usr.nombre_completo}</td>
                        <td>
                          <span className={`badge-rol ${usr.rol}`}>
                            {usr.rol === 'admin' ? '👑 Admin' : '✏️ Editor'}
                          </span>
                        </td>
                        <td>
                          <span className={`badge-estado ${usr.activo ? 'activo' : 'inactivo'}`}>
                            {usr.activo ? '✓ Activo' : '✗ Inactivo'}
                          </span>
                        </td>
                        <td className="acciones">
                          <button
                            onClick={() => abrirModalEditarUsuario(usr)}
                            className="btn-icon btn-editar"
                            title="Editar usuario"
                          >
                            <FiEdit2 />
                          </button>
                          {usr.username !== 'admin' && (
                            <button
                              onClick={() => eliminarUsuario(usr.id)}
                              className="btn-icon btn-eliminar"
                              title="Eliminar usuario"
                            >
                              <FiTrash2 />
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </main>

      {/* Modal de Usuario */}
      {mostrarModalUsuario && (
        <div className="modal-overlay" onClick={cerrarModalUsuario}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>{modoEdicionUsuario ? 'Editar Usuario' : 'Crear Nuevo Usuario'}</h2>
              <button onClick={cerrarModalUsuario} className="btn-cerrar">
                <FiX />
              </button>
            </div>
            <form onSubmit={guardarUsuario} className="modal-form">
              <div className="form-group">
                <label>Usuario (login):</label>
                <input
                  type="text"
                  value={usuarioActual.username}
                  onChange={(e) => setUsuarioActual({ ...usuarioActual, username: e.target.value })}
                  placeholder="nombre.usuario"
                  disabled={modoEdicionUsuario}
                  required
                />
              </div>
              <div className="form-group">
                <label>Contraseña:</label>
                <input
                  type="password"
                  value={usuarioActual.password}
                  onChange={(e) => setUsuarioActual({ ...usuarioActual, password: e.target.value })}
                  placeholder={modoEdicionUsuario ? 'Dejar en blanco para no cambiar' : 'Contraseña'}
                  required={!modoEdicionUsuario}
                />
              </div>
              <div className="form-group">
                <label>Nombre Completo:</label>
                <input
                  type="text"
                  value={usuarioActual.nombre_completo}
                  onChange={(e) => setUsuarioActual({ ...usuarioActual, nombre_completo: e.target.value })}
                  placeholder="Juan Pérez"
                  required
                />
              </div>
              <div className="form-group">
                <label>Rol:</label>
                <select
                  value={usuarioActual.rol}
                  onChange={(e) => setUsuarioActual({ ...usuarioActual, rol: e.target.value })}
                  required
                >
                  <option value="editor">Editor (solo gestiona preguntas)</option>
                  <option value="admin">Administrador (acceso total)</option>
                </select>
              </div>
              <div className="form-group">
                <label>
                  <input
                    type="checkbox"
                    checked={usuarioActual.activo}
                    onChange={(e) => setUsuarioActual({ ...usuarioActual, activo: e.target.checked })}
                  />
                  Usuario activo
                </label>
              </div>
              <div className="modal-actions">
                <button type="button" onClick={cerrarModalUsuario} className="btn-cancelar">
                  Cancelar
                </button>
                <button type="submit" className="btn-guardar" disabled={loading}>
                  {loading ? 'Guardando...' : 'Guardar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal para Crear/Editar */}
      {mostrarModal && (
        <div className="modal-overlay" onClick={cerrarModal}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>{modoEdicion ? 'Editar Pregunta' : 'Nueva Pregunta'}</h2>
              <button onClick={cerrarModal} className="modal-close">×</button>
            </div>
            <form onSubmit={guardarPregunta} className="modal-form">
              <div className="form-group">
                <label>Pregunta:</label>
                <textarea
                  value={preguntaActual.pregunta}
                  onChange={(e) => setPreguntaActual({ ...preguntaActual, pregunta: e.target.value })}
                  placeholder="Escribe la pregunta aquí..."
                  rows="4"
                  required
                />
              </div>
              <div className="form-group">
                <label>Respuesta Correcta:</label>
                <textarea
                  value={preguntaActual.respuesta_correcta}
                  onChange={(e) => setPreguntaActual({ ...preguntaActual, respuesta_correcta: e.target.value })}
                  placeholder="Escribe la respuesta correcta aquí..."
                  rows="4"
                  required
                />
              </div>
              <div className="modal-actions">
                <button type="button" onClick={cerrarModal} className="btn-cancelar">
                  Cancelar
                </button>
                <button type="submit" className="btn-guardar" disabled={loading}>
                  {loading ? 'Guardando...' : 'Guardar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}

export default App
