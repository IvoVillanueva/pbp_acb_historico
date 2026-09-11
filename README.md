<div align="center">

# 🏀 PBP ACB Histórico
<img src="[https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Liga_Endesa_2019_logo.svg/800px-Liga_Endesa_2019_logo.svg.png](https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e7/Liga_Endesa_2019_logo.svg/330px-Liga_Endesa_2019_logo.svg.png?utm_source=es.wikipedia.org&utm_campaign=index&utm_content=thumbnail)" alt="Liga Endesa" width="260"/>

### 📊 Histórico y actualización automática de partidos, play-by-play y boxscores de la ACB

[![Actualiza ACB en temporada](https://github.com/IvoVillanueva/pbp_acb_historico/actions/workflows/main.yml/badge.svg)](https://github.com/IvoVillanueva/pbp_acb_historico/actions/workflows/main.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-%23276DC3.svg?logo=r&logoColor=white)](https://www.r-project.org/)
[![tidyverse](https://img.shields.io/badge/tidyverse-%231A162D.svg?logo=tidyverse&logoColor=white)](https://www.tidyverse.org/)

---

*Pipeline en R que descarga el histórico completo de Liga Endesa, Copa del Rey y Supercopa (calendario, play-by-play y boxscores) y lo mantiene al día en temporada mediante GitHub Actions*

</div>

---

## 📖 Descripción

Este repositorio extrae de la API de la ACB el calendario, el play-by-play y los boxscores (jugador y equipo) de las tres competiciones — **Liga Endesa, Copa del Rey y Supercopa** — desde la temporada más antigua disponible hasta hoy. El histórico se descargó una vez; en temporada, un workflow de GitHub Actions revisa cada 10 minutos si se ha jugado algún partido y, si lo hay, añade sus datos sin volver a tocar lo ya descargado.

## ✨ Características

- 🗓️ **Histórico completo**: calendario desde 1975, boxscores desde 1983, play-by-play desde 2016-17
- 🔄 **Actualización automática**: GitHub Actions revisa cada 10 minutos en temporada (septiembre-junio) y solo trabaja los días que hay partido
- ♻️ **Incremental**: cada script añade lo nuevo sin volver a descargar lo que ya existe
- 🧮 **Play-by-play enriquecido**: valoración por jugada y quinteto en pista en cada evento
- 📦 **Un CSV por tabla** (o por temporada cuando el peso lo exige), listo para cargar y filtrar

## 📁 Estructura del proyecto

```
pbp_acb_historico/
├── setup.R                    # Librerías, autenticación y temporada_actual()
├── main_acb_update.R          # Runner: refresca horarios, sale si hoy no hay partido, corre el pipeline
├── scripts/
│   ├── 01_calendario.R        # Jornadas y partidos (Liga, Copa, Supercopa)
│   ├── 02_pbp.R                # Play-by-play
│   ├── 03_boxscore.R          # Boxscore de jugador
│   ├── 04_stats_equipos.R     # Estadísticas de equipo
│   ├── 05_pbp_clean.R         # Valoración por jugada + quinteto en pista
│   └── 06_horarios.R          # Fixture de la temporada en curso (fecha y hora)
├── data/
│   ├── ids_partidos_historico.csv   # Jornadas, 1975-hoy
│   ├── calendario_historico.csv     # Partidos finalizados, 1975-hoy
│   └── horarios.csv                 # Calendario de la temporada en curso
├── data_pbps/                  # Play-by-play crudo, un CSV por temporada (2016-17+)
├── data_pbp_clean/             # Play-by-play enriquecido, un CSV por temporada
├── data_boxscores/              # Boxscore de jugador, un CSV por temporada (1983+)
├── data_stats_equipos/         # Boxscore de equipo, un CSV por temporada (1983+)
├── .github/workflows/main.yml # Automatización en temporada
└── LICENSE
```

## 🛠️ Instalación y uso

### Requisitos

- R ≥ 4.0
- Paquetes:

```r
install.packages(c("tidyverse", "jsonlite", "httr", "hms"))
```

- Un `.Renviron` local con las credenciales de la API (no se suben al repo):

```
ACB_TOKEN=...
ACB_API=https://api2.acb.com/api/v1/openapilive/
```

### Ejecución local

Cada script en `scripts/` corre, al sourcearlo, su **actualización incremental** (los partidos que aún no tiene). El backfill completo de cada tabla es una función aparte, para no repetirlo por error:

```r
source("scripts/01_calendario.R")   # actualiza la edición en curso
backfill_calendario()               # o: regenera todo el histórico
```

Para actualizar todo de una vez, el runner:

```bash
Rscript main_acb_update.R
```

## 📊 Datos

| Tabla | Cobertura | Contenido |
|---|---|---|
| `calendario_historico.csv` | 1975 – hoy, ~16 500 partidos | resultado, equipos, fecha, jornada, competición |
| `data_pbps/` | 2016-17 – hoy | play-by-play crudo: cada jugada del partido |
| `data_pbp_clean/` | 2016-17 – hoy | + valoración por jugada, asistencias, tiros, quinteto en pista en cada evento |
| `data_boxscores/` | 1983 – hoy | estadísticas de jugador por partido |
| `data_stats_equipos/` | 1983 – hoy | estadísticas de equipo por partido |

Las tres competiciones (`id_competition`: 1 Liga Endesa, 2 Copa del Rey, 3 Supercopa) están en las mismas tablas, distinguibles por esa columna.

## ⚙️ Automatización con GitHub Actions

El workflow corre cada 10 minutos entre septiembre y junio. `main_acb_update.R` refresca primero el calendario de la temporada en curso y, si ningún partido se ha jugado hoy, termina sin hacer nada. Si hay partidos, actualiza calendario, play-by-play, boxscores y el play-by-play limpio, y commitea los CSV cambiados.

También se puede lanzar a mano desde la pestaña **Actions** del repositorio.

## 🏆 Fuente de datos

Los datos se obtienen de la API pública de la ACB (`api2.acb.com`).

## 📜 Licencia

Este proyecto está licenciado bajo la **Licencia MIT** — ver [LICENSE](LICENSE).

## 👤 Autor

<div align="center">

**Iván Villanueva Sabalete**

[![GitHub](https://img.shields.io/badge/GitHub-IvoVillanueva-181717?logo=github)](https://github.com/IvoVillanueva)

</div>
