# NOTES.md — play by play historico acb

## Estilo de código

* Escribir solo lo pedido: sin caché, validaciones, manejo de errores ni programación defensiva contra problemas hipotéticos. Los errores se arreglan cuando aparecen, con información real, no por anticipación.
* Usar la capacidad para simplificar, no para expandir: no proponer alternativas no pedidas, no rediseñar lo que ya funciona, no tomar decisiones de diseño/arquitectura que son de Ivan. Responder con la solución más corta y directa.
* Antes de dar por terminada cualquier edición de un `.R`: correr `styler::style_file()` y `lintr::lint()`, y corregir los warnings de lintr. No cambiar el estilo de líneas fuera del cambio pedido.
* No crear variables intermedias que solo existen para devolverse: que la función retorne directamente el resultado del pipe, con los efectos secundarios (`Sys.sleep()`, etc.) antes de esa última expresión.

## Convenciones de R

* Paquetes core: hoopR, httr, jsonlite, tidyverse, gt, ggtext, ggimage, showtext (más rvest, gtExtras, ggpattern en el set completo)
* `%>%` en vez de `|>`
* `pluck() + tibble() + unnest() + relocate()` encadenados
* `bind_rows()` en vez de patrones anidados con `map()`
* `map_df` en vez de `map_dfr`
* Nombres de función en snake_case
* Fuente principal: Oswald; usar `geom_chicklet()` y `geom_shadowtext()`
* `theme_ivo()`: basado en `theme_minimal`, fondo blanco, sin grid menor, acentos naranjas, logos NBA redondos
* Logos: repo de GitHub de Henryjean para NBA, repo propio circlesACB para ACB
* Rscript en `/usr/local/bin/Rscript`

## Explicaciones

* Importa que el código sea funcional, relativamente corto, reproducible, fácil de modificar y enseñable a otra persona. Al preguntar por una línea de código, se busca saber qué cambiar y por qué, no una explicación extensa.
