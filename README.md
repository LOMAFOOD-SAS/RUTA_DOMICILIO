# lomafood-ruta-diaria

Automatización diaria de la ruta de reparto de **LOMAFOOD** (Bogotá, Colombia).

[![Lint](https://img.shields.io/badge/status-active-brightgreen)](.github/workflows/lint.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Este repositorio es público

Contiene **únicamente código y datos de ejemplo ficticios**, publicados para transparencia interna y para que cualquier persona de LOMAFOOD pueda leer, entender y mejorar la automatización.

- ✅ **En el repo:** el script, plantilla vacía del Excel, ejemplos de salida, documentación.
- ❌ **Fuera del repo:** el Excel con los clientes reales, sus direcciones y coordenadas. Eso vive en la carpeta privada de OneDrive de la empresa:
  `OneDrive › LOMA › (01) Corporativo › (01) Operativo › (03) Tienda Movil › (08) Ruta › AA_RUTA DEL DIA.xlsx`

Si vas a colaborar y necesitás los datos reales, pedíselos al equipo de operaciones (`pedidos@lomafood.com`). No los subas al repo.

---

## Qué hace

Cada día a las **4:30 PM**, automatizado desde Cowork (Claude desktop):

1. **Lee** `AA_RUTA DEL DIA.xlsx` de la carpeta privada en OneDrive.
2. **Cruza** los clientes de mañana con un maestro de coordenadas y reglas de prioridad.
3. **Calcula** la ruta más corta ida-y-vuelta desde la bodega (Calle 77 #58-35, Bogotá).
4. **Respeta reglas** como "siempre primero", "prioritario", "último".
5. **Escribe** dos archivos en la misma carpeta:
   - `ruta-YYYY-MM-DD.html` — cuerpo del correo, en HTML.
   - `ruta-YYYY-MM-DD.json` — sidecar con destinatario, asunto, distancia, URL de Google Maps.
6. Un flujo de **Power Automate** vigila la carpeta y **envía el correo** a `pedidos@lomafood.com`.

No hace llamadas a internet — las coordenadas vienen del Excel. La distancia es haversine (línea recta), no distancia real de calle.

---

## Estructura

```
lomafood-ruta-diaria/
├── README.md                   ← este archivo
├── CLAUDE.md                   ← instrucciones para Claude/Cowork en este repo
├── LICENSE                     ← MIT (código), datos reales fuera del repo
├── .gitignore                  ← excluye xlsx reales y outputs operativos
├── requirements.txt            ← openpyxl
├── init-repo.sh / .ps1         ← bootstrap para subir a GitHub
├── src/
│   └── build_route.py          ← el script principal
├── templates/
│   └── AA_RUTA_DEL_DIA_TEMPLATE.xlsx   ← estructura del Excel, con 3 clientes ficticios
├── examples/
│   ├── README.md               ← cómo regenerar los ejemplos
│   ├── sample-ruta.html        ← cómo se ve el correo enviado
│   └── sample-ruta.json        ← cómo se ve el sidecar
├── docs/
│   ├── SKILL.md                ← definición de la tarea programada de Cowork
│   ├── POWER_AUTOMATE.md       ← cómo está armado el flow del correo
│   └── TROUBLESHOOTING.md      ← errores comunes y soluciones
└── .github/workflows/
    └── lint.yml                ← chequeo de sintaxis Python en cada push
```

---

## Quick start (probar el ejemplo)

```bash
git clone https://github.com/TU_USUARIO/lomafood-ruta-diaria.git
cd lomafood-ruta-diaria
python3 -m venv .venv
source .venv/bin/activate              # Windows PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements.txt

python3 src/build_route.py \
    --xlsx templates/AA_RUTA_DEL_DIA_TEMPLATE.xlsx \
    --out  examples/ \
    --date 2026-06-01 \
    --recipient ejemplo@lomafood.com
```

Eso te regenera `examples/sample-ruta.html` y `examples/sample-ruta.json` a partir de la plantilla con tres clientes ficticios.

---

## Cómo funciona en producción

La diferencia con el modo ejemplo es que no se pasa `--xlsx`: el script busca automáticamente el Excel real con un glob que apunta a la carpeta de OneDrive montada en Cowork.

```bash
python3 src/build_route.py     # detecta /sessions/*/mnt/(08) Ruta/AA_RUTA DEL DIA.xlsx
```

Cowork dispara este comando diariamente a las 4:30 PM. Ver `docs/SKILL.md` para la definición exacta de la tarea programada.

---

## Cambiar parámetros

| Flag | Default | Para qué |
|---|---|---|
| `--xlsx` | (autodetectado en Cowork) | Ruta al `.xlsx` fuente |
| `--out` | misma carpeta del xlsx | Dónde escribir los outputs |
| `--origin` | `Calle 77 #58-35, Bogota, Colombia` | Dirección de la bodega |
| `--origin-coords` | `4.6685,-74.0589` | Coordenadas de la bodega |
| `--max-km` | `70.0` | Umbral para mostrar la advertencia de ruta larga |
| `--recipient` | `pedidos@lomafood.com` | Email destino en el JSON |
| `--date` | mañana | Fecha objetivo, formato `YYYY-MM-DD` |

---

## Formato del Excel

Mirá `templates/AA_RUTA_DEL_DIA_TEMPLATE.xlsx` para el layout exacto. Resumen:

**Hoja `Sheet1`** — clientes del día (lo llena el operador cada tarde):

| Fila | Columna A (Cliente) | Columna B (Dirrecion) | Columna C (CITY) | Columna D (RULE) |
|---|---|---|---|---|
| 1 | (fecha informativa) | | | |
| 2 | Cliente | Dirrecion | CITY | RULE |
| 3+ | nombre exacto | dirección (informativa) | ciudad | regla opcional |

**Hoja `DATA VALIDATION`** — maestro de clientes (columnas B-F desde la fila 2):

| Columna | Contenido |
|---|---|
| B - CLIENTE | Nombre exacto del cliente |
| C - DIRRECION DE ENTREGA | Dirección copiada de Google Maps |
| D - Latitude and longitude | `lat, lng` en una sola celda |
| E - CUIDAD | Ciudad / municipio |
| F - REGLAS | Vacío, `siempre primero`, `prioritario`, `ultimo`, etc. |

---

## Cómo subir este repo a GitHub (primera vez, para mantenedores)


> ⚠️ **Importante: no inicialices el repo git dentro de OneDrive.** OneDrive interfiere con los archivos de Git y rompe el commit. Antes de correr los comandos de abajo, **copiá la carpeta `repo-lomafood-ruta-diaria/` a un lugar fuera de OneDrive** (por ejemplo `C:\Users\TuUsuario\Documents\`). Hacé `git init` ahí.

### Pasos

1. **Crear el repo VACÍO en GitHub:**
   - Andá a https://github.com/new
   - Nombre: `lomafood-ruta-diaria`
   - Visibilidad: **Público**
   - **NO** marcar "Add a README", "Add .gitignore", ni "Choose a license" — ya están acá.
   - Click "Create repository".

2. **Copiá la URL del repo nuevo** (algo como `https://github.com/tu-usuario/lomafood-ruta-diaria.git`).

3. **Correr el script de bootstrap:**

   En **Windows PowerShell**:
   ```powershell
   cd "ruta\a\la\carpeta\repo-lomafood-ruta-diaria"
   .\init-repo.ps1 -RemoteUrl "https://github.com/TU_USUARIO/lomafood-ruta-diaria.git"
   ```

   En **macOS / Linux / Git Bash**:
   ```bash
   cd /ruta/a/la/carpeta/repo-lomafood-ruta-diaria
   ./init-repo.sh "https://github.com/TU_USUARIO/lomafood-ruta-diaria.git"
   ```

4. **Listo.** GitHub te va a pedir credenciales la primera vez (token de acceso personal o GitHub CLI).

### A mano (sin script)

```bash
cd /ruta/al/repo
git init -b main
git add .
git commit -m "Initial commit: LOMAFOOD daily route automation"
git remote add origin https://github.com/TU_USUARIO/lomafood-ruta-diaria.git
git push -u origin main
```

### Actualizaciones futuras

```bash
git add .
git commit -m "Descripción del cambio"
git push
```

---

## Convenciones

- El script borra solo los `ruta-YYYY-MM-DD.*` con más de 14 días.
- Nunca modifica el Excel original.
- Si el Excel está corrupto (`BadZipFile`), **no** escribe nada — eso es a propósito, para que Power Automate no mande un correo basura. Solución en `docs/TROUBLESHOOTING.md`.

---

## Licencia

MIT, ver `LICENSE`. El código se puede reusar libremente. Los **datos operativos reales** de LOMAFOOD (clientes, direcciones, coordenadas) **no** se distribuyen bajo esta licencia — son privados.

---

## Contacto

- **Operaciones:** pedidos@lomafood.com
- **Issues / Sugerencias:** [abrir un issue en GitHub](https://github.com/TU_USUARIO/lomafood-ruta-diaria/issues)
