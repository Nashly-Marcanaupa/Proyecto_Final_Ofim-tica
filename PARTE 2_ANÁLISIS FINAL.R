########################################################################
# PROYECTO FINAL - R STUDIO
# PARTE 2: Analisis final a partir de los hallazgos del EDA
#
# Fuente: Banco Central de Reserva del Peru (BCRP) - BCRPData
########################################################################

library(ggplot2)
library(dplyr)
library(scales)

# 0. CARGA DE DATOS LIMPIOS (generados por EDA.R) -----------------------
datos <- read.csv("../data/bcrp_datos_limpios.csv", stringsAsFactors = FALSE)
datos$fecha <- as.Date(datos$fecha)

########################################################################
# 1. PREGUNTA DE ANALISIS
#
# Durante el EDA se observo que el año 2022 registro la inflacion
# interanual promedio mas alta del periodo (7.86%), muy por encima de
# la meta del BCRP (rango 1%-3%), coincidiendo con un tipo de cambio
# tambien elevado (S/ 3.84 promedio). A partir de este hallazgo se
# plantea la siguiente pregunta:
#
#   ¿La depreciacion del sol (incremento del tipo de cambio) esta
#   asociada con incrementos en la inflacion en Peru durante el
#   periodo 2010-2026, y que tan fuerte fue esa asociacion durante
#   el episodio inflacionario de 2021-2023?
########################################################################

cat("PREGUNTA DE ANALISIS:\n")
cat("¿La depreciacion del sol (mayor tipo de cambio) esta asociada con\n")
cat("mayor inflacion en Peru (2010-2026), y como se comporto esa relacion\n")
cat("durante el episodio inflacionario de 2021-2023?\n\n")

########################################################################
# 2. ANALISIS DE LA RELACION ENTRE VARIABLES
########################################################################

# 2.1 Correlacion general (todo el periodo)
cor_general <- cor(datos$tc, datos$ipc)
cat("Correlacion general tipo de cambio vs inflacion (2010-2026):",
    round(cor_general, 3), "\n\n")

# 2.2 Correlacion especifica en el episodio inflacionario 2021-2023
episodio <- datos %>% filter(year %in% c(2021, 2022, 2023))
cor_episodio <- cor(episodio$tc, episodio$ipc)
cat("Correlacion tipo de cambio vs inflacion durante 2021-2023:",
    round(cor_episodio, 3), "\n\n")

# 2.3 Tabla comparativa: promedio de variables antes, durante y despues
#     del episodio inflacionario
datos <- datos %>%
  mutate(
    fase = case_when(
      year %in% 2010:2020 ~ "1. Pre-episodio (2010-2020)",
      year %in% 2021:2023 ~ "2. Episodio inflacionario (2021-2023)",
      year %in% 2024:2026 ~ "3. Post-episodio (2024-2026)"
    )
  )

tabla_fases <- datos %>%
  group_by(fase) %>%
  summarise(
    tc_promedio     = round(mean(tc), 3),
    ipc_promedio    = round(mean(ipc), 2),
    ipc_maximo      = round(max(ipc), 2),
    correlacion     = round(cor(tc, ipc), 3),
    n_observaciones = n(),
    .groups = "drop"
  )

cat("--- Tabla comparativa por fases ---\n")
print(tabla_fases)
write.csv(tabla_fases, "../data/tabla_fases_analisis_final.csv", row.names = FALSE)

# 2.4 Indicador adicional: numero de meses con inflacion fuera de la
#     meta del BCRP (rango 1%-3%), por fase
fuera_de_meta <- datos %>%
  mutate(fuera_meta = ipc < 1 | ipc > 3) %>%
  group_by(fase) %>%
  summarise(
    meses_totales   = n(),
    meses_fuera_meta = sum(fuera_meta),
    pct_fuera_meta  = round(100 * mean(fuera_meta), 1),
    .groups = "drop"
  )

cat("\n--- Meses fuera del rango meta de inflacion (1%-3%), por fase ---\n")
print(fuera_de_meta)
write.csv(fuera_de_meta, "../data/tabla_fuera_meta_analisis_final.csv", row.names = FALSE)

########################################################################
# 3. VISUALIZACION ADICIONAL PARA EL HALLAZGO FINAL
########################################################################

tema_proyecto <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(color = "grey30"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Grafico final: doble eje conceptual mediante paneles superpuestos
# (se muestra tipo de cambio e inflacion normalizados en el tiempo,
# resaltando el episodio 2021-2023)
datos_norm <- datos %>%
  mutate(
    tc_norm  = scales::rescale(tc, to = c(0, 10)),
    ipc_norm = scales::rescale(ipc, to = c(0, 10))
  )

g_final <- ggplot(datos, aes(x = fecha)) +
  annotate("rect", xmin = as.Date("2021-01-01"), xmax = as.Date("2023-12-31"),
           ymin = -Inf, ymax = Inf, fill = "grey85", alpha = 0.5) +
  geom_line(aes(y = ipc, color = "Inflacion (IPC var. 12m, %)"), linewidth = 1) +
  geom_line(aes(y = (tc - min(tc)) / (max(tc) - min(tc)) * 8, color = "Tipo de cambio (reescalado)"), linewidth = 1) +
  scale_color_manual(values = c("Inflacion (IPC var. 12m, %)" = "#2ca02c",
                                 "Tipo de cambio (reescalado)" = "#1f77b4")) +
  labs(
    title = "Tipo de cambio e inflacion se mueven juntos durante el shock 2021-2023",
    subtitle = "Zona sombreada: episodio inflacionario (2021-2023). Tipo de cambio reescalado 0-8 para comparar tendencias",
    x = "Fecha",
    y = "Valor",
    color = "Variable",
    caption = "Fuente: BCRP - BCRPData. Elaboracion propia."
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  tema_proyecto

ggsave("../figures/05_hallazgo_final_tc_inflacion.png", g_final, width = 9.5, height = 5.5, dpi = 150)

cat("\nGrafico final guardado en ../figures/05_hallazgo_final_tc_inflacion.png\n")

########################################################################
# 4. CONCLUSIONES PRINCIPALES
#
# 1) A nivel de todo el periodo (2010-2026) existe una asociacion positiva
#    pero MODERADA entre el tipo de cambio y la inflacion mes a mes
#    (correlacion general = 0.336). Esto indica que, en promedio, cuando
#    el sol se deprecia la inflacion tiende a subir un poco, pero la
#    relacion esta lejos de ser determinista: gran parte de la variacion
#    de precios responde a otros factores (precios internacionales de
#    alimentos y combustibles, choques de oferta, expectativas).
#
# 2) Al comparar por fases se observa un hallazgo mas claro a NIVEL DE
#    PROMEDIOS: durante el episodio inflacionario de 2021-2023 el tipo
#    de cambio promedio subio a S/ 3.82 (vs. S/ 3.06 en 2010-2020) y la
#    inflacion promedio salto a 6.05% (vs. 2.71% antes), es decir, ambas
#    variables aumentaron de nivel al mismo tiempo. Sin embargo, la
#    correlacion mes a mes DENTRO del episodio (0.173) fue en realidad
#    MENOR que la correlacion general (0.336), y en el periodo
#    pre-episodio (2010-2020) la correlacion incluso fue negativa
#    (-0.255). Esto muestra que la relacion entre ambas variables no es
#    estable en el tiempo: el tipo de cambio y la inflacion subieron
#    juntos como consecuencia de un choque externo comun (post-pandemia
#    y guerra en Ucrania, que encarecieron alimentos, combustibles y
#    fletes a nivel mundial), mas que por una relacion mecanica y
#    constante de traspaso cambiario mes a mes.
#
# 3) Respondiendo a la pregunta de analisis: el tipo de cambio y la
#    inflacion en Peru SI subieron juntos durante el choque externo de
#    2021-2023 (evidencia al nivel de promedios por fase), pero la
#    asociacion mes a mes entre ambas variables es solo moderada y no se
#    mantiene estable en el tiempo (fue negativa en 2010-2020, positiva
#    pero debil en 2021-2023 y practicamente nula en 2024-2026). Por lo
#    tanto, el tipo de cambio por si solo NO es un buen predictor mensual
#    de la inflacion; es mas util como una de varias señales de alerta
#    cuando se observa una depreciacion sostenida y de gran magnitud.
#
# 4) El indicador de "meses fuera de la meta de inflacion del BCRP (1%-3%)"
#    confirma la severidad del episodio: paso de 49.2% de meses fuera de
#    meta en 2010-2020 a 86.1% en 2021-2023, y bajo a 20.7% en 2024-2026,
#    lo que sugiere que la politica monetaria del BCRP fue efectiva para
#    retornar la inflacion a su rango meta despues del choque. El repunte
#    de la inflacion observado en los primeros meses de 2026 (hasta 4.01%
#    en abril) es una señal que amerita seguimiento en proximos analisis.
########################################################################
