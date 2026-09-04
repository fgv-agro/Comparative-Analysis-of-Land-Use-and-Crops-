################################################################################
# agricultural_use_numcycles_extract.R
#
# Objetivo: Extraer, por celda de una grilla vectorial (gpkg), el area en
#           HECTAREAS cubierta por:
#             (a) 5 clases de uso agricola (landcover MapBiomas) por ano
#             (b) 2 clases de numero de ciclos de cultivo (MODIS MCD12Q2)
#                 por ano: 1, 2, 
#             (c) TODAS las combinaciones posibles landcover x NumCycles
#                 por ano (5 x 2 = 10 posibles), conservando solo las
#                 que tengan area > 0 en todo el pais
#
# ALINEAMIENTO TEMPORAL:
#   Landcover disponible : 2000, 2005, 2010, 2015, 2020, 2024
#   MODIS NumCycles      : 2001, 2005, 2010, 2015, 2020, 2024
#   Estrategia de match  : para cada ano de landcover se usa el ano de
#   MODIS mas cercano disponible (ver tabla YEAR_MAP abajo). 
#
# Adaptado de agricultural_use_safra_extract.R
# FGV Agro
################################################################################

library(sf)
library(terra)

# ==============================================================================
# CONFIGURACION
# ==============================================================================

SAVE_EVERY <- 200

# --- Grilla de celdas ---------------------------------------------------------
gpkg_path <- "~/clustermap_rev4.117_BRA.gpkg"
gpkg_layer <- NA   # NA = primera/unica capa

if (gpkg_path == "") stop("Falta completar 'gpkg_path'.")

cells_dir <- dirname(gpkg_path)
ckpt_dir  <- file.path(cells_dir, "ckpt_landcover_numcycles")
dir.create(ckpt_dir, showWarnings = FALSE, recursive = TRUE)

out_gpkg <- file.path(
  cells_dir,
  paste0(tools::file_path_sans_ext(basename(gpkg_path)),
         "_landcover_numcycles.gpkg")
)

# --- Carpeta rasters landcover -----------------------------------------------
lc_dir <- "/MapBiomas"

# --- Carpeta rasters MODIS NumCycles -----------------------------------------
nc_dir <- "/MODIS"

# ==============================================================================
# ALINEAMIENTO TEMPORAL landcover <-> MODIS NumCycles
# ==============================================================================
# Columna izquierda  = ano de landcover (usada para nombrar columnas)
# Columna derecha    = ano de MODIS a usar para ese landcover
# Si no hay MODIS disponible para un ano -> NA -> ese ano se omite
# ==============================================================================

YEAR_MAP <- data.frame(
  lc_year = c(2000L, 2005L, 2010L, 2015L, 2020L, 2024L),
  nc_year = c(
    NA_integer_,
    2001L,   # MODIS 2001 <- landcover 2000 (mas cercano disponible)
    2005L,
    2010L,
    2015L,
    2020L,
    2024L
  ),
  stringsAsFactors = FALSE
)

# Eliminar filas sin MODIS disponible
YEAR_MAP <- YEAR_MAP[!is.na(YEAR_MAP$nc_year), ]
cat("Pares ano landcover <-> MODIS NumCycles:\n")
print(YEAR_MAP, row.names = FALSE)
cat("\n")

anos <- YEAR_MAP$lc_year   # anos activos para procesar

# --- Rasters landcover (agricultural_use) ------------------------------------
tif_lc <- list(
  "2000" = file.path(lc_dir, "2000_agriculture_agricultural_use_1-1-1_79884444-c164-4e1f-b66c-d6717be6762c.tif"),
  "2005" = file.path(lc_dir, "2005_agriculture_agricultural_use_1-1-1_54bb182d-7202-4627-8c00-4570b81f38e0.tif"),
  "2010" = file.path(lc_dir, "2010_agriculture_agricultural_use_1-1-1_5f2913b8-9e70-4f07-850b-bc8af4bc1955 (1).tif"),
  "2015" = file.path(lc_dir, "2015_agriculture_agricultural_use_1-1-1_be32f69a-8b18-43dd-9cf8-79ac2e3eb3f3.tif"),
  "2020" = file.path(lc_dir, "2020_agriculture_agricultural_use_1-1-1_71e7d03a-058b-430d-8889-bce50e22f8bc.tif"),
  "2024" = file.path(lc_dir, "2024_agriculture_agricultural_use_1-1-1_0174bfb9-84b1-4443-91db-5213994eeb55.tif")
)

# --- Rasters MODIS NumCycles (MCD12Q2) ---------------------------------------
# Nombre de archivo: MCD12Q2_NumCycles_{ano}_Brasil.tif
tif_nc <- setNames(
  lapply(c(2001, 2005, 2010, 2015, 2020, 2024), function(y)
    file.path(nc_dir, sprintf("MCD12Q2_NumCycles_%d_Brasil.tif", y))
  ),
  as.character(c(2001, 2005, 2010, 2015, 2020, 2024))
)

# ==============================================================================
# DEFINICION DE CLASES
# ==============================================================================

# Landcover (MapBiomas) -- 5 clases
lc_classes <- c(
  cana            = 20L,
  soja            = 39L,
  arroz           = 40L,
  outras_lav_temp = 41L,
  algodao         = 62L
)

# NumCycles MODIS -- 2 clases de ciclos
# Valor 1 = un ciclo (cultivo simple)
# Valor 2 = dos ciclos (doble cultivo)
nc_classes <- list(
  ciclos_1    = 1L,
  ciclos_2    = 2L
  )

# Combinaciones posibles: 5 lc x 2 nc = 10 por ano
combos <- expand.grid(
  lc_name = names(lc_classes),
  nc_name = names(nc_classes),
  stringsAsFactors = FALSE
)
combos$lc_code <- lc_classes[combos$lc_name]
# nc_code es un vector posiblemente multiple, lo guardamos como lista
combos$nc_codes <- nc_classes[combos$nc_name]

cat(sprintf("Clases landcover: %d | Clases NumCycles: %d | Combinaciones/ano: %d\n\n",
            length(lc_classes), length(nc_classes), nrow(combos)))

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

if (!"area_ha" %in% names(grid)) {
  cat("  Calculando area_ha desde la geometria...\n")
  grid$area_ha <- as.numeric(st_area(grid)) / 10000
} else {
  cat("  Columna area_ha ya existente -- reutilizando.\n")
}
cat(sprintf("  area_ha total: %.2f ha\n\n", sum(grid$area_ha)))

# Verificar existencia de rasters
cat("Verificando rasters:\n")
for (row in seq_len(nrow(YEAR_MAP))) {
  lc_y <- as.character(YEAR_MAP$lc_year[row])
  nc_y <- as.character(YEAR_MAP$nc_year[row])
  f_lc <- tif_lc[[lc_y]]
  f_nc <- tif_nc[[nc_y]]
  cat(sprintf("  LC %s  -> %s\n", lc_y,
              ifelse(file.exists(f_lc), "OK", paste("NO ENCONTRADO:", basename(f_lc)))))
  cat(sprintf("  NC %s  -> %s\n", nc_y,
              ifelse(file.exists(f_nc), "OK", paste("NO ENCONTRADO:", basename(f_nc)))))
}
cat("\n")

# ==============================================================================
# FUNCIONES DE COMPUTO (identicas al script original, adaptadas para nc)
# ==============================================================================

grid_in_crs <- function(grid_sf, r) {
  if (st_crs(grid_sf) == st_crs(crs(r))) grid_sf else st_transform(grid_sf, crs(r))
}

# ---- Area de UNA clase (o conjunto de valores) por celda --------------------
compute_class_ha <- function(grid_sf, r, classe_alvo,
                             area_col    = "area_ha",
                             na_as_zero  = TRUE,
                             ck_file     = NULL,
                             save_every  = SAVE_EVERY,
                             label       = "",
                             resample_to = NULL) {
  n       <- nrow(grid_sf)
  area_ha <- numeric(n)
  start_i <- 1L

  if (!is.null(ck_file) && file.exists(ck_file)) {
    ck <- readRDS(ck_file)
    if (isTRUE(ck$complete) && length(ck$area_ha) == n) {
      cat("  [SKIP] Checkpoint completo\n"); return(ck$area_ha)
    }
    if (length(ck$area_ha) == n && !is.null(ck$last_i)) {
      area_ha <- ck$area_ha; start_i <- ck$last_i + 1L
      cat(sprintf("  [RESUME] Desde celda %d/%d\n", start_i, n))
    }
  }
  if (start_i > n) { cat("  [SKIP]\n"); return(area_ha) }

  cat(sprintf("  %s | valores: %s | denom: %s\n", label,
              paste(classe_alvo, collapse = ","),
              ifelse(na_as_zero, "ncell total", "pixeles validos")))

  t0 <- Sys.time()
  for (i in seq(start_i, n)) {
    area_ha[i] <- tryCatch({
      bb       <- st_bbox(grid_sf[i, ])
      r_cell   <- crop(r, ext(bb["xmin"], bb["xmax"], bb["ymin"], bb["ymax"]))
      if (!is.null(resample_to)) {
        ref_cell <- crop(resample_to, ext(bb["xmin"], bb["xmax"], bb["ymin"], bb["ymax"]))
        if (!is.null(ref_cell) && ncell(ref_cell) > 0)
          r_cell <- resample(r_cell, ref_cell, method = "near")
      }
      if (is.null(r_cell) || ncell(r_cell) == 0) { 0 } else {
        total_px <- if (na_as_zero) ncell(r_cell) else {
          ncell(r_cell) - as.integer(global(is.na(r_cell), "sum")[1,1])
        }
        if (total_px == 0) { 0 } else {
          ft       <- freq(r_cell)
          n_cl     <- sum(ft$count[ft$value %in% classe_alvo], na.rm = TRUE)
          (n_cl / total_px) * grid_sf[[area_col]][i]
        }
      }
    }, error = function(e) {
      cat(sprintf("\n  [AVISO] Celda %d: %s\n", i, conditionMessage(e))); 0
    })

    if (i %% save_every == 0L || i == n) {
      el  <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
      eta <- if (i < n) el / (i - start_i + 1L) * (n - i) else 0
      cat(sprintf("\r    [%3d%%] %d/%d | %.1f min | ETA %.1f min   ",
                  round(100*i/n), i, n, el, eta))
      if (!is.null(ck_file))
        saveRDS(list(area_ha = area_ha, last_i = i, complete = (i == n)), ck_file)
    }
  }
  cat(sprintf("\n  -> Total: %.2f ha (%.1f min)\n",
              sum(area_ha), as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  area_ha
}

# ---- Coincidencias landcover x NumCycles en UN SOLO PASE por celda ---------
compute_overlap_batch_ha <- function(grid_sf, r_lc, r_nc, combos_pend,
                                     area_col        = "area_ha",
                                     ck_file         = NULL,
                                     save_every      = SAVE_EVERY,
                                     label           = "",
                                     nc_needs_resamp = FALSE) {
  n   <- nrow(grid_sf)
  m   <- nrow(combos_pend)
  mat <- matrix(0, nrow = n, ncol = m,
                dimnames = list(NULL, combos_pend$col))
  start_i <- 1L

  if (!is.null(ck_file) && file.exists(ck_file)) {
    ck <- readRDS(ck_file)
    same <- !is.null(ck$mat) && nrow(ck$mat) == n && ncol(ck$mat) == m &&
            all(colnames(ck$mat) == colnames(mat))
    if (same && isTRUE(ck$complete)) {
      cat("  [SKIP] Checkpoint de lote completo\n"); return(ck$mat)
    }
    if (same && !is.null(ck$last_i)) {
      mat <- ck$mat; start_i <- ck$last_i + 1L
      cat(sprintf("  [RESUME] Lote desde celda %d/%d\n", start_i, n))
    }
  }
  if (start_i > n) { cat("  [SKIP] Lote ya concluido\n"); return(mat) }

  cat(sprintf("  %s | %d combinaciones lc x NumCycles en un solo pase\n", label, m))

   MULT <- 100L

  t0 <- Sys.time()
  for (i in seq(start_i, n)) {
    tryCatch({
      bb         <- st_bbox(grid_sf[i, ])
      cell_ext   <- ext(bb["xmin"], bb["xmax"], bb["ymin"], bb["ymax"])
      r_lc_cell  <- crop(r_lc, cell_ext)
      r_nc_cell  <- crop(r_nc, cell_ext)
      # Resample nc al grid de lc (solo el recorte, sin tocar el raster global)
      if (nc_needs_resamp && !is.null(r_nc_cell) && ncell(r_nc_cell) > 0)
        r_nc_cell <- resample(r_nc_cell, r_lc_cell, method = "near")

      if (!is.null(r_lc_cell) && ncell(r_lc_cell) > 0 &&
          !is.null(r_nc_cell) && ncell(r_nc_cell)  > 0) {

        total_px <- ncell(r_lc_cell)

        if (total_px > 0) {
          # Raster combinado: lc * MULT + nc
          comb <- r_lc_cell * MULT + r_nc_cell
          ft   <- freq(comb)

          for (j in seq_len(m)) {
            # Para ciclos_3mas (nc_codes puede ser 3:7) sumamos todos
            codes_j  <- as.integer(combos_pend$lc_code[j]) * MULT +
                        as.integer(combos_pend$nc_codes[[j]])
            n_comb   <- sum(ft$count[ft$value %in% codes_j], na.rm = TRUE)
            mat[i, j] <- (n_comb / total_px) * grid_sf[[area_col]][i]
          }
        }
      }
    }, error = function(e) {
      cat(sprintf("\n  [AVISO] Celda %d: %s\n", i, conditionMessage(e)))
    })

    if (i %% save_every == 0L || i == n) {
      el  <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
      eta <- if (i < n) el / (i - start_i + 1L) * (n - i) else 0
      cat(sprintf("\r    [%3d%%] %d/%d | %.1f min | ETA %.1f min   ",
                  round(100*i/n), i, n, el, eta))
      if (!is.null(ck_file))
        saveRDS(list(mat = mat, last_i = i, complete = (i == n)), ck_file)
    }
  }
  cat(sprintf("\n  -> Lote listo (%.1f min)\n",
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  mat
}

# ==============================================================================
# LOOP PRINCIPAL
# ==============================================================================

ov_cols_por_ano <- list()

for (row in seq_len(nrow(YEAR_MAP))) {

  lc_y <- YEAR_MAP$lc_year[row]
  nc_y <- YEAR_MAP$nc_year[row]
  a    <- as.character(lc_y)   # sufijo de columnas = ano landcover

  cat("\n", strrep("=", 70), "\n")
  cat(sprintf(" ANO LC: %d | ANO MODIS NumCycles: %d\n", lc_y, nc_y))
  cat(strrep("=", 70), "\n")

  # ---- Saltar si ya esta completo en el gpkg --------------------------------
  marker_col <- paste0("lc_", names(lc_classes)[1], "_", a)
  if (file.exists(out_gpkg)) {
    g_check <- tryCatch(st_read(out_gpkg, quiet = TRUE), error = function(e) NULL)
    if (!is.null(g_check) && marker_col %in% names(g_check)) {
      cat(sprintf("  [SKIP] Ano %d ya en %s\n", lc_y, basename(out_gpkg)))
      grid <- g_check
      next
    }
  }

  # ---- Verificar rasters ----------------------------------------------------
  f_lc <- tif_lc[[a]]
  f_nc <- tif_nc[[as.character(nc_y)]]
  if (!file.exists(f_lc)) stop(sprintf("Raster LC no encontrado: %s", f_lc))
  if (!file.exists(f_nc)) stop(sprintf("Raster NC no encontrado: %s", f_nc))

  r_lc <- rast(f_lc)
  r_nc <- rast(f_nc)

  # ---- Alinear grilla al CRS del landcover ----------------------------------
  grid_r <- grid_in_crs(grid, r_lc)

  # ---- Verificar si r_nc necesita reproyeccion por celda --------------------
    NC_NEEDS_RESAMPLE <- !compareGeom(r_lc, r_nc, stopOnError = FALSE)
  if (NC_NEEDS_RESAMPLE) {
    cat("  [INFO] r_lc y r_nc tienen grids distintos -> resample por celda (near).\n")
    cat("         CRS r_lc:", as.character(crs(r_lc, describe=TRUE)$code), "\n")
    cat("         CRS r_nc:", as.character(crs(r_nc, describe=TRUE)$code), "\n")
  }

  # ---- Landcover: 5 clases -> lc_{clase}_{ano_lc} -------------------------
  for (nm in names(lc_classes)) {
    col <- paste0("lc_", nm, "_", a)
    if (col %in% names(grid_r)) { cat(sprintf(">> %s ya en memoria\n", col)); next }
    cat(sprintf("\n>> %s\n", col))
    ck <- file.path(ckpt_dir, sprintf("lc_%s_%s.rds", nm, a))
    grid_r[[col]] <- compute_class_ha(grid_r, r_lc, lc_classes[[nm]],
                                      ck_file = ck, label = col)
  }

  # ---- NumCycles: 2 clases -> nc_{clase}_{ano_lc} -------------------------
  # Nota: el sufijo usa el ano de LANDCOVER para mantener coherencia de
  # columnas (el ano MODIS queda documentado en YEAR_MAP)
  for (nm in names(nc_classes)) {
    col <- paste0("nc_", nm, "_", a)
    if (col %in% names(grid_r)) { cat(sprintf(">> %s ya en memoria\n", col)); next }
    cat(sprintf("\n>> %s\n", col))
    ck <- file.path(ckpt_dir, sprintf("nc_%s_%s.rds", nm, a))
    grid_r[[col]] <- compute_class_ha(grid_r, r_nc, nc_classes[[nm]],
                                      ck_file = ck, label = col,
                                      resample_to = if (NC_NEEDS_RESAMPLE) r_lc else NULL)
  }

  # ---- Coincidencias landcover x NumCycles ----------------------------------
  combos$col <- paste0("ov_", combos$lc_name, "_", combos$nc_name, "_", a)
  ov_cols_calculadas <- combos$col
  pend_idx <- integer(0)

  for (k in seq_len(nrow(combos))) {
    col    <- combos$col[k]
    if (col %in% names(grid_r)) next

    ck_ind <- file.path(ckpt_dir,
                        sprintf("ov_%s_%s_%s.rds", combos$lc_name[k], combos$nc_name[k], a))
    cargado <- FALSE
    if (file.exists(ck_ind)) {
      ck <- readRDS(ck_ind)
      if (isTRUE(ck$complete) && length(ck$area_ha) == nrow(grid_r)) {
        cat(sprintf(">> %s [SKIP ckpt individual]\n", col))
        grid_r[[col]] <- ck$area_ha; cargado <- TRUE
      }
    }
    if (!cargado) pend_idx <- c(pend_idx, k)
  }

  if (length(pend_idx) > 0) {
    combos_pend <- combos[pend_idx, ]
    cat(sprintf("\n>> Calculando %d combinaciones pendientes (ano LC %d / MODIS %d)\n",
                nrow(combos_pend), lc_y, nc_y))
    ck_batch <- file.path(ckpt_dir, sprintf("ov_batch_%s.rds", a))
    mat <- compute_overlap_batch_ha(grid_r, r_lc, r_nc, combos_pend,
                                    ck_file         = ck_batch,
                                    label           = sprintf("LC%d/NC%d", lc_y, nc_y),
                                    nc_needs_resamp = NC_NEEDS_RESAMPLE)
    for (j in seq_len(ncol(mat))) grid_r[[colnames(mat)[j]]] <- mat[, j]
  } else {
    cat("\n  Todas las combinaciones resueltas por checkpoints.\n")
  }

  # ---- Descartar columnas ov_ con area = 0 en todo el pais -----------------
  sums_ov <- sapply(ov_cols_calculadas, function(cc) sum(grid_r[[cc]], na.rm = TRUE))
  ov_keep  <- names(sums_ov)[sums_ov > 0]
  ov_drop  <- setdiff(ov_cols_calculadas, ov_keep)
  if (length(ov_drop) > 0) {
    cat(sprintf("\n  Descartando %d combinaciones con area = 0 (de %d posibles)\n",
                length(ov_drop), length(ov_cols_calculadas)))
    for (cc in ov_drop) grid_r[[cc]] <- NULL
  }
  ov_cols_por_ano[[a]] <- ov_keep
  cat(sprintf("  -> %d combinaciones conservadas para LC%d\n", length(ov_keep), lc_y))

  grid <- grid_r

  # ---- Guardar gpkg ---------------------------------------------------------
  cat(sprintf("\nGuardando en %s...\n", basename(out_gpkg)))
  st_write(grid, out_gpkg, layer = "landcover_numcycles",
           delete_layer = TRUE, quiet = TRUE)
  cat(sprintf("  -> %d celdas | %d columnas\n", nrow(grid), ncol(grid)))

  # Limpiar checkpoints del ano procesado
  rds_ano <- list.files(ckpt_dir, pattern = sprintf("_%s\\.rds$", a), full.names = TRUE)
  if (length(rds_ano) > 0) {
    file.remove(rds_ano)
    cat(sprintf("  -> %d checkpoint(s) eliminados\n", length(rds_ano)))
  }

  rm(r_lc, r_nc); gc()
}

# ==============================================================================
# RESUMEN
# ==============================================================================

cat("\n", strrep("=", 70), "\n")
cat(" RESUMEN -- Area por clase (ha)\n")
cat(strrep("=", 70), "\n")

for (row in seq_len(nrow(YEAR_MAP))) {
  lc_y <- YEAR_MAP$lc_year[row]
  nc_y <- YEAR_MAP$nc_year[row]
  a    <- as.character(lc_y)

  cat(sprintf("\n--- LC %d / MODIS %d ---\n", lc_y, nc_y))

  cat("Landcover:\n")
  for (nm in names(lc_classes)) {
    col <- paste0("lc_", nm, "_", a)
    if (col %in% names(grid))
      cat(sprintf("  %-20s | %12.2f ha\n", nm, sum(grid[[col]], na.rm = TRUE)))
  }

  cat("NumCycles:\n")
  for (nm in names(nc_classes)) {
    col <- paste0("nc_", nm, "_", a)
    if (col %in% names(grid))
      cat(sprintf("  %-20s | %12.2f ha\n", nm, sum(grid[[col]], na.rm = TRUE)))
  }

  cat("Coincidencias lc x nc (solo > 0):\n")
  ov_keep <- ov_cols_por_ano[[a]]
  if (!is.null(ov_keep) && length(ov_keep) > 0) {
    for (col in ov_keep)
      cat(sprintf("  %-35s | %12.2f ha\n", col, sum(grid[[col]], na.rm = TRUE)))
  } else {
    cat("  (ninguna con area > 0)\n")
  }
}

cat("\n", strrep("=", 60), "\n")
cat(" CONCLUIDO!\n")
cat(strrep("=", 60), "\n")
cat(sprintf("\nGeoPackage : %s\n", out_gpkg))
cat(sprintf("Celdas     : %d\n", nrow(grid)))
cat(sprintf("Columnas   : %d\n", ncol(grid)))
cat(sprintf("\nNota: sufijo de columnas = ano de LANDCOVER.\n"))
cat(sprintf("Correspondencia LC <-> MODIS documentada en YEAR_MAP:\n"))
print(YEAR_MAP, row.names = FALSE)
