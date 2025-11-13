-- =====================================================
-- BACKUP DE BASE DE DATOS - BANCO DE PREGUNTAS
-- Generado: 11/11/2025, 3:53:10
-- Usuario: admin
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

-- Insertar usuarios
INSERT INTO usuarios (id, username, password_hash, nombre_completo, rol, activo, created_at, updated_at) VALUES (
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    'admin',
    '$2a$10$twGSjxnwUv0.mOmUf6YMbuX6Ab1/kzEUObI7rTINPNyF6hnrGJSNW',
    'Administrador del Sistema',
    'admin',
    true,
    '2025-11-06T00:27:46.998Z',
    '2025-11-06T00:27:46.998Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO usuarios (id, username, password_hash, nombre_completo, rol, activo, created_at, updated_at) VALUES (
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    'joel',
    '$2a$10$P5RK7mfXRU5hNoEaW0gCkeD2UDJws96BLgaahEU.IC997xP9Rg/i2',
    'Joel111',
    'editor',
    true,
    '2025-11-06T00:39:05.581Z',
    '2025-11-06T00:39:05.581Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO usuarios (id, username, password_hash, nombre_completo, rol, activo, created_at, updated_at) VALUES (
    '8945b442-07c5-4856-9579-3d19bcdba685',
    'wilson',
    '$2a$10$VNBJRQ3kIKqk2Thqn0sXC.4jTqnZQAOfb/C4nFjHyfxBmasvVIqny',
    'Wilson',
    'editor',
    true,
    '2025-11-06T03:16:00.022Z',
    '2025-11-06T03:16:00.022Z'
) ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- DATOS DE PREGUNTAS (102 registros)
-- =====================================================

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '32d72b4a-c283-47ae-b198-768f2713aab5',
    '¿Cuál es el propósito principal de la función pd.to_datetime()?',
    'Convertir una Serie de Pandas que contiene texto o números en un objeto de tipo datetime64, que permite realizar operaciones y extracciones relacionadas con fechas.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '627b06a3-a1cd-4eb1-9a84-0370e41b7302',
    'Quieres mostrar un gráfico de dispersión interactivo creado con Plotly Express (fig_plotly) y un histograma estático creado con Seaborn (fig_seaborn, ax_seaborn). ¿Cuál es la combinación de comandos correcta para renderizarlos en Streamlit?',
    'st.plotly_chart(fig_plotly) y st.pyplot(fig_seaborn)',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'b317725e-8af1-4c53-b715-8e8fa7e6e624',
    '¿Cuál es la diferencia fundamental entre una Imagen de Docker y un Contenedor de Docker?',
    'Una Imagen es una plantilla estática y de solo lectura, mientras que un Contenedor es una instancia viva y ejecutable de esa plantilla.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '6881c77a-e5d9-44fc-b842-dcc4f13b8769',
    'Un desarrollador quiere mostrar un KPI (Indicador Clave de Rendimiento) importante, como las ventas totales del mes, y compararlo con el mes anterior. ¿Qué componente de Streamlit está diseñado específicamente para este propósito?',
    'st.metric(label=Ventas Mensuales, value=$50,000, delta=$5,000)',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'ce70b6f9-c87f-4523-9b28-9e8abcd116b1',
    'Cuando tu API de FastAPI devuelve df.to_dict(orient=records), y tu cliente de Streamlit recibe el JSON y lo convierte a un DataFrame con pd.DataFrame(response.json()), ¿qué se ha logrado fundamentalmente?',
    'Se ha serializado un objeto de Pandas a un formato de texto universal (JSON) para el transporte a través de la red, y luego se ha deserializado de vuelta a un objeto de Pandas.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '7bc06bfe-a9e9-472e-bbef-dfbc65969745',
    'Un analista financiero está trabajando con un DataFrame que contiene datos de transacciones. Quiere visualizar la distribución del Monto de las transacciones, pero segmentado por Tipo_Comercio (ej: Retail, Online, Servicios) y, a su vez, desglosado por Metodo_Pago (ej: Tarjeta, Efectivo). Su objetivo es crear un solo gráfico interactivo que permita al usuario navegar desde el tipo de comercio hasta el método de pago para entender la composición del monto total. ¿Cuál de las siguientes visualizaciones es la más adecuada para representar esta estructura de datos jerárquica y de composición?',
    'Un gráfico Sunburst, configurando la ruta (path) de esta manera [Tipo_Comercio, Metodo_Pago].',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'f23db5bd-242d-469b-97fe-18ace406e650',
    '¿Qué valor contendrá la variable resultado_final después de ejecutar este código? def resta(a, b): total = a - b return total resultado_final = resta(5, 10) + 5',
    '0',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '58437373-24a5-45cf-80ac-5996e6c3f36e',
    'Un DataFrame df tiene una columna ID_Producto (ej: PROD-12345). Quieres crear una nueva columna ID_Numerico que contenga solo la parte numérica del ID. ¿Cuál de las siguientes líneas de código lograría esto?',
    'df[ID_Numerico] = df[ID_Producto].apply(lambda x: x.split(-)[1]).astype(int)',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '3dfcd825-2fd5-45fb-a6ca-6c0fc1dc1e7d',
    'Dado un DataFrame df_ventas, ¿cuál es la sintaxis correcta para seleccionar únicamente las filas donde la columna Region es Norte Y la columna Ventas es mayor a 2000?',
    'df_ventas[(df_ventas[Region] == Norte) & (df_ventas[Ventas] > 2000)]',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '7b780071-6234-4d70-945d-f8eabde9db8f',
    'Después de realizar una operación de groupby, como df.groupby(Pais)[Ventas].sum(), ¿qué representa el índice del objeto resultante?',
    'Los valores únicos de la columna por la que se agrupó.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '7a824acc-6da3-4990-b234-8cf237fbc6f7',
    'El método .drop_duplicates() es fundamental para la limpieza de datos. ¿Cuál de las siguientes opciones describe con mayor precisión su comportamiento por defecto?',
    'Analiza el DataFrame completo y elimina las filas que son una copia exacta de una fila que ya apareció previamente.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'f4aa3613-51b7-41b1-8caa-b4d20d4ca66b',
    'Después de convertir una columna Fecha_Registro a formato datetime con pd.to_datetime, quieres crear una nueva columna que contenga únicamente el nombre del día de la semana (ej: Monday, Tuesday). ¿Cuál es el código correcto?',
    'df[Dia_Semana] = df[Fecha_Registro].dt.day_name()',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '70432700-09ea-468b-bad4-f626166d46fd',
    'Para que un DataFrame de Pandas pueda ser enviado como una respuesta JSON válida desde una API, debe ser serializado. ¿Qué hace el método .to_dict(orient=records)?',
    'Convierte cada fila del DataFrame en un diccionario y devuelve una lista de estos diccionarios.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '18f24c96-8b16-4958-baa6-43214f4a405e',
    'Un desarrollador en tu equipo acaba de fusionar (merge) un Pull Request en la rama principal (main) del repositorio en GitHub. Tu rama main local ahora está desactualizada. Después de cambiar a tu rama principal local con git checkout main, ¿qué comando de Git debes ejecutar para descargar los cambios más recientes del repositorio remoto y actualizar tu copia local?',
    'git pull origin main',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '56715b32-a058-48f0-a00d-65ed3b16a648',
    '¿Cuál es el nombre de la estructura de datos principal, similar a una tabla o una hoja de cálculo, que utiliza la librería Pandas para almacenar y manipular datos?',
    'DataFrame',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '5e841c0f-0497-49bc-b789-4127c5c10b33',
    'Un equipo de analítica tiene un DataFrame con datos geográficos de miles de tiendas a nivel mundial. Quieren crear una visualización que muestre la densidad de tiendas en un mapa, es decir, las zonas o puntos calientes donde se concentran geográficamente. ¿Qué tipo de gráfico geoespacial y qué concepto se alinea mejor con el objetivo de visualizar la densidad de puntos en un mapa?',
    'Un mapa de densidad (density_mapbox), que está diseñado para mostrar la concentración de puntos en un área geográfica.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'a8e7c341-87ba-47e3-9c86-28d8cfdde191',
    'Un analista quiere crear una nueva columna Tipo_Cliente basada en la columna Antigüedad (en años). Si la antigüedad es mayor a 5 años, debe ser Leal; de lo contrario, Nuevo. ¿Cuál es la forma más eficiente y pythónica de lograr esto en Pandas?',
    'df[Tipo_Cliente] = np.where(df[Antigüedad] > 5, Leal, Nuevo)',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '1ed82806-8358-44ee-94a3-a21316695e50',
    'Necesitas mostrar un DataFrame de Pandas (df) en tu aplicación. Tienes dos opciones: st.write(df) y st.dataframe(df). ¿Cuál es la ventaja clave de usar st.dataframe(df)?',
    'st.dataframe renderiza una tabla interactiva que permite al usuario ordenar las columnas, mientras que st.write muestra una tabla estática.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '48d7666b-a576-4feb-9bca-85d19273bf1a',
    'Se tiene un diccionario que almacena la configuración de una aplicación. Se necesita iterar únicamente sobre las claves (los nombres de las configuraciones) para imprimirlas. configuracion = { theme: dark, font_size: 14, show_sidebar: True } for key in configuracion.keys(): print(key) ¿Qué tipo de objeto devuelve el método .keys() de un diccionario en Python?',
    'Un objeto de vista (dict_keys) que contiene las claves.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '383d09f3-a294-411e-a3d3-2e981803c41d',
    'Un analista de datos está estudiando un dataset de clientes y quiere visualizar la distribución de la columna edad, que es una variable numérica continua, para entender qué rangos de edad son más frecuentes. ¿Cuál de las siguientes afirmaciones describe la elección de gráfico correcta y la razón técnica por la que es la adecuada?',
    'Debería usar un histograma (histplot), porque agrupa los valores de la variable numérica continua en intervalos (bins) y luego cuenta la frecuencia de observaciones en cada intervalo.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '35b0ffc3-8a65-44d9-a2c6-8b562aa59320',
    'Para ejecutar una aplicación de Streamlit guardada en un archivo llamado mi_app.py desde la terminal, ¿cuál es el comando correcto?',
    'streamlit run mi_app.py',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '6d5377d9-a7f1-4ad5-b8ba-c820d99a1224',
    'Quieres organizar tu dashboard para que un gráfico principal ocupe el 70% del ancho de la pantalla y una tabla con datos de resumen ocupe el 30% restante, uno al lado del otro. ¿Cómo lograrías este layout con st.columns?',
    'col1, col2 = st.columns([0.7, 0.3])',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '169a12d6-92ae-4fe1-8181-c2e4a15fb6e8',
    'Un analista de datos está procesando una columna Fecha que contiene texto y sabe que algunas entradas pueden tener formatos incorrectos o ser inválidas (ej: Fecha no disponible). El objetivo es convertir la columna a tipo datetime, pero sin que el script se detenga por errores. Además, las fechas inválidas deben ser marcadas como un valor nulo de tipo fecha (NaT) para poder filtrarlas y contarlas después.',
    'pd.to_datetime(df[Fecha], errors=coerce)',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '2b401a91-fa4d-4a4b-8da7-265e6e598ef4',
    'Quieres crear un endpoint en FastAPI para buscar ítems, permitiendo al usuario especificar opcionalmente cuántos resultados quiere, así: http://127.0.0.1:8000/items?limit=20. ¿Cómo se define la función para manejar este parámetro de consulta (query parameter)?',
    '@app.get(/items) y def get_items(limit: int = 10):',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '65e9efaf-2789-417c-ae24-6312550ce199',
    'Dentro de la instrucción CMD de un Dockerfile para una API de FastAPI, es crucial usar --host, 0.0.0.0. ¿Por qué?',
    '0.0.0.0 es una dirección IP especial que le dice al servidor que escuche peticiones desde cualquier interfaz de red, permitiendo que las peticiones de la máquina anfitriona lleguen al contenedor.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'd76af617-d1f7-4047-8e88-bf51b7b3a3ec',
    'Una API devuelve una respuesta JSON exitosa. En tu script de Streamlit, después de recibir el objeto response de requests.get(...), ¿qué método debes llamar en este objeto para convertir el cuerpo de la respuesta en una estructura de datos de Python (como una lista o un diccionario)?',
    'response.json()',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '29bebc1b-ae2b-487a-b19f-6608e21450be',
    '¿Cuál de las siguientes afirmaciones sobre la variable elementos_unicos es verdadera? mi_lista = [1, 2, a, 3, 2, a, b] elementos_unicos = set(mi_lista) print(elementos_unicos)',
    'Es un set que contiene 5 elementos únicos.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'ffa7355a-6049-4b66-910a-0d142f67f9aa',
    'Un programador necesita mostrar el resultado de un cálculo de promedio, pero quiere asegurarse de que el número se muestre siempre con solo dos decimales en la salida final. promedio = 95.8763 print(fEl promedio final es: {promedio:.2f}) ¿Cuál será la salida exacta que producirá este código?',
    'El promedio final es: 95.88',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '98e4ea15-cf84-4e49-af95-5fdfd4df552f',
    '¿Cuál es la característica principal que distingue a una tupla de una lista en Python?',
    'Las tuplas son inmutables, lo que significa que no se pueden modificar después de su creación.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '48a9b1bd-3bc4-47bf-9a99-41fb0178ef5c',
    '¿Por qué es una buena práctica de ingeniería de software usar try...except requests.exceptions.RequestException al hacer una llamada de red en una aplicación de Streamlit?',
    'Para manejar elegantemente los errores de red y evitar que toda la aplicación de Streamlit se detenga con un error, mostrando en su lugar un mensaje amigable.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '90a9c21c-4e26-44bb-902a-c921d3a617d8',
    'En un Dockerfile, ¿por qué se considera una buena práctica de optimización copiar el archivo requirements.txt y ejecutar pip install antes de copiar el resto del código de la aplicación (como api_app.py)?',
    'Para aprovechar el sistema de caché por capas de Docker; si el código de la app cambia pero las dependencias no, el lento paso de pip install no se vuelve a ejecutar.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'b32eb9aa-4710-49d6-97b0-799595762a7c',
    'Un desarrollador coloca la línea df = pd.read_csv(datos.csv) fuera de cualquier función de endpoint, en el scope global del script api_app.py. ¿Por qué esta es una buena práctica para el rendimiento?',
    'Porque permite que el archivo de datos se cargue en la memoria una sola vez cuando la API se inicia, en lugar de volver a leerlo desde el disco en cada petición.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '0a69d43c-b544-4612-a568-403e6b163ca1',
    'Un usuario interactúa con un st.slider en una aplicación de Streamlit. ¿Qué sucede inmediatamente después en el backend?',
    'El script completo de Python, de principio a fin, se re-ejecuta, y el slider ahora reporta su nuevo valor.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '8f22ca90-42b7-4fc5-a866-795093c54cfc',
    'Dado el siguiente código: sensor_data = (101, 24.5, 68) id_sensor, temperatura, humedad = sensor_data print(id_sensor) ¿Qué valor se imprimirá en la consola?',
    '101',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '483acb17-d85f-4f3e-bf00-296587191d01',
    'Un desarrollador quiere permitir que el usuario seleccione una y solo una ciudad de una lista para filtrar un mapa. ¿Qué widget de Streamlit es el más apropiado para esta tarea?',
    'st.radio o st.selectbox',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'c5ed4b14-830f-4553-ab60-43a18ebffb8a',
    'Revisa el siguiente script en Python: entrada_usuario = veinte cantidad = 1 try: cantidad = int(entrada_usuario) except ValueError: cantidad = 5 costo_total = 10 * cantidad print(fEl costo final es: ${costo_total})',
    'El costo final es: $50',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'e46480d9-d247-48ba-9852-67f0461317d2',
    'En Git, ¿cuál es la razón principal para crear una nueva rama (branch) antes de empezar a trabajar en una nueva funcionalidad o corregir un error?',
    'Para trabajar de forma aislada sin afectar la versión estable y funcional del código en la rama principal.',
    NULL,
    NULL,
    '2025-11-06T00:27:47.097Z',
    '2025-11-06T00:27:47.097Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'c334ab95-9963-461d-8565-359a99928bde',
    '¿Qué valor se almacenará en la variable resultado después de ejecutar la siguiente línea de código en Python? resultado = 15 % 4',
    'resultado = 3',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    '2025-11-06T04:49:15.875Z',
    '2025-11-06T19:12:03.356Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'aca93a1f-4aba-4657-b81d-e7e9e7968b87',
    'Estás creando un gráfico de dispersión con Plotly para analizar la relación entre total_bill y tip. Quieres crear una versión de este gráfico para cada valor único de la columna time (ej: Lunch, Dinner). ¿Qué parámetro debes añadir a tu función px.scatter?',
    'La opción correcta es: facet_col=''time''',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    NULL,
    '2025-11-06T04:50:48.987Z',
    '2025-11-06T04:50:48.987Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '8bfbe68c-60ea-49c0-81e7-dec6b0121d0f',
    'En la arquitectura cliente-servidor que hemos construido, ¿qué librería de Python actúa como el teléfono que permite al cliente (Streamlit) llamar al servidor (FastAPI)?',
    'Requests',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    NULL,
    '2025-11-06T04:52:00.954Z',
    '2025-11-06T04:52:00.954Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'e5673d95-93a9-4a56-bf7a-0502fe2578d3',
    'En Python, ¿cuál es la convención de estilo recomendada para nombrar variables que constan de varias palabras (por ejemplo, User Name)?',
    'user_name (snake_case)',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    NULL,
    '2025-11-06T04:53:07.977Z',
    '2025-11-06T04:53:07.977Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '63c46213-2426-4071-a48d-e87716b949a7',
    'Un analista sospecha que la ausencia de datos en una columna podría estar relacionada con la ausencia de datos en otra. Por ejemplo, si falta el dato de Fecha_de_entrega, es muy probable que también falte el dato de Estado_del_envio. ¿Qué función de la librería missingno se especializa en visualizar la correlación de nulidad entre columnas, mostrando una matriz donde un valor cercano a 1 indica que si una columna tiene un valor nulo, la otra también tiende a tenerlo?',
    'El mapa de calor (msno.heatmap)',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    NULL,
    '2025-11-06T04:59:33.756Z',
    '2025-11-06T04:59:33.756Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '0efe51a4-de2c-47b7-83bb-5ea3d64843bb',
    '¿Qué línea de código se debe usar para acceder al último elemento de la lista planetas = [Mercurio, Venus, Tierra, Marte]?',
    'planetas[-1]',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    NULL,
    '2025-11-06T05:01:52.141Z',
    '2025-11-06T05:01:52.141Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '964e8a66-ee4a-4224-8de0-f4f73a9a19e1',
    'En una arquitectura de software desacoplada, ¿cuál es el rol principal de una API?',
    'Servir como un intermediario estandarizado que permite la comunicación entre el frontend y el backend sin que dependan directamente el uno del otro.',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    NULL,
    '2025-11-06T05:05:27.025Z',
    '2025-11-06T05:05:27.025Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '1029af33-e2c6-455d-9767-218ab989e19f',
    'Un desarrollador ejecuta docker build -t mi_app . y funciona. Luego, cambia una sola línea de texto en un comentario dentro de api_app.py y vuelve a ejecutar docker build -t mi_app .. ¿Qué comportamiento esperaría ver en la salida de la terminal?',
    'El build será casi instantáneo, reutilizando las capas cacheadas para la base de Python y la instalación de pip, y solo reconstruyendo la capa final donde se copió el código modificado.',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    NULL,
    '2025-11-06T05:06:49.248Z',
    '2025-11-06T05:06:49.248Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'da4b7734-dbd6-4631-b959-7bf33633bd66',
    'En una aplicación de Streamlit, un st.slider llamado slider_anios devuelve una tupla con dos valores: (2018, 2022). ¿Cuál de las siguientes líneas de código de Pandas filtra correctamente un DataFrame df para incluir solo las filas donde la columna Anio está dentro de ese rango (inclusivo)?',
    'df[(df["Anio"] >= slider_anios[0]) & (df["Anio"] <= slider_anios[1])]',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    NULL,
    '2025-11-06T05:10:05.357Z',
    '2025-11-06T05:10:05.357Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'c630490e-e1e4-4770-a7eb-74be33b8e314',
    'Dado el siguiente diccionario que representa un producto: producto = { nombre: Laptop Pro, precio: 1200, disponible: True } ¿Cuál es la sintaxis correcta para acceder al precio del producto?',
    'producto[precio]',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    '2025-11-06T05:10:46.445Z',
    '2025-11-07T05:39:40.213Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '65df4f68-13ad-477e-8e80-91f8ef391abe',
    'Un analista quiere obtener un reporte que muestre, para cada Categoria de producto, la suma total de Ventas y el valor máximo de Ganancia. ¿Cuál es la sintaxis correcta usando el método .agg()?',
    'df.groupby("Categoria").agg(Total_Ventas=("Ventas", sum), Max_Ganancia=("Ganancia", max))',
    '8945b442-07c5-4856-9579-3d19bcdba685',
    NULL,
    '2025-11-06T05:11:44.211Z',
    '2025-11-06T05:11:44.211Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'ccc472ec-05ca-4330-9962-10cadcb194c9',
    'Tu modelo de Scikit-Learn fue entrenado con un DataFrame de Pandas que tiene 3 columnas: [feature1, feature2, feature3]. Tu endpoint POST recibe un objeto Pydantic con los mismos 3 campos. ¿Cuál es el paso crucial que debes realizar dentro del endpoint antes de llamar a model.predict()?',
    'Convertir el objeto Pydantic de entrada a un formato que el modelo entienda, como un DataFrame de Pandas, asegurando que el orden de las columnas sea el correcto.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T14:56:49.344Z',
    '2025-11-06T14:56:49.344Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '8537794d-afdc-4b9d-be33-71a0a62dbde0',
    'Un analista decide reemplazar los valores nulos (NaN) en la columna Ingresos con el promedio de esa misma columna. ¿Cuál de las siguientes líneas de código realiza esta operación y actualiza el DataFrame df de forma correcta y permanente?',
    'df["Ingresos"] = df["Ingresos"].fillna(df["Ingresos"].mean())',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T14:59:07.954Z',
    '2025-11-06T14:59:07.954Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '89f3e97e-3afb-4072-9f83-d87ad63ade45',
    'Después de cargar un dataset en un DataFrame llamado df, ejecutas el comando df.info(). ¿Cuál de las siguientes informaciones NO es proporcionada directamente por este comando?',
    'El promedio (mean) de las columnas numéricas.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T15:00:38.901Z',
    '2025-11-06T15:00:38.901Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '4f189dfa-674d-474d-b903-5b3f1fdf8792',
    'Analiza el siguiente código de Pydantic y el JSON de entrada: # Pydantic Model in FastAPI class Item(BaseModel): name: str price: float is_offer: bool = True # Campo opcional con valor por defecto # Incoming JSON { name: Laptop, price: 999.99 } Si este JSON se envía al endpoint, ¿cómo lo procesará Pydantic?',
    'Procesará los datos exitosamente, creando un objeto Item donde is_offer tendrá su valor por defecto True',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T15:01:05.330Z',
    '2025-11-06T15:01:05.330Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'eb532f6c-69ad-452b-b5d8-d395521a38e2',
    'Un analista de datos está trabajando con un DataFrame df_pedidos que contiene información sobre ventas y quiere saber rápidamente cuál es el país que ha realizado más pedidos. La columna de interés se llama Pais. ¿Cuál de los siguientes comandos de Pandas es el más directo y adecuado para obtener un conteo de cuántas veces aparece cada país en la columna?',
    'df_pedidos[Pais].value_counts()',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    '2025-11-06T15:40:07.078Z',
    '2025-11-10T20:58:21.635Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '8c590c0c-50c2-46f8-85ef-c26b39f9f173',
    'Un analista quiere crear rápidamente un gráfico de líneas para tener una idea preliminar de la tendencia de ventas a lo largo del tiempo, directamente desde su DataFrame df_ventas. ¿Cuál es la forma más directa de hacerlo?',
    'df_ventas.plot(kind="line", x="Fecha", y="Ventas")',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T15:40:33.137Z',
    '2025-11-06T15:40:33.137Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'a4d879d4-036d-4f1c-8064-cd2b8330edfe',
    'Un analista de datos tiene un DataFrame de ventas con las columnas Ciudad y Ingresos. Observa que faltan algunos valores en la columna Ingresos. Sabe que simplemente rellenar todos los valores faltantes con la media global de Ingresos de todo el país podría ser inexacto, ya que los ingresos promedio varían significativamente de una ciudad a otra. ¿Cuál de las siguientes estrategias sería conceptualmente la más precisa y menos sesgada para imputar (rellenar) los valores de ingresos faltantes?',
    'Para cada fila con un ingreso faltante, calcular la media de ingresos únicamente de la ciudad a la que pertenece esa fila y usar ese valor específico para rellenar el dato.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T15:41:02.819Z',
    '2025-11-06T15:41:02.819Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '1e8eee9b-ce82-4ccb-a244-c4325f0e2e8a',
    '¿Qué hace el comando df.groupby(Grupo).reset_index()?',
    'Realiza la agrupación y luego convierte la columna del índice creada por el groupby de nuevo en una columna regular del DataFrame.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T15:41:46.868Z',
    '2025-11-06T15:41:46.868Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '831707e6-04b3-41e9-b13e-5744e97b98ee',
    'El siguiente script determina si un usuario tiene acceso a una función premium de un sistema. El acceso se concede si el usuario es administrador, O si tiene una suscripción activa Y es un invitado especial. es_admin = False suscripcion_activa = True es_invitado_especial = False if es_admin or suscripcion_activa and es_invitado_especial: print(Acceso Concedido) else: print(Acceso Denegado) Considerando la precedencia de operadores en Python, ¿cuál será la salida del script?',
    'Acceso Denegado',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T15:43:51.177Z',
    '2025-11-06T15:43:51.177Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '25311ba8-813f-4b49-8e25-f08a8a956fda',
    'Un estudiante ejecuta el comando df.describe() sobre su DataFrame y observa que el resultado solo incluye las columnas que contienen datos numéricos (como int64 y float64), ignorando las columnas de tipo object (texto). ¿Cuál es el propósito principal del método .describe()?',
    'Generar un resumen estadístico descriptivo para las columnas numéricas.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T15:44:19.520Z',
    '2025-11-06T15:44:19.520Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '689649c7-d68e-4fa0-bfba-2617633cbabd',
    'Un script de Streamlit contiene la siguiente lógica: opciones = st.multiselect(Elige:, [A, B, C]). Si un usuario no selecciona ninguna opción, ¿qué valor contendrá la variable opciones?',
    'Una lista vacía []',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T17:53:25.481Z',
    '2025-11-06T17:53:25.481Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'e57a02fc-f8bc-4470-ac70-6ec38ee5188b',
    '¿Cuál es la diferencia de propósito entre las instrucciones RUN y CMD en un Dockerfile?',
    'RUN se ejecuta una sola vez cuando se construye la imagen, mientras que CMD especifica el comando por defecto que se ejecuta cuando se inicia un contenedor a partir de esa imagen.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T17:54:40.750Z',
    '2025-11-06T17:54:40.750Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '073b3030-9b94-450f-8d54-1b25acc3b103',
    'En Pandas, ¿cuál es la diferencia fundamental entre seleccionar datos con .loc y con .iloc?',
    '.loc se usa para seleccionar por las etiquetas del índice, mientras que .iloc se usa para seleccionar por la posición numérica entera.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T17:56:46.676Z',
    '2025-11-06T17:56:46.676Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'b1d8fb55-4841-4b14-aefe-2eaf399cc6fb',
    'Al ejecutar un contenedor con el comando docker run -p 8080:8000 mi_imagen, ¿qué significa exactamente la parte -p 8080:8000?',
    'La aplicación dentro del contenedor, que está escuchando en el puerto 8000, será accesible desde el exterior a través del puerto 8080 de la máquina anfitriona.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T17:57:57.848Z',
    '2025-11-06T17:57:57.848Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '60d69f6c-2dcf-46ac-b429-15b2b61e78c9',
    'En el flujo de trabajo de Git, ¿cuál es la diferencia fundamental entre los comandos git commit y git push?',
    'git commit guarda los cambios en el repositorio local, mientras que git push envía esos cambios al repositorio remoto.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T17:58:27.717Z',
    '2025-11-06T17:58:27.717Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'cfdc69a2-cc4e-4c0e-995b-4cdcda20ca94',
    'Al analizar un mapa de calor (heatmap) de correlaciones, encuentras que el cuadrado donde se cruzan las variables Años_Experiencia y Salario tiene un valor de -0.9. ¿Qué insight puedes extraer de este valor?',
    'Existe una fuerte correlación negativa: a medida que una variable aumenta, la otra tiende a disminuir.',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-06T18:00:26.353Z',
    '2025-11-06T18:00:26.353Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'e333a6ca-83e3-4a8a-b1a3-6cc1e0dd5344',
    'En la fase de visualización del EDA, ¿qué acción representa mejor una práctica madura?',
    'Empezar con una pregunta de negocio específica, elegir el gráfico adecuado para responderla, y usar el resultado para formular la siguiente pregunta.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:06:45.306Z',
    '2025-11-06T19:06:45.306Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '3ac7e4f3-be7e-4d2b-92ac-794284b62451',
    '¿Cuándo usar .apply() en vez de vectorización o np.where?',
    'Cuando la lógica para crear la nueva columna es compleja y no puede ser expresada fácilmente con operaciones estándar, requiriendo una función personalizada.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:07:44.259Z',
    '2025-11-06T19:07:44.259Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '89c5a852-30ff-4b0f-9cde-cd40d5b399ce',
    'Analiza el siguiente bloque de código, cuyo objetivo es crear una nueva lista que contenga únicamente los números pares de la lista original. numeros_iniciales = [10, 23, 44, 57, 88, 91] numeros_pares = [] for numero in numeros_iniciales: if numero % 2 == 0: numeros_pares.append(numero) print(numeros_pares) ¿Cuál será la salida exacta que se mostrará en la consola?',
    '[10, 44, 88]',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:20:35.087Z',
    '2025-11-06T19:20:35.087Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '80d113c0-bd0a-48f6-8bb2-46c42eed55b7',
    'A continuación se presenta una función diseñada para analizar una frase y devolver un resumen en un diccionario. def analizar_frase(frase): num_caracteres = len(frase) num_palabras = len(frase.split()) num_vocales = 0 for caracter in frase.lower(): if caracter in aeiou: num_vocales += 1 return { num_caracteres: num_caracteres, num_palabras: num_palabras, num_vocales: num_vocales } # Llamada a la función reporte = analizar_frase(Hola Mundo) print(reporte) ¿Cuál será la salida exacta generada por la llamada a la función con la frase Hola Mundo?',
    '{num_caracteres: 10, num_palabras: 2, num_vocales: 4}',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:20:59.196Z',
    '2025-11-06T19:20:59.196Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '620a6db0-abf2-4af9-84b6-d65e41603655',
    '¿Cuál es la principal diferencia semántica entre una petición HTTP GET y una POST?',
    'GET es para recuperar recursos existentes sin cambiar el estado del servidor, mientras que POST es para enviar datos nuevos al servidor para que realice una acción.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:21:29.146Z',
    '2025-11-06T19:21:29.146Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '7457e1cd-9f9f-4282-bf06-2817bc083cd7',
    'Un analista compara la distribución de la variable Tiempo_Respuesta para dos grupos, A y B. Al crear boxplots, observa que son casi idénticos en cuanto a su mediana, rango intercuartílico y bigotes. Sin embargo, al crear violin plots para los mismos datos, nota que el gráfico del Grupo A es ancho en el centro y delgado en los extremos (unimodal), mientras que el del Grupo B tiene dos bultos separados, uno en la parte inferior y otro en la superior (bimodal). ¿Qué revela esta discrepancia sobre la ventaja fundamental de un violin plot?',
    'El boxplot puede ocultar la estructura subyacente de la distribución de los datos, como la bimodalidad, mientras que el violin plot la visualiza a través de su forma de densidad.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:22:10.734Z',
    '2025-11-06T19:22:10.734Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '7b660993-e8e3-4915-9bce-3b5dc8636a7a',
    'En FastAPI, ¿qué es un decorador de operación de ruta (path operation decorator)?
Una sintaxis especial como @app.get(/) que asocia una URL y un método HTTP a la función de Python que se encuentra justo debajo.',
    'Una sintaxis especial como @app.get(/) que asocia una URL y un método HTTP a la función de Python que se encuentra justo debajo.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    '2025-11-06T19:51:21.356Z',
    '2025-11-06T19:58:05.929Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '47b91071-ab20-4525-a43c-e2134b94bc05',
    'Estás construyendo una llamada a una API para buscar datos y necesitas pasar parámetros de consulta (query parameters) para que la URL final sea .../search?category=Technology&in_stock=true. ¿Cuál es la forma más segura y recomendada de hacer esto con la librería requests?',
    'requests.get(URL, params={category: Technology, in_stock: true})',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    '2025-11-06T19:51:43.533Z',
    '2025-11-06T19:57:36.736Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'bf8db63f-e566-4034-8846-2792e5edc5d6',
    'Tienes una columna Precio en tu DataFrame que es de tipo object porque contiene el símbolo $ (ej: $19.99). Quieres convertirla a un tipo numérico float. ¿Cuál es la secuencia de operaciones correcta y más eficiente?',
    'Usar .str.replace($, ) para eliminar el símbolo y luego encadenar .astype(float) para convertir el tipo.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    '2025-11-06T19:52:00.350Z',
    '2025-11-06T19:53:40.177Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '678ea75a-b94f-48fb-9812-5790a88e5d94',
    'Un DataFrame df tiene 100 filas. Después de ejecutar df_limpio = df.dropna(), el nuevo DataFrame df_limpio tiene 80 filas. ¿Qué se puede concluir con certeza sobre el DataFrame original df?',
    '20 de sus filas contenían al menos un valor NaN',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:52:57.064Z',
    '2025-11-06T19:52:57.064Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'b58c93e3-5c33-4078-9c45-701ad6ed0248',
    'Considerando el modelo de ejecución de rerun de Streamlit, ¿por qué es una práctica común colocar la carga de datos (ej: pd.read_csv(...)) dentro de una función decorada con @st.cache_data?',
    'Para evitar que los datos se vuelvan a cargar desde el disco en cada interacción del usuario, mejorando drásticamente el rendimiento de la aplicación.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:54:10.224Z',
    '2025-11-06T19:54:10.224Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '18078616-3069-4a9b-8c0f-297a2f60d68c',
    'En FastAPI, ¿qué rol cumple una clase que hereda de pydantic.BaseModel cuando se usa en un endpoint POST?',
    'Define la estructura, los tipos de datos y las validaciones para los datos JSON que se esperan en el cuerpo (body) de la petición.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:54:48.525Z',
    '2025-11-06T19:54:48.525Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '533f5e8e-3de0-441e-8ebc-a1e2aac4d412',
    'Un desarrollador quiere servir una predicción de clustering. El modelo kmeans_model fue entrenado para segmentar clientes. El endpoint POST recibe los datos de un nuevo cliente. ¿Qué devolverá la llamada kmeans_model.predict(new_customer_data)?',
    'Un número entero que representa el ID del clúster o segmento al que pertenece el nuevo cliente.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:55:32.657Z',
    '2025-11-06T19:55:32.657Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '02bd4001-129e-4838-a91f-f20be8acbb10',
    'Considerando el ciclo de vida de un modelo de ML en un entorno de producción, ¿cuál de las siguientes afirmaciones es la más acertada?',
    'El entrenamiento es un proceso computacionalmente costoso que se realiza offline, y la API solo se encarga de cargar el modelo guardado y ejecutar la operación de predicción, que es muy rápida.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T19:56:09.199Z',
    '2025-11-06T19:56:09.199Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '5e041950-3d95-420e-acaa-08c1b2df02c4',
    '¿Cuál es el propósito principal del archivo requirements.txt en un proyecto de Python?',
    'Lista las librerías y sus versiones exactas necesarias para que el proyecto funcione, permitiendo a otros replicar el entorno.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:07:35.492Z',
    '2025-11-06T20:07:35.492Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '05545145-6de6-489e-b3f0-a2a96b2e63fe',
    'La siguiente función es_palindromo está diseñada para determinar si una frase es un palíndromo (se lee igual de izquierda a derecha que de derecha a izquierda), ignorando espacios y diferencias entre mayúsculas y minúsculas. def es_palindromo(frase): frase_limpia = frase.replace( , ).lower() return frase_limpia == frase_limpia[::-1] resultado = es_palindromo(Anita lava la tina) print(resultado) Considerando los pasos de limpieza y la comparación con la versión invertida, ¿cuál será la salida exacta que se imprimirá en la consola?',
    'True',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:07:52.532Z',
    '2025-11-06T20:07:52.532Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '7a5a77da-cd80-4769-98d6-8b327151c9ae',
    '¿Cuál es la relación fundamental entre las librerías Seaborn y Matplotlib?',
    'Seaborn está construida sobre Matplotlib y la utiliza para crear gráficos estadísticos más atractivos con menos código.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:08:14.347Z',
    '2025-11-06T20:08:14.347Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'ca87f045-9785-4f76-9dd6-fc398946f9c0',
    'Un estudiante ejecuta el siguiente código para calcular la suma de dos números: num1 = input(Ingrese el primer número: ) #el usuario ingresa 10 num2 = input(Ingrese el segundo número: ) #el usuario ingresa 5 suma = num1 + num2 print(fEl resultado es: {suma}) Al ejecutarlo, la consola muestra: El resultado es: 105. ¿Cuál es la descripción técnica más precisa de por qué ocurre este comportamiento?',
    'La función input() retorna valores de tipo str, y el operador + para strings realiza una operación de concatenación.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:08:40.972Z',
    '2025-11-06T20:08:40.972Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '433a380a-5666-4de9-899f-d88722762445',
    '¿Cuál es la diferencia fundamental entre pd.merge() y pd.concat()?',
    'merge une DataFrames basándose en los valores de una o más columnas clave, mientras que concat los apila por filas o los pega por columnas.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:09:04.771Z',
    '2025-11-06T20:09:04.771Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'c1fc60ef-2e0f-4f9a-b3b0-9c4294939c59',
    'Un DataFrame df_logs tiene una columna usuario_id. Quieres saber cuántas acciones realizó cada usuario. La columna de acciones, accion, tiene algunos valores nulos (NaN). ¿Qué comando te dará el conteo de todas las filas (acciones) por usuario, independientemente de si la acción es nula o no?',
    'df_logs.groupby(usuario_id).size()',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:09:36.652Z',
    '2025-11-06T20:09:36.652Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '558dca48-11b3-44af-be8e-38341812eba1',
    '¿Cuál es el principal beneficio de colocar los widgets de control (como selectbox y slider) dentro de st.sidebar?',
    'Libera espacio en la página principal y agrupa los controles en una ubicación lógica y consistente, mejorando la experiencia de usuario.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:09:59.231Z',
    '2025-11-06T20:09:59.231Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '6f852a52-e2c3-4fc8-8ed5-51cd4e2c9165',
    'Al seleccionar una única columna de un DataFrame de Pandas utilizando la sintaxis de corchetes, como en df[nombre_columna], ¿qué tipo de objeto devuelve Pandas por defecto?',
    'Un objeto Serie de Pandas.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:19:31.275Z',
    '2025-11-06T20:19:31.275Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '5c7bd900-5494-43e0-bdb1-d7bbe8acc864',
    'Tienes dos DataFrames: df_empleados (con ID_Empleado y Nombre) y df_salarios (con ID_Empleado y Salario). Quieres crear un nuevo DataFrame que contenga el nombre y el salario de todos los empleados que aparecen en la tabla df_empleados, sin importar si tienen un salario registrado en df_salarios. ¿Qué tipo de merge debes usar?',
    'pd.merge(df_empleados, df_salarios, on=ID_Empleado, how=left)',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:19:52.155Z',
    '2025-11-06T20:19:52.155Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '09b43f60-07ff-473b-898d-0d66bc04811f',
    'Quieres visualizar la relación entre dos variables numéricas, por ejemplo, el kilometraje de un auto y su precio. ¿Qué tipo de gráfico es el más adecuado para este propósito?',
    'Gráfico de dispersión (scatterplot)',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:20:06.150Z',
    '2025-11-06T20:20:06.150Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '2a0b8d5e-6663-480b-b3d6-ef7505b91b5f',
    'El siguiente script tiene como objetivo analizar una lista de estudiantes, donde cada estudiante es un diccionario con su nombre y una lista de sus notas. El propósito es encontrar el nombre del estudiante con el promedio de notas más alto. estudiantes = [ {nombre: Ana, notas: [90, 85, 88]}, # promedio: 87.66 {nombre: Luis, notas: [78, 80, 82]}, # promedio: 80.0 {nombre: Marta, notas: [95, 92, 97]} # promedio: 94.66 ] mejor_estudiante_nombre = max_promedio = 0.0 for estudiante in estudiantes: notas = estudiante[notas] promedio_actual = sum(notas) / len(notas) if promedio_actual > max_promedio: max_promedio = promedio_actual mejor_estudiante_nombre = estudiante[nombre] print(mejor_estudiante_nombre) Después de ejecutar el código, ¿qué nombre se imprimirá en la consola?',
    'Marta',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:20:24.614Z',
    '2025-11-06T20:20:24.614Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'ee29d2c1-aa5a-4402-8035-fde086732da6',
    '¿Cuál es el problema principal y fundamental que la tecnología de contenedores como Docker está diseñada para resolver en el desarrollo de software?',
    'La falta de consistencia de los entornos entre las máquinas de los desarrolladores y los servidores, encapsulando la aplicación y sus dependencias.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:20:42.147Z',
    '2025-11-06T20:20:42.147Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'cbdea823-9c2a-4636-af9e-4ff557f332bd',
    'Un desarrollador quiere obtener una visión general rápida de la salud de su dataset en cuanto a datos faltantes. En lugar de solo usar df.isnull().sum(), quiere una visualización que le muestre la distribución y la densidad de los valores nulos a lo largo de todo el DataFrame. ¿Qué gráfico de la librería missingno está diseñado específicamente para visualizar la completitud de los datos en cada fila, mostrando los datos presentes como líneas sólidas y los datos faltantes (NaN) como espacios en blanco?',
    'La matriz de nulos (msno.matrix)',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:42:02.926Z',
    '2025-11-06T20:42:02.926Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '6484e433-c53a-4ed2-8aee-709cc3fb7bf0',
    'Tu API tiene un endpoint GET /data. Tu dashboard de Streamlit tiene una función load_data() que llama a este endpoint. La función está decorada con @st.cache_data. Si un usuario selecciona un filtro en un widget que NO afecta a la llamada load_data(), ¿qué sucederá durante el rerun?',
    'Streamlit no llamará a la API; servirá el DataFrame directamente desde su caché de memoria.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:42:19.931Z',
    '2025-11-06T20:42:19.931Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '05447b04-e4d1-4764-b7e9-3cfb54998ded',
    'Quieres mostrar un mensaje de éxito al usuario después de que una operación de carga de datos se completa correctamente. ¿Qué comando de Streamlit usarías para mostrar un cuadro verde con un ícono de check?',
    'st.success(Datos cargados correctamente.)',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:42:32.780Z',
    '2025-11-06T20:42:32.780Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '3cf06a4c-6d1e-445b-9299-0b551ddc3115',
    'Un analista crea un gráfico con Seaborn: sns.histplot(data=df, x=Edad). Luego, quiere añadirle un título al gráfico. ¿Cuál es el código correcto para hacerlo?',
    'plt.title(Distribución de Edades)',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:42:50.038Z',
    '2025-11-06T20:42:50.038Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '26f04fd6-654d-4b4d-a9e2-55a9a558fe9b',
    'Un desarrollador está construyendo un dashboard que carga un archivo CSV de 100 MB. Para optimizar el rendimiento, encapsula la lógica de carga en una función y utiliza el decorador @st.cache_data. import streamlit as st import pandas as pd import time @st.cache_data def load_heavy_data(): time.sleep(5) df = pd.read_csv(mi_archivo_pesado.csv) return df st.title(Dashboard Optimizado) df = load_heavy_data() st.dataframe(df) if st.button(Actualizar Vista): st.write(Vista actualizada.) Un usuario abre la aplicación por primera vez y espera 5 segundos para que los datos se carguen y se muestre el DataFrame. Luego, el usuario hace clic en el botón Actualizar Vista. ¿Cuál será el comportamiento de la aplicación en este segundo rerun?',
    'La aplicación se actualizará instantáneamente (sin los 5 segundos de espera), porque @st.cache_data recuperará el DataFrame guardado en la memoria caché en lugar de volver a ejecutar el cuerpo de la función.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:43:05.347Z',
    '2025-11-06T20:43:05.347Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'a41ec833-54da-459c-857e-eb4fb1959cd3',
    '¿Cuál es la principal ventaja de usar Plotly Express en lugar de Seaborn para un dashboard que será presentado a un usuario final?',
    'Los gráficos de Plotly son interactivos, mejorando la experiencia del usuario.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:49:24.794Z',
    '2025-11-06T20:49:24.794Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '67dc2637-2738-48bc-adc9-ff2278dd0815',
    'El siguiente bucle while fue diseñado para imprimir los números del 1 al 5, pero contiene un error que provoca un bucle infinito. contador = 1 while contador <= 5: print(contador) ¿Qué línea de código falta dentro del bucle para corregir el error?',
    'contador = contador + 1',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-06T20:49:45.771Z',
    '2025-11-06T20:49:45.771Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '2e606f85-635a-4803-b2e9-e888fbc58761',
    'El siguiente programa implementa un bucle que repite la entrada del usuario en mayúsculas y solo se detiene bajo una condición específica. while True: entrada = input(Di algo: ) if entrada.lower() == salir: break print(entrada.upper()) ¿Cuál de las siguientes entradas del usuario hará que el bucle while termine exitosamente?',
    'SALIR',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-07T00:52:02.128Z',
    '2025-11-07T00:52:02.128Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '37c509fb-d211-46fd-94fa-1149b68cef79',
    '¿Cuál es una de las características más destacadas de FastAPI que acelera el desarrollo y las pruebas de una API?',
    'La generación automática de documentación interactiva accesible por defecto en las rutas /docs y /redoc.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-07T03:00:12.105Z',
    '2025-11-07T03:00:12.105Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'c5c5ba51-8475-4c82-91d8-19e2f6628601',
    'Un nuevo desarrollador se une a tu equipo y clona el repositorio del proyecto desde GitHub. El proyecto utiliza varias librerías, incluyendo Pandas, NumPy y FastAPI. Al intentar ejecutar el pipeline de datos por primera vez, recibe el siguiente error: ModuleNotFoundError: No module named pandas. A pesar de que el código es correcto y funciona en las máquinas de los demás, ¿cuál es el paso más probable que el nuevo desarrollador olvidó realizar después de clonar el repositorio y activar su entorno virtual?',
    'Ejecutar pip install -r requirements.txt para instalar todas las dependencias del proyecto de una sola vez.',
    '8f326af4-a019-4b80-8ada-a2750ce4104a',
    NULL,
    '2025-11-07T05:49:14.729Z',
    '2025-11-07T05:49:14.729Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    'f5444e63-04bb-4b5e-a9ca-2df7d21723ae',
    '¿En qué escenario es más apropiado usar el método .apply() en lugar de una operación vectorizada (como +, -) o np.where?',
    'Cuando la lógica para crear la nueva columna es compleja y no puede ser expresada fácilmente con operaciones estándar, requiriendo una función personalizada',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-07T18:08:02.150Z',
    '2025-11-07T18:08:02.150Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO preguntas (id, pregunta, respuesta_correcta, creado_por, modificado_por, created_at, updated_at) VALUES (
    '03b74c52-1a97-46c1-a095-918f09161c66',
    'Un analista está realizando un Análisis Exploratorio de Datos (EDA) sobre un dataset. Ya ha realizado los pasos de limpieza y feature engineering. Ahora se encuentra en la fase de visualización y descubrimiento de insights. ¿Cuál de las siguientes acciones representa mejor una aplicación madura y efectiva del ciclo de EDA en esta fase?',
    'Empezar con una pregunta de negocio específica, elegir el gráfico adecuado para responderla, y usar el resultado para formular la siguiente pregunta',
    '80d3991a-3086-4b52-9a25-9f390e3056cb',
    NULL,
    '2025-11-07T18:18:36.758Z',
    '2025-11-07T18:18:36.758Z'
) ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- DATOS DE CONFIGURACIÓN
-- =====================================================

INSERT INTO config (key, value, created_at) VALUES (
    'delete_enabled',
    '{"enabled":false}'::jsonb,
    '2025-11-11T03:52:53.754Z'
) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO config (key, value, created_at) VALUES (
    'edit_enabled',
    '{"enabled":false}'::jsonb,
    '2025-11-11T03:52:53.751Z'
) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO config (key, value, created_at) VALUES (
    'export_excel',
    '{"enabled":false}'::jsonb,
    '2025-11-06T18:15:39.277Z'
) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO config (key, value, created_at) VALUES (
    'export_pdf',
    '{"enabled":false}'::jsonb,
    '2025-11-06T18:15:39.273Z'
) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- =====================================================
-- ESTADÍSTICAS DEL BACKUP
-- =====================================================
-- Total de usuarios: 3
-- Total de preguntas: 102
-- Total de configuraciones: 4
-- Fecha de backup: 2025-11-11T03:53:10.904Z
-- =====================================================

SELECT COUNT(*) as total_usuarios FROM usuarios;
SELECT COUNT(*) as total_preguntas FROM preguntas;
SELECT COUNT(*) as total_configs FROM config;
