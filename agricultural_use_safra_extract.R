################################################################################
# agricultural_use_safra_extract.R
#
# Objetivo: Extraer, por celda de una grilla vectorial (gpkg), el area en
#           HECTAREAS cubierta por:
#             (a) 5 clases de uso agricola (landcover temporary crops MapBiomas) x 6 anos
#                 (2000, 2005, 2010, 2015, 2020, 2024) -> 30 columnas
#             (b) 3 clases de segunda safra (double crop) x 6 anos
#                 (2000, 2005, 2010, 2015, 2020, 2024) -> 18 columnas
#             (c) TODAS las combinaciones posibles agricultural use x safra, por ano
#                 (5 x 3 = 15 combinaciones x 6 anos = 90 posibles), pero
#                 solo se conservan en el gpkg final las que tengan area > 0
#                 en todo el pais (columnas dinamicas)
#
# checkpoint por clase/celda, simplificada:
# un solo raster por producto/ano).
#
# IMPORTANTE - supuesto de calculo de area:
#   area_clase_ha = (n_pixeles_clase / n_pixeles_totales_en_la_celda) * area_ha_celda
#   Se usa na_as_zero = TRUE por defecto, es decir: el denominador es el
#   total de pixeles que caen dentro de la celda (cubran o no dato valido),
#   de forma que el area calculada sea siempre una fraccion real del area
#   geometrica de la celda. 
# FGV Agro
################################################################################

library(sf)
library(terra)

# ==============================================================================
# CONFIGURACION -- COMPLETAR ANTES DE CORRER
# ==============================================================================

SAVE_EVERY <- 200   # guardar checkpoint cada N celdas

# --- Grilla de celdas (COMPLETAR con la ruta real) --------------------------
gpkg_path <- "~/clustermap_rev4.117_BRA.gpkg"   # <-- COMPLETAR: ruta al gpkg con los poligonos de celdas


gpkg_layer <- NA  # NA = usar la primera/unica capa del gpkg; o indicar nombre

if (gpkg_path == "") {
  stop("Falta completar 'gpkg_path' con la ruta al gpkg de la grilla de celdas.")
}

cells_dir <- dirname(gpkg_path)
ckpt_dir  <- file.path(cells_dir, "ckpt_landcover_safra")
dir.create(ckpt_dir, showWarnings = FALSE, recursive = TRUE)

out_gpkg <- file.path(cells_dir,
                      paste0(tools::file_path_sans_ext(basename(gpkg_path)),
                             "_2.gpkg"))

# --- Carpeta y archivos raster -----------------------------------------------
raster_dir <- "~/rasters"

anos <- c(2000, 2005,2010, 2015, 2020, 2024)

tif_lc <- list(  # landcover (agricultural_use)
  "2010" = file.path(raster_dir, "2010_agriculture_agricultural_use_1-1-1_5f2913b8-9e70-4f07-850b-bc8af4bc1955 (1).tif"),
  "2020" = file.path(raster_dir, "2020_agriculture_agricultural_use_1-1-1_71e7d03a-058b-430d-8889-bce50e22f8bc.tif")
  "2000" = file.path(raster_dir, "2000_agriculture_agricultural_use_1-1-1_79884444-c164-4e1f-b66c-d6717be6762c.tif"),
  "2005" = file.path(raster_dir, "2005_agriculture_agricultural_use_1-1-1_54bb182d-7202-4627-8c00-4570b81f38e0.tif"),
  "2015" = file.path(raster_dir, "2015_agriculture_agricultural_use_1-1-1_be32f69a-8b18-43dd-9cf8-79ac2e3eb3f3.tif"),
  "2024" = file.path(raster_dir, "2024_agriculture_agricultural_use_1-1-1_0174bfb9-84b1-4443-91db-5213994eeb55.tif")
)

tif_sf <- list(  # segunda safra (second_crop)
  "2010" = file.path(raster_dir, "2010_agriculture_agricultural_use_second_crop_1-1-1_e296e27d-bcc0-469c-aab5-ef4a2a141288.tif"),
  "2020" = file.path(raster_dir, "2020_agriculture_agricultural_use_second_crop_1-1-1_6b693804-82ed-4e1e-98ce-472b41a8d0b4.tif")
  "2000" = file.path(raster_dir, "2000_agriculture_agricultural_use_second_crop_1-1-1_d3bcf1f7-ff4a-458e-b277-6f629fc4f5ee.tif"),
  "2005" = file.path(raster_dir, "2005_agriculture_agricultural_use_second_crop_1-1-1_bd5a8f19-cb23-4b2a-8201-8e6a8da61f69.tif"),
  "2015" = file.path(raster_dir, "2015_agriculture_agricultural_use_second_crop_1-1-1_742e5e1a-744f-4e4a-9f10-4147398a05f3.tif"),
  "2024" = file.path(raster_dir, "2024_agriculture_agricultural_use_second_crop_1-1-1_f968dc13-8eb5-4c84-a28f-d603591dd6b6.tif")
)

# ==============================================================================
# DEFINICION DE CLASES
# ==============================================================================

# Landcover (MapBiomas) -- 5 clases -> 30 columnas (5 x 6 anos)
lc_classes <- c(
  cana              = 20,
  soja              = 39,
  arroz             = 40,
  outras_lav_temp   = 41,
  algodao           = 62
)

# Segunda safra (double crop) -- 3 clases -> 18 columnas (3 x 6 anos)
sf_classes <- c(
  milho             = 1,
  algodao           = 62,
  outras_lav_temp   = 41
)

# Todas las combinaciones posibles landcover x safra (33 por ano)
combos <- expand.grid(lc_name = names(lc_classes),
                      sf_name = names(sf_classes),
                      stringsAsFactors = FALSE)
combos$lc_code <- lc_classes[combos$lc_name]
combos$sf_code <- sf_classes[combos$sf_name]

cat(sprintf("Clases landcover : %d | Clases safra: %d | Combinaciones posibles/ano: %d\n",
            length(lc_classes), length(sf_classes), nrow(combos)))

# ==============================================================================
# LEER GRILLA
# ==============================================================================

cat(strrep("=", 60), "\n")
cat(" Leyendo grilla de celdas\n")
cat(strrep("=", 60), "\n")

grid <- if (is.na(gpkg_layer)) {
  st_read(gpkg_path, quiet = TRUE)
} else {
  st_read(gpkg_path, layer = gpkg_layer, quiet = TRUE)
}
if (is.na(st_crs(grid))) stop("La grilla no tiene CRS definido.")

cat(sprintf("  -> %d celdas | CRS: %s\n", nrow(grid), st_crs(grid)$input))

# --- area_ha por celda, calculada desde la geometria -------------------------
if (!"area_ha" %in% names(grid)) {
  cat("  Calculando area_ha desde la geometria...\n")
  grid$area_ha <- as.numeric(st_area(grid)) / 10000
} else {
  cat("  Columna area_ha ya existente -- se reutiliza.\n")
}
cat(sprintf("  area_ha total: %.2f ha\n\n", sum(grid$area_ha)))

cat("Verificando rasters:\n")
for (a in as.character(anos)) {
  for (f in c(tif_lc[[a]], tif_sf[[a]])) {
    cat(sprintf("  %-90s -> %s\n", basename(f),
                ifelse(file.exists(f), "OK", "NO ENCONTRADO")))
  }
}
cat("\n")

# ==============================================================================
# FUNCIONES DE COMPUTO CON CHECKPOINT
# ==============================================================================

# ---- Alinear grilla al CRS de un raster (si hace falta) --------------------
grid_in_crs <- function(grid_sf, r) {
  if (st_crs(grid_sf) == st_crs(crs(r))) grid_sf else st_transform(grid_sf, crs(r))
}

# ---- Area (ha) de UNA clase, por celda --------------------------------------
# r          : SpatRaster ya abierto (terra::rast)
# area_col   : columna de area (ha) en grid_sf
# na_as_zero : TRUE  -> denominador = todos los pixeles de la celda (recom.)
#              FALSE -> denominador = solo pixeles validos (no-NA)
compute_class_ha <- function(grid_sf, r, classe_alvo,
                             area_col   = "area_ha",
                             na_as_zero = TRUE,
                             ck_file    = NULL,
                             save_every = SAVE_EVERY,
                             label      = "") {
  
  n      <- nrow(grid_sf)
  area_ha <- numeric(n)
  start_i <- 1L
  
  if (!is.null(ck_file) && file.exists(ck_file)) {
    ck <- readRDS(ck_file)
    if (isTRUE(ck$complete) && length(ck$area_ha) == n) {
      cat("  [SKIP] Checkpoint completo -- pulando.\n")
      return(ck$area_ha)
    }
    if (length(ck$area_ha) == n && !is.null(ck$last_i)) {
      area_ha <- ck$area_ha
      start_i <- ck$last_i + 1L
      cat(sprintf("  [RESUME] Continuando desde la celda %d/%d\n", start_i, n))
    }
  }
  
  if (start_i > n) { cat("  [SKIP] Ya concluido.\n"); return(area_ha) }
  
  cat(sprintf("  %s | clases: %s | denom: %s\n", label,
              paste(classe_alvo, collapse = ", "),
              ifelse(na_as_zero, "ncell total", "pixeles validos")))
  
  t0 <- Sys.time()
  for (i in seq(start_i, n)) {
    area_ha[i] <- tryCatch({
      bb       <- st_bbox(grid_sf[i, ])
      cell_ext <- ext(bb["xmin"], bb["xmax"], bb["ymin"], bb["ymax"])
      r_cell   <- crop(r, cell_ext)
      
      if (is.null(r_cell) || ncell(r_cell) == 0) {
        0
      } else {
        if (na_as_zero) {
          total_pixels <- ncell(r_cell)
        } else {
          n_na         <- as.integer(global(is.na(r_cell), "sum")[1, 1])
          total_pixels <- ncell(r_cell) - n_na
        }
        if (total_pixels == 0) {
          0
        } else {
          ft       <- freq(r_cell)
          n_classe <- sum(ft$count[ft$value %in% classe_alvo], na.rm = TRUE)
          (n_classe / total_pixels) * grid_sf[[area_col]][i]
        }
      }
    }, error = function(e) {
      cat(sprintf("\n  [AVISO] Error GDAL en celda %d: %s -- usando 0\n",
                  i, conditionMessage(e)))
      0
    })
    
    if (i %% save_every == 0L || i == n) {
      elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
      n_done  <- i - start_i + 1L
      eta     <- if (i < n) elapsed / n_done * (n - i) else 0
      cat(sprintf("\r    [%3d%%] %d/%d | %.1f min | ETA: %.1f min   ",
                  round(100 * i / n), i, n, elapsed, eta))
      if (!is.null(ck_file)) {
        saveRDS(list(area_ha = area_ha, last_i = i, complete = (i == n)), ck_file)
      }
    }
  }
  cat(sprintf("\n  -> Total: %.2f ha (%.1f min)\n",
              sum(area_ha), as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  area_ha
}

# ---- Area (ha) de la COINCIDENCIA EXACTA entre una clase landcover y ------
# ---- una clase de segunda safra, por celda ---------------------------------
# r_lc, r_sf : SpatRasters ya abiertos y ALINEADOS (mismo grid de pixeles)
# denom      : "lc" (denom = pixeles totales del recorte de landcover, por
#              defecto) -- asi la coincidencia siempre es <= area de esa
#              clase de landcover en la misma celda/ano.
compute_overlap_ha <- function(grid_sf, r_lc, r_sf, lc_code, sf_code,
                               area_col   = "area_ha",
                               ck_file    = NULL,
                               save_every = SAVE_EVERY,
                               label      = "") {
  
  n       <- nrow(grid_sf)
  area_ha <- numeric(n)
  start_i <- 1L
  
  if (!is.null(ck_file) && file.exists(ck_file)) {
    ck <- readRDS(ck_file)
    if (isTRUE(ck$complete) && length(ck$area_ha) == n) {
      cat("  [SKIP] Checkpoint completo -- pulando.\n")
      return(ck$area_ha)
    }
    if (length(ck$area_ha) == n && !is.null(ck$last_i)) {
      area_ha <- ck$area_ha
      start_i <- ck$last_i + 1L
      cat(sprintf("  [RESUME] Continuando desde la celda %d/%d\n", start_i, n))
    }
  }
  
  if (start_i > n) { cat("  [SKIP] Ya concluido.\n"); return(area_ha) }
  
  cat(sprintf("  %s | lc=%d & sf=%d\n", label, lc_code, sf_code))
  
  t0 <- Sys.time()
  for (i in seq(start_i, n)) {
    area_ha[i] <- tryCatch({
      bb        <- st_bbox(grid_sf[i, ])
      cell_ext  <- ext(bb["xmin"], bb["xmax"], bb["ymin"], bb["ymax"])
      r_lc_cell <- crop(r_lc, cell_ext)
      r_sf_cell <- crop(r_sf, cell_ext)
      
      if (is.null(r_lc_cell) || ncell(r_lc_cell) == 0 ||
          is.null(r_sf_cell) || ncell(r_sf_cell) == 0) {
        0
      } else {
        total_pixels <- ncell(r_lc_cell)   # denom = pixeles totales de la celda
        if (total_pixels == 0) {
          0
        } else {
          comb     <- r_lc_cell * 1000 + r_sf_cell
          ft       <- freq(comb)
          codigo   <- lc_code * 1000 + sf_code
          n_comb   <- sum(ft$count[ft$value == codigo], na.rm = TRUE)
          (n_comb / total_pixels) * grid_sf[[area_col]][i]
        }
      }
    }, error = function(e) {
      cat(sprintf("\n  [AVISO] Error GDAL en celda %d: %s -- usando 0\n",
                  i, conditionMessage(e)))
      0
    })
    
    if (i %% save_every == 0L || i == n) {
      elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
      n_done  <- i - start_i + 1L
      eta     <- if (i < n) elapsed / n_done * (n - i) else 0
      cat(sprintf("\r    [%3d%%] %d/%d | %.1f min | ETA: %.1f min   ",
                  round(100 * i / n), i, n, elapsed, eta))
      if (!is.null(ck_file)) {
        saveRDS(list(area_ha = area_ha, last_i = i, complete = (i == n)), ck_file)
      }
    }
  }
  cat(sprintf("\n  -> Total: %.2f ha (%.1f min)\n",
              sum(area_ha), as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  area_ha
}

# ---- Version OPTIMIZADA: calcula VARIAS combinaciones EN UN SOLO PASE -----
# En vez de hacer crop()+freq() por cada combinacion (33 veces por celda),
# hace crop()+freq() UNA sola vez por celda y extrae de esa misma tabla de
# frecuencias el conteo de TODAS las combinaciones pendientes. Es compatible
# con los checkpoints individuales generados por compute_overlap_ha(): las
# combinaciones que ya estan "complete" en su .rds individual se saltan
# antes de llamar a esta funcion (ver loop principal).
compute_overlap_batch_ha <- function(grid_sf, r_lc, r_sf, combos_pending,
                                     area_col   = "area_ha",
                                     ck_file    = NULL,
                                     save_every = SAVE_EVERY,
                                     label      = "") {
  
  n     <- nrow(grid_sf)
  m     <- nrow(combos_pending)
  codes <- combos_pending$lc_code * 1000 + combos_pending$sf_code
  mat   <- matrix(0, nrow = n, ncol = m,
                  dimnames = list(NULL, combos_pending$col))
  start_i <- 1L
  
  if (!is.null(ck_file) && file.exists(ck_file)) {
    ck <- readRDS(ck_file)
    same_shape <- !is.null(ck$mat) && nrow(ck$mat) == n && ncol(ck$mat) == m &&
      all(colnames(ck$mat) == colnames(mat))
    if (same_shape && isTRUE(ck$complete)) {
      cat("  [SKIP] Checkpoint de lote completo -- pulando.\n")
      return(ck$mat)
    }
    if (same_shape && !is.null(ck$last_i)) {
      mat     <- ck$mat
      start_i <- ck$last_i + 1L
      cat(sprintf("  [RESUME] Continuando lote desde la celda %d/%d\n", start_i, n))
    }
  }
  
  if (start_i > n) { cat("  [SKIP] Lote ya concluido.\n"); return(mat) }
  
  cat(sprintf("  %s | %d combinaciones en un solo pase por celda\n", label, m))
  
  t0 <- Sys.time()
  for (i in seq(start_i, n)) {
    tryCatch({
      bb        <- st_bbox(grid_sf[i, ])
      cell_ext  <- ext(bb["xmin"], bb["xmax"], bb["ymin"], bb["ymax"])
      r_lc_cell <- crop(r_lc, cell_ext)
      r_sf_cell <- crop(r_sf, cell_ext)
      
      if (!is.null(r_lc_cell) && ncell(r_lc_cell) > 0 &&
          !is.null(r_sf_cell) && ncell(r_sf_cell) > 0) {
        total_pixels <- ncell(r_lc_cell)
        if (total_pixels > 0) {
          comb <- r_lc_cell * 1000 + r_sf_cell
          ft   <- freq(comb)
          for (j in seq_len(m)) {
            n_comb   <- sum(ft$count[ft$value == codes[j]], na.rm = TRUE)
            mat[i, j] <- (n_comb / total_pixels) * grid_sf[[area_col]][i]
          }
        }
      }
    }, error = function(e) {
      cat(sprintf("\n  [AVISO] Error GDAL en celda %d: %s -- usando 0\n",
                  i, conditionMessage(e)))
    })
    
    if (i %% save_every == 0L || i == n) {
      elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
      n_done  <- i - start_i + 1L
      eta     <- if (i < n) elapsed / n_done * (n - i) else 0
      cat(sprintf("\r    [%3d%%] %d/%d | %.1f min | ETA: %.1f min   ",
                  round(100 * i / n), i, n, elapsed, eta))
      if (!is.null(ck_file)) {
        saveRDS(list(mat = mat, last_i = i, complete = (i == n)), ck_file)
      }
    }
  }
  cat(sprintf("\n  -> Lote listo (%.1f min)\n",
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  mat
}

# ==============================================================================
# LOOP PRINCIPAL
# ==============================================================================

ov_cols_por_ano <- list()   # guarda que columnas ov_ se conservan por ano

for (ano in anos) {
  a <- as.character(ano)
  
  cat("\n", strrep("=", 70), "\n")
  cat(sprintf(" ANO: %d\n", ano))
  cat(strrep("=", 70), "\n")
  
  # ---- Saltar ano si ya esta completo en el gpkg de salida ------------------
  marker_col <- paste0("lc_", names(lc_classes)[1], "_", a)
  if (file.exists(out_gpkg)) {
    existing_layers <- tryCatch(st_layers(out_gpkg)$name, error = function(e) character(0))
    if (length(existing_layers) > 0) {
      g_check <- tryCatch(st_read(out_gpkg, quiet = TRUE), error = function(e) NULL)
      if (!is.null(g_check) && marker_col %in% names(g_check)) {
        cat(sprintf("  [SKIP] Ano %d ya presente en %s -- pulando.\n", ano, basename(out_gpkg)))
        grid <- g_check
        next
      }
    }
  }
  
  if (!file.exists(tif_lc[[a]]) || !file.exists(tif_sf[[a]])) {
    stop(sprintf("Falta raster para el ano %d. Verifica tif_lc/tif_sf.", ano))
  }
  
  r_lc <- rast(tif_lc[[a]])
  r_sf <- rast(tif_sf[[a]])
  
  # ---- Alinear grilla al CRS del raster --------------------------------------
  grid_r <- grid_in_crs(grid, r_lc)
  
  # ---- Alinear r_sf al grid de pixeles de r_lc si difieren -------------------
  if (!compareGeom(r_lc, r_sf, stopOnError = FALSE)) {
    cat("  [INFO] r_lc y r_sf no comparten grid de pixeles -- reproyectando r_sf a r_lc (near)...\n")
    r_sf <- project(r_sf, r_lc, method = "near")
  }
  
  # ---- Landcover: 5 clases -> lc_{clase}_{ano} ------------------------------
  for (nm in names(lc_classes)) {
    col <- paste0("lc_", nm, "_", a)
    if (col %in% names(grid_r)) { cat(sprintf(">> %s ya en memoria, pulando\n", col)); next }
    cat(sprintf("\n>> %s\n", col))
    ck <- file.path(ckpt_dir, sprintf("lc_%s_%s.rds", nm, a))
    grid_r[[col]] <- compute_class_ha(grid_r, r_lc, lc_classes[[nm]],
                                      ck_file = ck, label = col)
  }
  
  # ---- Segunda safra: 3 clases -> sf_{clase}_{ano} ---------------------------
  for (nm in names(sf_classes)) {
    col <- paste0("sf_", nm, "_", a)
    if (col %in% names(grid_r)) { cat(sprintf(">> %s ya en memoria, pulando\n", col)); next }
    cat(sprintf("\n>> %s\n", col))
    ck <- file.path(ckpt_dir, sprintf("sf_%s_%s.rds", nm, a))
    grid_r[[col]] <- compute_class_ha(grid_r, r_sf, sf_classes[[nm]],
                                      ck_file = ck, label = col)
  }
  
  # ---- Coincidencias exactas: hasta 15 combinaciones -> ov_{lc}_{sf}_{ano} --
  # Primero: reusar checkpoints INDIVIDUALES ya completos (de corridas
  # anteriores). Lo que falte se calcula en UN SOLO PASE por celda
  # (compute_overlap_batch_ha), mucho mas rapido que una pasada por
  # combinacion.
  combos$col <- paste0("ov_", combos$lc_name, "_", combos$sf_name, "_", a)
  ov_cols_calculadas <- combos$col
  pend_idx <- integer(0)
  
  for (k in seq_len(nrow(combos))) {
    col <- combos$col[k]
    if (col %in% names(grid_r)) next  # ya calculado en esta misma corrida
    
    ck_ind <- file.path(ckpt_dir, sprintf("ov_%s_%s_%s.rds",
                                          combos$lc_name[k], combos$sf_name[k], a))
    cargado <- FALSE
    if (file.exists(ck_ind)) {
      ck <- readRDS(ck_ind)
      if (isTRUE(ck$complete) && length(ck$area_ha) == nrow(grid_r)) {
        cat(sprintf(">> %s [SKIP] checkpoint individual completo\n", col))
        grid_r[[col]] <- ck$area_ha
        cargado <- TRUE
      }
    }
    if (!cargado) pend_idx <- c(pend_idx, k)
  }
  
  if (length(pend_idx) > 0) {
    combos_pending <- combos[pend_idx, ]
    cat(sprintf("\n>> Calculando %d combinaciones pendientes en un solo pase (%d)\n",
                nrow(combos_pending), ano))
    ck_batch <- file.path(ckpt_dir, sprintf("ov_batch_%s.rds", a))
    mat <- compute_overlap_batch_ha(grid_r, r_lc, r_sf, combos_pending,
                                    ck_file = ck_batch, label = paste0("ano ", ano))
    for (j in seq_len(ncol(mat))) grid_r[[colnames(mat)[j]]] <- mat[, j]
  } else {
    cat("\n  Todas las combinaciones ya estaban resueltas por checkpoints individuales.\n")
  }
  
  # ---- Descartar columnas ov_ con area total = 0 en todo el pais ------------
  sums_ov <- sapply(ov_cols_calculadas, function(cc) sum(grid_r[[cc]], na.rm = TRUE))
  ov_keep <- names(sums_ov)[sums_ov > 0]
  ov_drop <- setdiff(ov_cols_calculadas, ov_keep)
  if (length(ov_drop) > 0) {
    cat(sprintf("\n  Descartando %d combinaciones con area = 0 (de %d posibles) para %d\n",
                length(ov_drop), length(ov_cols_calculadas), ano))
    for (cc in ov_drop) grid_r[[cc]] <- NULL
  }
  ov_cols_por_ano[[a]] <- ov_keep
  cat(sprintf("  -> %d combinaciones conservadas para %d: %s\n",
              length(ov_keep), ano, paste(ov_keep, collapse = ", ")))
  
  grid <- grid_r
  
  # ---- Guardar gpkg + limpiar checkpoints de este ano ------------------------
  cat(sprintf("\nGuardando ano %d en %s...\n", ano, basename(out_gpkg)))
  st_write(grid, out_gpkg, layer = "landcover_safra",
           delete_layer = TRUE, quiet = TRUE)
  cat(sprintf("  -> Guardado (%d columnas)\n", ncol(grid)))
  
  rds_ano <- list.files(ckpt_dir, pattern = sprintf("_%s\\.rds$", a), full.names = TRUE)
  if (length(rds_ano) > 0) {
    file.remove(rds_ano)
    cat(sprintf("  -> %d checkpoint(s) del ano %d eliminados\n", length(rds_ano), ano))
  }
  
  rm(r_lc, r_sf); gc()
}

# ==============================================================================
# RESUMEN
# ==============================================================================

cat("\n", strrep("=", 70), "\n")
cat(" RESUMEN -- Area por clase (ha)\n")
cat(strrep("=", 70), "\n")

for (ano in anos) {
  a <- as.character(ano)
  cat(sprintf("\n--- %d ---\n", ano))
  cat("Landcover:\n")
  for (nm in names(lc_classes)) {
    col <- paste0("lc_", nm, "_", a)
    if (col %in% names(grid)) cat(sprintf("  %-20s | %12.2f ha\n", nm, sum(grid[[col]], na.rm = TRUE)))
  }
  cat("Segunda safra:\n")
  for (nm in names(sf_classes)) {
    col <- paste0("sf_", nm, "_", a)
    if (col %in% names(grid)) cat(sprintf("  %-20s | %12.2f ha\n", nm, sum(grid[[col]], na.rm = TRUE)))
  }
  cat("Coincidencias (solo > 0):\n")
  ov_keep <- ov_cols_por_ano[[a]]
  if (!is.null(ov_keep) && length(ov_keep) > 0) {
    for (col in ov_keep) cat(sprintf("  %-30s | %12.2f ha\n", col, sum(grid[[col]], na.rm = TRUE)))
  } else {
    cat("  (ninguna)\n")
  }
}

cat("\n", strrep("=", 60), "\n")
cat(" CONCLUIDO!\n")
cat(strrep("=", 60), "\n")
cat(sprintf("\nGeoPackage : %s\n", out_gpkg))
cat(sprintf("Celdas     : %d\n", nrow(grid)))
cat(sprintf("Columnas   : %d\n", ncol(grid)))