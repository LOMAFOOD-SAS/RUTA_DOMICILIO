# Troubleshooting

Errores comunes y cómo arreglarlos.

> **Recordatorio:** los datos reales viven en la carpeta privada de OneDrive `(08) Ruta/`. Este repo solo tiene un template y ejemplos ficticios.

---

## 1. `BadZipFile: File is not a zip file`

**Síntoma:** El correo de las 4:30 PM no llega. Si revisás el log de Cowork, ves este error.

**Causa:** OneDrive truncó el `AA_RUTA DEL DIA.xlsx` mientras lo estaba sincronizando. El archivo existe en disco pero le falta el "End of Central Directory" del ZIP (un .xlsx es un ZIP por dentro).

**Cómo verificar:**
```bash
python3 -c "import zipfile; zipfile.ZipFile('AA_RUTA DEL DIA.xlsx').namelist()"
# Si lanza BadZipFile, está corrupto.
```

**Solución:**
1. Abrir el archivo en **Excel de escritorio** (no Excel Online).
2. `Archivo → Guardar como…` → mismo nombre, misma carpeta. Reemplazar al confirmar.
3. Esperar a que OneDrive termine de sincronizar (icono de check verde).
4. Re-disparar la tarea de Cowork manualmente o esperar al próximo run de 4:30 PM.

**Prevención:** evitar editarlo simultáneamente desde Excel de escritorio y Excel Online. Cerralo siempre antes de irte.

---

## 2. Archivos fantasma de SharePoint (`PermissionError` / `FileNotFoundError` al escribir)

**Síntoma:** En el log ves algo como:
```
WARN: ghost en ruta-2026-05-28.html (PermissionError); usando ruta-2026-05-28-163215.html
```

**Causa:** OneDrive dejó un `ruta-YYYY-MM-DD.html` del run anterior en un estado raro — `stat()` lo ve, pero no se puede abrir ni borrar. Suele pasar cuando se corre la tarea dos veces el mismo día o cuando hubo un conflicto de sync.

**Consecuencia:** Power Automate **no** se dispara con el nuevo archivo porque el filtro busca el nombre canónico `ruta-2026-05-28.html`, no `ruta-2026-05-28-163215.html`.

**Solución:**
1. Borrar manualmente desde el explorador (no desde Python) el archivo viejo `ruta-2026-05-28.html` y su `.json`.
2. Si el explorador también dice "no se puede borrar", entrar a OneDrive Web (onedrive.live.com), navegar a la carpeta y borrarlo desde ahí.
3. Después correr el script de nuevo — esta vez podrá escribir con el nombre canónico.

---

## 3. Un cliente nuevo no aparece en la ruta

**Síntoma:** Llenaste el cliente en `Sheet1` pero el correo no lo incluye.

**Causa más probable:** el cliente no está en `DATA VALIDATION` (la hoja maestra). El script loguea:
```
MISSING-FROM-MASTER: 'NombreCliente' no está en DATA VALIDATION; omitido.
```

**Solución:** agregalo al maestro con sus coordenadas. Pasos:

1. Abrir Google Maps, buscar la dirección del cliente, click derecho sobre el pin → copiar coordenadas (formato `lat, lng`, e.g. `4.6712, -74.0489`).
2. Copiar también la dirección **tal como Google la muestra** (con barrio).
3. En `DATA VALIDATION`, agregar una fila nueva al final con:
   - **CLIENTE:** mismo texto exacto que escribiste en Sheet1.
   - **DIRRECION DE ENTREGA:** la dirección de Google.
   - **Latitude and longitude:** `lat, lng` (con coma).
   - **CUIDAD:** Bogotá / Chía / etc.
   - **REGLAS:** vacío, o `"siempre primero"` / `"prioritario"` / `"ultim"` según corresponda.
4. Guardar el Excel.

---

## 4. La ruta excede 70 km

**Síntoma:** El correo incluye un párrafo rojo:
> ⚠️ ADVERTENCIA: La ruta excede 70 km. Considere dividir la ruta.

**Qué hacer:** la advertencia no impide el envío — solo te avisa. Opciones:
- Si tenés tiempo, dividí la ruta en dos días.
- Si no, ignorá la advertencia y manejá. El correo igual llega con la lista completa.

**Por qué pasa:** generalmente cuando hay un cliente en una ciudad lejana (Chía, Cota, Mosquera, etc.) en el mismo día que muchos de Bogotá.

---

## 5. Power Automate no manda el correo

**Síntoma:** el `ruta-YYYY-MM-DD.html` existe en OneDrive pero el correo no llegó.

**Cómo diagnosticar:**

1. Entrar a [make.powerautomate.com](https://make.powerautomate.com) → Mis flujos.
2. Buscar el flow "Enviar ruta diaria LOMAFOOD".
3. Click en el flow → ver el historial de ejecuciones.
4. Si el último intento dice "Falló", click para ver qué paso falló.

**Causas comunes:**
- El flow está desactivado. Botón "Activar".
- La conexión a OneDrive caducó. Hay que re-autenticar (Power Automate lo pide explícitamente).
- El filtro del trigger no matchea — verificá que sea `ruta-*.html` (no `.htm`).

---

## 6. Las coordenadas del Excel son incorrectas

**Síntoma:** la ruta optimizada cruza la ciudad de un lado al otro sin sentido.

**Causa:** una coordenada quedó tipeada al revés (`lng, lat` en vez de `lat, lng`), o se escribió con coma decimal en lugar de punto.

**Cómo detectar:** abrir Google Maps y pegar el contenido de la celda `Latitude and longitude` del cliente sospechoso. Si te lleva a un lugar muy distinto de la dirección, está mal.

**Formato correcto:**
- ✅ `4.6712, -74.0489` (lat, lng con punto decimal)
- ❌ `-74.0489, 4.6712` (lng, lat)
- ❌ `4,6712, -74,0489` (comas decimales — no funcionan)

---

## 7. Quiero probar el script sin esperar a las 4:30 PM

Tenés dos opciones:

**A) Contra el template del repo (no afecta producción):**
```bash
python3 src/build_route.py \
    --xlsx templates/AA_RUTA_DEL_DIA_TEMPLATE.xlsx \
    --out  examples/ \
    --date 2026-06-01
```

**B) Contra el Excel real desde Cowork:** decile a Claude/Cowork:
> "Corré la ruta para mañana ahora"

El script genera el `ruta-YYYY-MM-DD.html`/`.json` en la carpeta privada de OneDrive, y Power Automate lo agarra dentro de 1-5 minutos.

Si no querés que se mande el correo de prueba, primero desactivá el flow en Power Automate, corré el script, revisá el archivo, y volvé a activar el flow después.
