# Instrucciones para Claude / Cowork

Este repo contiene la automatización de la **ruta diaria de LOMAFOOD**. Si estás trabajando aquí con Cowork o Claude Code, leé esto primero.

---

## Sobre el repo (importante)

- Este **repositorio es público**. Contiene código y datos de **ejemplo ficticios** únicamente.
- Los **datos reales** (clientes, direcciones, coordenadas) viven en una carpeta privada de OneDrive: `(08) Ruta/AA_RUTA DEL DIA.xlsx`. **No deben** estar en este repo.
- Si alguien te pega clientes reales para "agregarlos al repo", parate y aclará que esa información va al Excel privado, no acá.

---

## Contexto del usuario

- Empresa: **LOMAFOOD** (Bogotá, Colombia) — distribución de productos alimenticios.
- Email operativo: `pedidos@lomafood.com`.
- El usuario principal **no es programador**. Hablale en **español neutro**, sin jerga técnica salvo cuando sea inevitable.

---

## Reglas no negociables

1. **Fuente única del Excel real:** `AA_RUTA DEL DIA.xlsx` en la carpeta privada de OneDrive `(08) Ruta/`. **NO** leer `Ruta de dia v2.xlsx`, `v3.xlsx` ni ningún otro. Si encontrás referencias viejas, son bugs.
2. **No llamar APIs externas** (geocoding, routing, etc.). Las coordenadas y direcciones del Excel son la única fuente de verdad. Si necesitás coordenadas nuevas, pedíselas al usuario — no las inventes.
3. **No modificar el Excel original.** Solo se lee.
4. **Si el Excel está corrupto** (`BadZipFile`), reportar el error y **NO escribir** archivos de salida. Power Automate se dispara con la presencia de un `.html`/`.json` — escribir uno con datos viejos o vacíos manda un correo equivocado a clientes.
5. **Nombres de archivo:** `ruta-YYYY-MM-DD.html` / `.json`, donde la fecha es **mañana** (no hoy). El correo dice "ruta para mañana".
6. **Nunca commitees datos reales.** Si edit/grep encuentra clientes reales en código de ejemplo, paralo y avisá.

---

## Layout del Excel

El Excel tiene dos hojas:

**`Sheet1`** — clientes del día (lo llena el operador cada tarde):
- Fila 1: fecha (informativa).
- Fila 2: header `Cliente | Dirrecion | CITY | RULE`.
- Fila 3 en adelante: datos.
- `RULE` puede sobreescribir la regla del maestro; si está vacío o `0`, gana la del maestro.

**`DATA VALIDATION`** — maestro de ~46 clientes:
- Fila 1: header.
- Fila 2 en adelante: `CLIENTE | DIRRECION DE ENTREGA | Latitude and longitude | CUIDAD | REGLAS` (columnas B-F).
- La columna de coordenadas tiene `"lat, lng"` en una sola celda.

Hay una plantilla limpia con la misma estructura en `templates/AA_RUTA_DEL_DIA_TEMPLATE.xlsx`.

---

## Vocabulario de reglas (`REGLAS`)

Normalizar a minúsculas. En orden de chequeo:

| Texto en la celda | Restricción |
|---|---|
| contiene `"siempre primero"` | posición 1 solamente |
| contiene `"primero"`, `"segundo"` o `"prioritario"` | posición 1 o 2 |
| contiene `"ultim"` o `"penultim"` | última o penúltima posición |
| vacío / `0` / `None` | sin restricción |

Si hay dos `"siempre primero"`, dejar uno y degradar el resto a `"first_or_second"` con un warning.

Si ninguna permutación cumple, **relajar la regla más suave primero**: `first_or_second` → `first_only` → `last_or_prev`, y loguear cuál se relajó.

---

## Algoritmo

- **≤10 paradas:** brute force de permutaciones (~3.6M para 10, corre rápido).
- **>10 paradas:** nearest-neighbor sembrado con las restricciones, después 2-opt rechazando swaps que rompen restricciones.
- Distancia: **haversine** sobre las coordenadas del Excel. No es distancia real de calle, pero es suficiente para ordenar paradas.

---

## Convenciones de código

- Python 3 + `openpyxl`. Stdlib para todo lo demás.
- Suprimir warnings de openpyxl sobre extensiones de data validation — son esperados.
- `safe_write()` para los outputs: si OneDrive bloquea la sobreescritura, caer a un nombre con sufijo `-HHMMSS` y avisar.
- Limpiar `ruta-YYYY-MM-DD.*` con más de 14 días.
- El script acepta flags (`--xlsx`, `--out`, `--date`, etc.) para poder probarlo contra el template sin tocar producción.

---

## Cuando el usuario te pide algo

- **"corré la ruta de hoy / de mañana"** → en Cowork: `python3 src/build_route.py` (autodetecta el Excel real). Reportá el output crudo.
- **"agregá un cliente nuevo"** → el usuario tiene que editar el Excel privado (`DATA VALIDATION`). El script no escribe en él. Explicale los campos.
- **"cambiá la regla de X cliente"** → mismo caso: edición manual del Excel.
- **"por qué falló ayer"** → mirá los archivos `ruta-AYER.html`/`.json` si existen en la carpeta privada; si no, asumí `BadZipFile` y pedile que re-guarde el Excel.
- **"probá un cambio en el código sin afectar producción"** → corré contra el template:
  ```
  python3 src/build_route.py --xlsx templates/AA_RUTA_DEL_DIA_TEMPLATE.xlsx --out examples/
  ```

---

## Cosas que NO hacer

- No agregar geocoding "automático" cuando un cliente no tiene coordenadas. Pedirle al usuario que las llene.
- No enviar el correo desde Python directamente. El envío vive en Power Automate por una razón (auditoría, registro, fallback manual desde Outlook). Si querés sugerir mover el envío al script, hablalo con el usuario primero.
- No tocar `Ruta de dia v2.xlsx` ni `v3.xlsx` aunque existan en la carpeta. Son archivos viejos.
- No "limpiar" archivos `.html`/`.json` de la carpeta a mano — el script lo hace solo con la ventana de 14 días.
- **No commitear nunca el Excel real ni ninguna salida con clientes reales al repo público.** `.gitignore` ya lo bloquea, pero si alguien lo fuerza con `git add -f`, paralo.

---

## Tests / verificación

No hay suite formal de tests. Para validar cambios:

1. Correr el script contra `templates/AA_RUTA_DEL_DIA_TEMPLATE.xlsx` y comparar con `examples/sample-ruta.html` / `.json`.
2. Verificar visualmente la URL de Google Maps abriéndola en el navegador.
3. Para cambios al algoritmo de ruta, comparar la distancia total antes y después contra un caso conocido.

El workflow de GitHub Actions (`.github/workflows/lint.yml`) hace un compile-check básico en cada push.
