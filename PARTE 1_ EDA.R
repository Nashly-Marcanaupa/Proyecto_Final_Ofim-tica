########################################################################
# PROYECTO FINAL - R STUDIO
# Analisis Exploratorio de Datos (EDA)
#
# Fuente: Banco Central de Reserva del Peru (BCRP) - BCRPData
# https://estadisticas.bcrp.gob.pe/estadisticas/series/mensuales
#
# Series utilizadas:
#   - PN01207PM: Tipo de cambio interbancario promedio (S/ por US$)
#   - PN01273PM: Indice de Precios al Consumidor - Lima Metropolitana
#                (variacion % respecto a 12 meses atras)
#
# Periodo: Enero 2010 - Mayo 2026 (dato mensual, 197 observaciones)
########################################################################

# 0. LIBRERIAS --------------------------------------------------------
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)

# 1. CONTEXTO DEL CONJUNTO DE DATOS ------------------------------------
# Institucion: Banco Central de Reserva del Peru (BCRP), a traves de su
#   plataforma de series estadisticas BCRPData (estadisticas.bcrp.gob.pe).
# Objetivo/tematica: El BCRP publica series historicas de las principales
#   variables macroeconomicas del pais. Este proyecto usa dos series
#   mensuales clave para entender la relacion entre el tipo de cambio
#   (S/ por US$) y la inflacion (variacion % del IPC en 12 meses) en Peru.
# Variables principales:
#   - anio, mes: periodo de referencia del dato
#   - tipo_cambio_interbancario: tipo de cambio promedio interbancario (S/ por US$)
#   - inflacion_ipc_var12m: inflacion interanual medida por el IPC de Lima
#     Metropolitana (%)

# 2. IMPORTACION DE DATOS ----------------------------------------------
ruta_datos <- "../data/bcrp_tipo_cambio_inflacion.csv"
datos <- read.csv(ruta_datos, stringsAsFactors = FALSE)

str(datos)
head(datos)
dim(datos)

# 3. LIMPIEZA Y PREPARACION --------------------------------------------

# 3.1 Cambio de nombres de variables (mas descriptivos y cortos)
datos <- datos %>%
  rename(
    year   = anio,
    month  = mes,
    tc     = tipo_cambio_interbancario,
    ipc    = inflacion_ipc_var12m
  )

# 3.2 Creacion de nuevas variables
meses_es <- c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic")

datos <- datos %>%
  mutate(
    fecha = as.Date(paste(year, month, "01", sep = "-")),        # variable fecha
    mes_nombre = factor(meses_es[month], levels = meses_es),      # mes en texto
    decada = paste0(floor(year / 10) * 10, "s"),                  # variable categorica: decada
    periodo_covid = ifelse(year %in% c(2020, 2021), "Pandemia (2020-2021)", "Resto de periodo"),
    tc_var_mensual = c(NA, diff(tc))                              # variacion mensual del TC
  ) %>%
  arrange(fecha)

# 3.3 Filtrado / seleccion de observaciones: subconjunto sin datos incompletos
datos <- datos %>% filter(!is.na(tc), !is.na(ipc))

# 3.4 Agrupacion: promedio anual de ambas variables
resumen_anual <- datos %>%
  group_by(year) %>%
  summarise(
    tc_promedio  = mean(tc),
    ipc_promedio = mean(ipc),
    n_meses      = n(),
    .groups = "drop"
  )

print(resumen_anual)

# Guardar datos limpios (opcional, para trazabilidad)
write.csv(datos, "../data/bcrp_datos_limpios.csv", row.names = FALSE)

# 4. ESTADISTICAS DESCRIPTIVAS ------------------------------------------

cat("\n--- Resumen general (summary) ---\n")
summary(datos[, c("tc", "ipc", "tc_var_mensual")])

cat("\n--- Medidas de tendencia central y dispersion ---\n")
estadisticas <- datos %>%
  summarise(
    tc_media    = mean(tc),
    tc_mediana  = median(tc),
    tc_sd       = sd(tc),
    tc_min      = min(tc),
    tc_max      = max(tc),
    ipc_media   = mean(ipc),
    ipc_mediana = median(ipc),
    ipc_sd      = sd(ipc),
    ipc_min     = min(ipc),
    ipc_max     = max(ipc),
    correlacion_tc_ipc = cor(tc, ipc)
  )
print(estadisticas)

cat("\n--- Estadisticas por decada ---\n")
por_decada <- datos %>%
  group_by(decada) %>%
  summarise(
    tc_promedio  = mean(tc),
    ipc_promedio = mean(ipc),
    ipc_max      = max(ipc),
    .groups = "drop"
  )
print(por_decada)

cat("\n--- Comparacion pandemia vs resto del periodo ---\n")
por_pandemia <- datos %>%
  group_by(periodo_covid) %>%
  summarise(
    tc_promedio  = mean(tc),
    ipc_promedio = mean(ipc),
    .groups = "drop"
  )
print(por_pandemia)

# 5. VISUALIZACION DE DATOS (ggplot2) -----------------------------------

tema_proyecto <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(color = "grey30"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Grafico 1: Evolucion del tipo de cambio en el tiempo (serie de tiempo)
g1 <- ggplot(datos, aes(x = fecha, y = tc)) +
  geom_line(color = "#1f77b4", linewidth = 0.9) +
  geom_smooth(method = "loess", se = FALSE, color = "#d62728", linetype = "dashed") +
  labs(
    title = "Evolucion del tipo de cambio interbancario en Peru",
    subtitle = "Soles (S/) por dolar americano (US$), 2010 - 2026",
    x = "Fecha",
    y = "Tipo de cambio (S/ por US$)",
    caption = "Fuente: BCRP - BCRPData (serie PN01207PM)"
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  tema_proyecto

ggsave("../figures/01_tipo_cambio_serie_tiempo.png", g1, width = 9, height = 5.5, dpi = 150)

# Grafico 2: Evolucion de la inflacion (IPC) en el tiempo, con banda meta BCRP
g2 <- ggplot(datos, aes(x = fecha, y = ipc)) +
  geom_hline(yintercept = c(1, 3), linetype = "dotted", color = "grey50") +
  geom_line(color = "#2ca02c", linewidth = 0.9) +
  labs(
    title = "Evolucion de la inflacion interanual (IPC) en Peru",
    subtitle = "Variacion % del IPC de Lima Metropolitana respecto a 12 meses atras\n(lineas punteadas: rango meta de inflacion del BCRP 1%-3%)",
    x = "Fecha",
    y = "Inflacion interanual (%)",
    caption = "Fuente: BCRP - BCRPData (serie PN01273PM)"
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  tema_proyecto

ggsave("../figures/02_inflacion_serie_tiempo.png", g2, width = 9, height = 5.5, dpi = 150)

# Grafico 3: Relacion entre tipo de cambio e inflacion (dispersion)
g3 <- ggplot(datos, aes(x = tc, y = ipc, color = decada)) +
  geom_point(alpha = 0.75, size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dashed", linewidth = 0.6) +
  labs(
    title = "Relacion entre tipo de cambio e inflacion en Peru",
    subtitle = "Cada punto representa un mes entre 2010 y 2026",
    x = "Tipo de cambio (S/ por US$)",
    y = "Inflacion interanual (%)",
    color = "Decada",
    caption = "Fuente: BCRP - BCRPData"
  ) +
  tema_proyecto

ggsave("../figures/03_dispersion_tc_vs_ipc.png", g3, width = 8, height = 5.5, dpi = 150)

# Grafico 4: Promedio anual de inflacion por barras
g4 <- ggplot(resumen_anual, aes(x = factor(year), y = ipc_promedio, fill = ipc_promedio)) +
  geom_col() +
  geom_hline(yintercept = 2, linetype = "dashed", color = "grey30") +
  labs(
    title = "Inflacion promedio anual en Peru",
    subtitle = "Promedio del IPC interanual por año (linea: meta central del BCRP, 2%)",
    x = "Año",
    y = "Inflacion promedio anual (%)",
    fill = "Inflacion (%)",
    caption = "Fuente: BCRP - BCRPData (serie PN01273PM)"
  ) +
  scale_fill_gradient(low = "#a6d96a", high = "#d7191c") +
  tema_proyecto +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("../figures/04_inflacion_promedio_anual.png", g4, width = 9, height = 5.5, dpi = 150)

cat("\nGraficos guardados en la carpeta figures/\n")

########################################################################
# FIN DEL SCRIPT EDA.R
########################################################################
