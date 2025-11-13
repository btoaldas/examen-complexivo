-- Configurar UTF-8
SET client_encoding = 'UTF8';

-- Crear extensión para generar UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Crear extensión para búsqueda sin acentos (unaccent)
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Crear extensión para encriptación de contraseñas
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

-- Crear usuario administrador por defecto
-- Usuario: admin
-- Contraseña: Admin2025!
INSERT INTO usuarios (username, password_hash, nombre_completo, rol) 
VALUES ('admin', crypt('Admin2025!', gen_salt('bf', 10)), 'Administrador del Sistema', 'admin')
ON CONFLICT (username) DO NOTHING;

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

-- Índices para auditoría
CREATE INDEX IF NOT EXISTS idx_auditoria_usuario ON auditoria(usuario_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_fecha ON auditoria(created_at);
CREATE INDEX IF NOT EXISTS idx_auditoria_accion ON auditoria(accion);

-- Tabla de preguntas
CREATE TABLE IF NOT EXISTS preguntas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pregunta TEXT NOT NULL,
    respuesta_correcta TEXT NOT NULL,
    creado_por UUID REFERENCES usuarios(id),
    modificado_por UUID REFERENCES usuarios(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índice para búsqueda rápida (sin unaccent en el índice, lo usamos en las consultas)
CREATE INDEX IF NOT EXISTS idx_pregunta_search ON preguntas USING gin(to_tsvector('spanish', pregunta));

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at
CREATE TRIGGER update_preguntas_updated_at
    BEFORE UPDATE ON preguntas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- PREGUNTAS DEL EXAMEN COMPLEXIVO (37 ÚNICAS)
-- =====================================================

INSERT INTO preguntas (pregunta, respuesta_correcta) VALUES
-- GRUPO 1: Preguntas 1-20
('¿Cuál es la característica principal que distingue a una tupla de una lista en Python?', 'Las tuplas son inmutables, lo que significa que no se pueden modificar después de su creación.'),

('Quieres mostrar un gráfico de dispersión interactivo creado con Plotly Express (fig_plotly) y un histograma estático creado con Seaborn (fig_seaborn, ax_seaborn). ¿Cuál es la combinación de comandos correcta para renderizarlos en Streamlit?', 'st.plotly_chart(fig_plotly) y st.pyplot(fig_seaborn)'),

('¿Cuál es la diferencia fundamental entre una Imagen de Docker y un Contenedor de Docker?', 'Una Imagen es una plantilla estática y de solo lectura, mientras que un Contenedor es una instancia viva y ejecutable de esa plantilla.'),

('Un desarrollador quiere mostrar un KPI (Indicador Clave de Rendimiento) importante, como las ventas totales del mes, y compararlo con el mes anterior. ¿Qué componente de Streamlit está diseñado específicamente para este propósito?', 'st.metric(label=Ventas Mensuales, value=$50,000, delta=$5,000)'),

('Cuando tu API de FastAPI devuelve df.to_dict(orient=records), y tu cliente de Streamlit recibe el JSON y lo convierte a un DataFrame con pd.DataFrame(response.json()), ¿qué se ha logrado fundamentalmente?', 'Se ha serializado un objeto de Pandas a un formato de texto universal (JSON) para el transporte a través de la red, y luego se ha deserializado de vuelta a un objeto de Pandas.'),

('Un analista financiero está trabajando con un DataFrame que contiene datos de transacciones. Quiere visualizar la distribución del Monto de las transacciones, pero segmentado por Tipo_Comercio (ej: Retail, Online, Servicios) y, a su vez, desglosado por Metodo_Pago (ej: Tarjeta, Efectivo). Su objetivo es crear un solo gráfico interactivo que permita al usuario navegar desde el tipo de comercio hasta el método de pago para entender la composición del monto total. ¿Cuál de las siguientes visualizaciones es la más adecuada para representar esta estructura de datos jerárquica y de composición?', 'Un gráfico Sunburst, configurando la ruta (path) de esta manera [Tipo_Comercio, Metodo_Pago].'),

('¿Qué valor contendrá la variable resultado_final después de ejecutar este código? def resta(a, b): total = a - b return total resultado_final = resta(5, 10) + 5', '0'),

('Un DataFrame df tiene una columna ID_Producto (ej: PROD-12345). Quieres crear una nueva columna ID_Numerico que contenga solo la parte numérica del ID. ¿Cuál de las siguientes líneas de código lograría esto?', 'df[ID_Numerico] = df[ID_Producto].apply(lambda x: x.split(-)[1]).astype(int)'),

('Dado un DataFrame df_ventas, ¿cuál es la sintaxis correcta para seleccionar únicamente las filas donde la columna Region es Norte Y la columna Ventas es mayor a 2000?', 'df_ventas[(df_ventas[Region] == Norte) & (df_ventas[Ventas] > 2000)]'),

('Después de realizar una operación de groupby, como df.groupby(Pais)[Ventas].sum(), ¿qué representa el índice del objeto resultante?', 'Los valores únicos de la columna por la que se agrupó.'),

('El método .drop_duplicates() es fundamental para la limpieza de datos. ¿Cuál de las siguientes opciones describe con mayor precisión su comportamiento por defecto?', 'Analiza el DataFrame completo y elimina las filas que son una copia exacta de una fila que ya apareció previamente.'),

('Después de convertir una columna Fecha_Registro a formato datetime con pd.to_datetime, quieres crear una nueva columna que contenga únicamente el nombre del día de la semana (ej: Monday, Tuesday). ¿Cuál es el código correcto?', 'df[Dia_Semana] = df[Fecha_Registro].dt.day_name()'),

('¿Cuál es el propósito principal de la función pd.to_datetime()?', 'Convertir una Serie de Pandas que contiene texto o números en un objeto de tipo datetime64, que permite realizar operaciones y extracciones relacionadas con fechas.'),

('¿Por qué es una buena práctica de ingeniería de software usar try...except requests.exceptions.RequestException al hacer una llamada de red en una aplicación de Streamlit?', 'Para manejar elegantemente los errores de red y evitar que toda la aplicación de Streamlit se detenga con un error, mostrando en su lugar un mensaje amigable.'),

('En un Dockerfile, ¿por qué se considera una buena práctica de optimización copiar el archivo requirements.txt y ejecutar pip install antes de copiar el resto del código de la aplicación (como api_app.py)?', 'Para aprovechar el sistema de caché por capas de Docker; si el código de la app cambia pero las dependencias no, el lento paso de pip install no se vuelve a ejecutar.'),

('Un desarrollador coloca la línea df = pd.read_csv(datos.csv) fuera de cualquier función de endpoint, en el scope global del script api_app.py. ¿Por qué esta es una buena práctica para el rendimiento?', 'Porque permite que el archivo de datos se cargue en la memoria una sola vez cuando la API se inicia, en lugar de volver a leerlo desde el disco en cada petición.'),

('Un usuario interactúa con un st.slider en una aplicación de Streamlit. ¿Qué sucede inmediatamente después en el backend?', 'El script completo de Python, de principio a fin, se re-ejecuta, y el slider ahora reporta su nuevo valor.'),

('Dado el siguiente código: sensor_data = (101, 24.5, 68) id_sensor, temperatura, humedad = sensor_data print(id_sensor) ¿Qué valor se imprimirá en la consola?', '101'),

('Un desarrollador quiere permitir que el usuario seleccione una y solo una ciudad de una lista para filtrar un mapa. ¿Qué widget de Streamlit es el más apropiado para esta tarea?', 'st.radio o st.selectbox'),

('Revisa el siguiente script en Python: entrada_usuario = veinte cantidad = 1 try: cantidad = int(entrada_usuario) except ValueError: cantidad = 5 costo_total = 10 * cantidad print(fEl costo final es: ${costo_total})', 'El costo final es: $50'),

-- GRUPO 2: Preguntas 21-37 (eliminando duplicados: pregunta 4, 7 y 15 del segundo grupo)
('En Git, ¿cuál es la razón principal para crear una nueva rama (branch) antes de empezar a trabajar en una nueva funcionalidad o corregir un error?', 'Para trabajar de forma aislada sin afectar la versión estable y funcional del código en la rama principal.'),

('Para que un DataFrame de Pandas pueda ser enviado como una respuesta JSON válida desde una API, debe ser serializado. ¿Qué hace el método .to_dict(orient=records)?', 'Convierte cada fila del DataFrame en un diccionario y devuelve una lista de estos diccionarios.'),

('Un desarrollador en tu equipo acaba de fusionar (merge) un Pull Request en la rama principal (main) del repositorio en GitHub. Tu rama main local ahora está desactualizada. Después de cambiar a tu rama principal local con git checkout main, ¿qué comando de Git debes ejecutar para descargar los cambios más recientes del repositorio remoto y actualizar tu copia local?', 'git pull origin main'),

('¿Cuál es el nombre de la estructura de datos principal, similar a una tabla o una hoja de cálculo, que utiliza la librería Pandas para almacenar y manipular datos?', 'DataFrame'),

('Un equipo de analítica tiene un DataFrame con datos geográficos de miles de tiendas a nivel mundial. Quieren crear una visualización que muestre la densidad de tiendas en un mapa, es decir, las zonas o puntos calientes donde se concentran geográficamente. ¿Qué tipo de gráfico geoespacial y qué concepto se alinea mejor con el objetivo de visualizar la densidad de puntos en un mapa?', 'Un mapa de densidad (density_mapbox), que está diseñado para mostrar la concentración de puntos en un área geográfica.'),

('Un analista quiere crear una nueva columna Tipo_Cliente basada en la columna Antigüedad (en años). Si la antigüedad es mayor a 5 años, debe ser Leal; de lo contrario, Nuevo. ¿Cuál es la forma más eficiente y pythónica de lograr esto en Pandas?', 'df[Tipo_Cliente] = np.where(df[Antigüedad] > 5, Leal, Nuevo)'),

('Necesitas mostrar un DataFrame de Pandas (df) en tu aplicación. Tienes dos opciones: st.write(df) y st.dataframe(df). ¿Cuál es la ventaja clave de usar st.dataframe(df)?', 'st.dataframe renderiza una tabla interactiva que permite al usuario ordenar las columnas, mientras que st.write muestra una tabla estática.'),

('Se tiene un diccionario que almacena la configuración de una aplicación. Se necesita iterar únicamente sobre las claves (los nombres de las configuraciones) para imprimirlas. configuracion = { theme: dark, font_size: 14, show_sidebar: True } for key in configuracion.keys(): print(key) ¿Qué tipo de objeto devuelve el método .keys() de un diccionario en Python?', 'Un objeto de vista (dict_keys) que contiene las claves.'),

('Un analista de datos está estudiando un dataset de clientes y quiere visualizar la distribución de la columna edad, que es una variable numérica continua, para entender qué rangos de edad son más frecuentes. ¿Cuál de las siguientes afirmaciones describe la elección de gráfico correcta y la razón técnica por la que es la adecuada?', 'Debería usar un histograma (histplot), porque agrupa los valores de la variable numérica continua en intervalos (bins) y luego cuenta la frecuencia de observaciones en cada intervalo.'),

('Para ejecutar una aplicación de Streamlit guardada en un archivo llamado mi_app.py desde la terminal, ¿cuál es el comando correcto?', 'streamlit run mi_app.py'),

('Quieres organizar tu dashboard para que un gráfico principal ocupe el 70% del ancho de la pantalla y una tabla con datos de resumen ocupe el 30% restante, uno al lado del otro. ¿Cómo lograrías este layout con st.columns?', 'col1, col2 = st.columns([0.7, 0.3])'),

('Un analista de datos está procesando una columna Fecha que contiene texto y sabe que algunas entradas pueden tener formatos incorrectos o ser inválidas (ej: Fecha no disponible). El objetivo es convertir la columna a tipo datetime, pero sin que el script se detenga por errores. Además, las fechas inválidas deben ser marcadas como un valor nulo de tipo fecha (NaT) para poder filtrarlas y contarlas después.', 'pd.to_datetime(df[Fecha], errors=coerce)'),

('Quieres crear un endpoint en FastAPI para buscar ítems, permitiendo al usuario especificar opcionalmente cuántos resultados quiere, así: http://127.0.0.1:8000/items?limit=20. ¿Cómo se define la función para manejar este parámetro de consulta (query parameter)?', '@app.get(/items) y def get_items(limit: int = 10):'),

('Dentro de la instrucción CMD de un Dockerfile para una API de FastAPI, es crucial usar --host, 0.0.0.0. ¿Por qué?', '0.0.0.0 es una dirección IP especial que le dice al servidor que escuche peticiones desde cualquier interfaz de red, permitiendo que las peticiones de la máquina anfitriona lleguen al contenedor.'),

('Una API devuelve una respuesta JSON exitosa. En tu script de Streamlit, después de recibir el objeto response de requests.get(...), ¿qué método debes llamar en este objeto para convertir el cuerpo de la respuesta en una estructura de datos de Python (como una lista o un diccionario)?', 'response.json()'),

('¿Cuál de las siguientes afirmaciones sobre la variable elementos_unicos es verdadera? mi_lista = [1, 2, a, 3, 2, a, b] elementos_unicos = set(mi_lista) print(elementos_unicos)', 'Es un set que contiene 5 elementos únicos.'),

('Un programador necesita mostrar el resultado de un cálculo de promedio, pero quiere asegurarse de que el número se muestre siempre con solo dos decimales en la salida final. promedio = 95.8763 print(fEl promedio final es: {promedio:.2f}) ¿Cuál será la salida exacta que producirá este código?', 'El promedio final es: 95.88');

-- Verificar datos insertados
SELECT COUNT(*) as total_preguntas FROM preguntas;
