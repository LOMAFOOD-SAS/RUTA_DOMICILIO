# Flujo de Power Automate

Este documento describe cómo el archivo `ruta-YYYY-MM-DD.html` termina como correo en la bandeja de `pedidos@lomafood.com`.

## Diagrama (alto nivel)

```
┌──────────────────────────┐
│ Cowork (Claude desktop)  │   4:30 PM diario
│  tarea: ruta-diaria-loma │
└────────────┬─────────────┘
             │ escribe
             ▼
┌──────────────────────────┐
│ OneDrive — (08) Ruta/    │  ← carpeta privada de LOMAFOOD
│  ruta-2026-05-28.html    │
│  ruta-2026-05-28.json    │
└────────────┬─────────────┘
             │ trigger "Cuando se crea un archivo"
             ▼
┌──────────────────────────┐
│ Power Automate (flow)    │
│  - lee el .html          │
│  - lee el .json          │
│  - manda correo          │
└────────────┬─────────────┘
             │
             ▼
       pedidos@lomafood.com
```

## Trigger y acciones del flow

**Trigger:** "Cuando se crea un archivo (solo propiedades)" — OneDrive for Business
- Carpeta: la carpeta privada `(08) Ruta` (la ruta exacta depende del tenant — usar el selector de carpetas del conector OneDrive).
- Filtro de archivo: `ruta-*.html`

**Acciones (4 en total):**

1. **Obtener contenido del archivo** (el `.html`).
2. **Obtener archivo (propiedades)** del sidecar `.json` — derivar el nombre reemplazando `.html` por `.json`.
3. **Obtener contenido** del `.json` → parsear como JSON.
4. **Enviar correo (V2)** — Outlook:
   - Para: campo `to` del JSON (`pedidos@lomafood.com`)
   - Asunto: campo `subject` del JSON
   - Cuerpo: contenido del `.html` (con flag "Es HTML" activado)
   - Importancia: Normal

## Por qué se hace así (y no enviando desde Python)

- **Auditoría:** el correo aparece en "Enviados" del buzón corporativo. Si fuera desde un SMTP propio no quedaría rastro en Outlook.
- **Re-envío manual:** si el flow falla, alguien puede mandar el `.html` a mano abriéndolo y pegándolo en Outlook.
- **Sin credenciales en código:** Power Automate usa OAuth de la cuenta corporativa; el repo no necesita guardar contraseñas.
- **Fallback:** si Cowork se cae un día, el operador puede armar un `.html` manualmente y dejarlo en la carpeta — el flow lo manda igual.

## Cómo recrear el flow

1. Entrar a [make.powerautomate.com](https://make.powerautomate.com).
2. **Mis flujos → Nuevo flujo → Flujo de nube automatizado.**
3. Trigger: **"Cuando se crea un archivo (solo propiedades)"** (OneDrive for Business).
4. Configurar carpeta (la privada de la empresa) y filtro `ruta-*.html`.
5. Agregar las 4 acciones de la sección anterior.
6. Activar el flow.

## Cómo apagarlo temporalmente

Si vas de vacaciones y querés que NO mande correos:

- **Opción 1:** desactivar el flow en Power Automate (botón "Desactivar" arriba a la derecha).
- **Opción 2:** desactivar la tarea programada `ruta-diaria-lomafood` en Cowork. Sin entrada, no hay salida.

Ambas funcionan; la opción 2 es más limpia si querés ver el log de Power Automate cuando vuelvas.
