# Proyecto_Final_Ofimática
# Proyecto Final – R Studio: EDA del Tipo de Cambio y la Inflación en Perú

**Autor:** _Marcañaupa Allcca Nashly Valeria_
**Curso:** Ofimática R Studio
**Fuente de datos:** Banco Central de Reserva del Perú (BCRP) – Plataforma BCRPData
https://estadisticas.bcrp.gob.pe/estadisticas/series/mensuales

**Link del repositorio:** _(pega aquí la URL de tu repositorio de GitHub una vez lo subas, ej. `https://github.com/tu-usuario/Proyecto_Final`)_

## 1. Contexto del conjunto de datos

- **Institución que proporciona los datos:** Banco Central de Reserva del Perú (BCRP), a través de su sistema de series estadísticas **BCRPData**, la fuente oficial de estadísticas macroeconómicas del país.
- **Objetivo / temática del conjunto de datos:** El BCRP publica series históricas mensuales de las principales variables macroeconómicas de Perú. Este proyecto utiliza dos series oficiales para estudiar la relación entre el **tipo de cambio** y la **inflación**:
  - `PN01207PM` – Tipo de cambio interbancario promedio del período (S/ por US$).
  - `PN01273PM` – Índice de Precios al Consumidor (IPC) de Lima Metropolitana, variación % respecto a 12 meses atrás (inflación interanual).
- **Periodo analizado:** enero 2010 – mayo 2026 (197 observaciones mensuales).
- **Principales variables:**
  | Variable | Descripción |
  |---|---|
  | `year` | Año de referencia |
  | `month` | Mes de referencia (1-12) |
  | `tc` | Tipo de cambio interbancario promedio (S/ por US$) |
  | `ipc` | Inflación interanual (variación % del IPC, Lima Metropolitana) |
  | `fecha` | Fecha (primer día del mes), variable derivada |
  | `mes_nombre` | Nombre del mes en español, variable derivada |
  | `decada` | Década del dato (2010s / 2020s), variable derivada |
  | `periodo_covid` | Indica si el mes corresponde a 2020-2021 (pandemia) o no |
  | `tc_var_mensual` | Variación mensual del tipo de cambio, variable derivada |

## 2. Estructura del repositorio

```
Proyecto_Final/
│
├── data/
│   ├── bcrp_tipo_cambio_inflacion.csv     # datos originales importados
│   ├── bcrp_datos_limpios.csv             # datos ya limpios/transformados (salida de EDA.R)
│   ├── tabla_fases_analisis_final.csv     # tabla comparativa por fases (Parte 2)
│   └── tabla_fuera_meta_analisis_final.csv# indicador de meses fuera de meta (Parte 2)
│
├── figures/
│   ├── 01_tipo_cambio_serie_tiempo.png
│   ├── 02_inflacion_serie_tiempo.png
│   ├── 03_dispersion_tc_vs_ipc.png
│   ├── 04_inflacion_promedio_anual.png
│   ├── 05_hallazgo_final_tc_inflacion.png  # gráfico de la Parte 2 (para redes sociales)
│   └── collage_graficos.png               # collage de los 4 gráficos del EDA (Parte 1)
│
├── scripts/
│   ├── EDA.R                   # Parte 1: importación, limpieza, estadísticas y gráficos
│   └── 04_analisis_final.R     # Parte 2: pregunta de análisis, relación e indicadores, conclusiones
│
└── README.md
```

## 3. Metodología (resumen del script `EDA.R`)

1. **Importación:** se leyó el archivo `data/bcrp_tipo_cambio_inflacion.csv` con `read.csv()`.
2. **Limpieza y preparación:**
   - Renombrado de variables (`anio → year`, `mes → month`, etc.).
   - Creación de variables nuevas: `fecha`, `mes_nombre`, `decada`, `periodo_covid`, `tc_var_mensual`.
   - Filtrado de observaciones incompletas (`filter(!is.na(...))`).
   - Agrupación de datos por año (`group_by(year) %>% summarise(...)`) para el resumen anual.
3. **Estadísticas descriptivas:** medidas de tendencia central y dispersión (media, mediana, desviación estándar, mínimo, máximo) para el tipo de cambio y la inflación, además de comparaciones por década y por periodo de pandemia.
4. **Visualización (ggplot2):** se generaron 4 gráficos con título, subtítulo, etiquetas de ejes, leyenda (cuando corresponde) y `theme()` personalizado:
   1. Serie de tiempo del tipo de cambio.
   2. Serie de tiempo de la inflación (con banda de meta del BCRP).
   3. Diagrama de dispersión tipo de cambio vs. inflación, coloreado por década.
   4. Barras de inflación promedio anual.

## 4. Parte 2 – Análisis final (script `04_analisis_final.R`)

### 4.1 Pregunta de análisis

> **¿La depreciación del sol (incremento del tipo de cambio) está asociada con incrementos en la inflación en Perú durante el periodo 2010-2026, y qué tan fuerte fue esa asociación durante el episodio inflacionario de 2021-2023?**

Esta pregunta surge de un hallazgo del EDA: el año 2022 registró la inflación promedio más alta del periodo (7.86%), muy por encima de la meta del BCRP (1%-3%), coincidiendo con un tipo de cambio también elevado.

### 4.2 Análisis de la relación entre variables

- **Correlación general (2010-2026):** r = **0.336** (asociación positiva, pero moderada).
- **Correlación durante el episodio 2021-2023:** r = **0.173** (más débil que la correlación general).
- **Correlación en el periodo pre-episodio (2010-2020):** r = **-0.255** (negativa).

**Tabla comparativa por fases:**

| Fase | Tipo de cambio promedio | Inflación promedio | Inflación máxima | Correlación interna |
|---|---|---|---|---|
| Pre-episodio (2010-2020) | S/ 3.06 | 2.71% | 4.74% | -0.255 |
| Episodio inflacionario (2021-2023) | S/ 3.82 | 6.05% | 8.81% | 0.173 |
| Post-episodio (2024-2026) | S/ 3.62 | 2.14% | 4.01% | 0.023 |

**Indicador adicional — % de meses fuera del rango meta de inflación del BCRP (1%-3%):**

| Fase | % de meses fuera de meta |
|---|---|
| Pre-episodio (2010-2020) | 49.2% |
| Episodio inflacionario (2021-2023) | **86.1%** |
| Post-episodio (2024-2026) | 20.7% |

### 4.3 Conclusiones principales

1. A nivel de todo el periodo existe una asociación positiva pero **moderada** entre el tipo de cambio y la inflación mes a mes (r = 0.336). La depreciación del sol contribuye algo a la inflación, pero no la explica por sí sola.
2. Al comparar por fases se observa un hallazgo más claro **a nivel de promedios**: durante 2021-2023 ambas variables subieron de nivel al mismo tiempo (tipo de cambio de S/ 3.06 a S/ 3.82; inflación de 2.71% a 6.05%). Sin embargo, la correlación mes a mes *dentro* del episodio (0.173) fue incluso **menor** que la correlación general, y en 2010-2020 fue negativa. Esto indica que ambas variables reaccionaron juntas ante un **choque externo común** (efectos post-pandemia y guerra en Ucrania sobre precios de alimentos, combustibles y fletes), más que por una relación mecánica y constante mes a mes.
3. **Respondiendo a la pregunta de análisis:** el tipo de cambio y la inflación en Perú sí subieron juntos durante el choque externo de 2021-2023 (evidencia a nivel de promedios por fase), pero su asociación mensual es solo moderada y no es estable en el tiempo. Por lo tanto, el tipo de cambio por sí solo **no es un buen predictor mensual** de la inflación; es más útil como una señal de alerta cuando se observa una depreciación sostenida y de gran magnitud.
4. El indicador de meses fuera de la meta del BCRP confirma la severidad del episodio (pasó de 49.2% a 86.1% de meses fuera de meta) y la efectividad posterior de la política monetaria para retornar la inflación al rango meta (20.7% en 2024-2026). El repunte de inflación observado en los primeros meses de 2026 (hasta 4.01% en abril) es una señal que amerita seguimiento en próximos análisis.

## 5. Cómo reproducir el análisis

```r
# Desde la carpeta scripts/
install.packages(c("ggplot2", "dplyr", "tidyr", "scales"))
source("EDA.R")
source("04_analisis_final.R")
```

## 6. Publicación en redes sociales (LinkedIn / X)

Se publicó el gráfico `HALLAZGO FINAL_INFLACIÓN` junto con los hallazgos finales del análisis.
<img width="737" height="565" alt="image" src="https://github.com/user-attachments/assets/338cc632-3826-4695-942f-308e1783d106" />

