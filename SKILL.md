# SKILL.md — Tarea programada `ruta-diaria-lomafood`

Esta es la definición de la tarea programada de Cowork que dispara la automatización cada día a las 4:30 PM. Si recreás la tarea en otra máquina, este es el texto que va en el `SKILL.md` de la tarea.

---

You are generating the daily delivery route for LOMAFOOD. Execute these steps autonomously every day at 4:30 PM.

## Objective
Read tomorrow's client list from an Excel file, look up each client's saved coordinates and exact Google address in the master reference sheet, build the shortest round-trip driving route that starts and ends at the LOMAFOOD warehouse, and write a ready-to-send HTML file plus a sidecar JSON file into OneDrive. A Power Automate flow watches that folder and will send the email to pedidos@lomafood.com automatically.

## Fixed parameters
- **Origin / Destination (round trip):** Calle 77 #58-35, Bogota, Colombia
- **Excel filename:** `AA_RUTA DEL DIA.xlsx` inside the `(08) Ruta/` OneDrive folder. Resolve the full path at runtime with a glob like `/sessions/*/mnt/(08) Ruta/AA_RUTA DEL DIA.xlsx`.
- **Daily sheet:** `Sheet1`. Columns: `Cliente`, `Dirrecion`, `CITY`, `RULE`. Row 1 is a date stamp, row 2 is the header, data starts row 3.
- **Master reference sheet:** `DATA VALIDATION`. Columns B..F: `CLIENTE`, `DIRRECION DE ENTREGA`, `Latitude and longitude` (a single cell with `"lat, lng"`), `CUIDAD`, `REGLAS`. Data starts row 2.
- **Output folder:** the same `(08) Ruta/` folder as the Excel.
- **Max route distance:** 70 km.
- **File-naming date:** **tomorrow's date** (ISO `YYYY-MM-DD`).

## Rule vocabulary (REGLAS)
Normalize the rule string to lowercase. Classify:
- contains `"siempre primero"` → **position 1 only**
- else contains `"primero"`, `"segundo"`, or `"prioritario"` → **position 1 or 2**
- else contains `"ultim"` or `"penultim"` → **last or second-to-last position**
- empty / `"0"` / None → no constraint

Precedence: if `Sheet1.RULE` is a non-empty, non-zero string, use it; otherwise use `DATA VALIDATION.REGLAS`.

If multiple clients both demand `"siempre primero"`, demote all but one to `"first_or_second"` and log a warning.

## Steps

1. Load the workbook with `openpyxl.load_workbook(path, data_only=True)`. Suppress openpyxl warnings.
2. Build master lookup from `DATA VALIDATION` (key = `cliente.strip().lower()`).
3. Read today's clients from `Sheet1` starting row 3. Skip empty cliente or `direccion in (None, "", 0, "0")`. Log missing-from-master clients.
4. If today's list is empty, write `ruta-{iso_date}.SKIP` and exit. No HTML/JSON.
5. Optimize the route:
   - ≤10 stops: brute force permutations.
   - >10 stops: nearest-neighbor + 2-opt, respecting constraints.
   - Relax soft rules in order: `first_or_second` → `first_only` → `last_or_prev`. Log relaxations.
6. Build Google Maps URL with `urllib.parse.quote` on every address.
7. Tomorrow's date for filename and display date inside the email.
8. Write `ruta-{iso_date}.html` (template in `src/build_route.py`).
9. Write `ruta-{iso_date}.json` sidecar (to, subject, distance_km, stops, exceeds_limit, google_maps_url, html_file).
10. Delete `ruta-YYYY-MM-DD.*` older than 14 days.
11. Report stops, total km, exceeds_limit, warnings, paths, URL.

## Constraints
- Never exceed 70 km silently — include warning paragraph in HTML.
- No network calls. Excel is the only source of truth.
- Don't modify the Excel.
- File names: lowercase ISO with **tomorrow's** date.
- Use Python stdlib + `openpyxl`.

## If the Excel file is unreadable
If `openpyxl.load_workbook` fails with `BadZipFile`:
1. Report the error.
2. Do NOT write any output files.
3. Tell the user to re-save the Excel from desktop Excel (Save As).
