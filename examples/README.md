# Ejemplos

Estos archivos son la salida del script corriendo contra `templates/AA_RUTA_DEL_DIA_TEMPLATE.xlsx`. Los tres clientes son **ficticios** y las direcciones se inventaron — sirven solo para mostrar el formato.

## Archivos

| Archivo | Qué es |
|---|---|
| `sample-ruta.html` | El cuerpo del correo que Power Automate envía. Abrilo en un navegador para ver cómo se ve. |
| `sample-ruta.json` | El sidecar con metadata (destinatario, asunto, distancia, URL de Google Maps). |

## Reproducirlos

Desde la raíz del repo:

```bash
python3 src/build_route.py \
    --xlsx templates/AA_RUTA_DEL_DIA_TEMPLATE.xlsx \
    --out  examples/ \
    --date 2026-06-01 \
    --recipient ejemplo@lomafood.com
```

Eso te debería regenerar exactamente los mismos archivos (la URL es determinística porque las coordenadas y reglas vienen del template).

## Resultado esperado

3 clientes, ~14.7 km, no excede el límite de 70 km. Orden:

1. **Cliente Ejemplo Dos** (regla `prioritario` → posición 1 o 2)
2. **Cliente Ejemplo Uno** (sin regla)
3. **Cliente Ejemplo Tres** (regla `ultimo` → última o penúltima posición)

Si cambiás el template y agregás más clientes o cambiás reglas, el orden y la distancia van a cambiar.
