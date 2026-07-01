################################################################################
# luc_hibrido_v4.R  (versao com checkpoints por classe/celula)
#
# Objetivo: Computar uso da terra (7 classes MAgPIE) como combinacao
#           RESTORE+ v2 / MapBiomas v10 para as 2901 celulas do Brasil
#           (clustermap rev4.117) -- anos: 1995, 2000, 2005, 2010, 2020
#
# Pre-requisito: calc_frac_amz.R ja rodado (gpkg contem area_Mha e frac_amz)
#
# Formula hibrida (anos com RESTORE+: 2000, 2005, 2010, 2020):
#   cls_hyb = cls_rest + cls_mb * (1 - frac_amz)
#
# Ano 1995: NAO existe RESTORE+ disponivel. Estrategia: usar apenas MapBiomas
#           (cobertura total do Brasil), ou seja:
#   cls_1995 = cls_mb_1995
#   (equivalente a tratar frac_amz = 0 dentro da formula hibrida)
#
#   OBS: Em VERSAO 4 todos os anos seguem a mesma nomenclatura SECVEG:
#          mp_secveg_{YEAR}-*.tif  (1995, 2000, 2005, 2010, 2020)
#        Os codigos de classe (2=primforest, 3 e 5=secdforest) sao os mesmos.
#
# Checkpoints:
#   - Diretorio: cells_dir/ckpt/
#   - Um arquivo .rds por (classe x fonte x ano), salvo a cada SAVE_EVERY celulas
#   - Ao retomar, o script pula anos ja completos e continua a classe interrompida
#     exatamente do indice onde parou
#   - Erros GDAL por celula sao tratados como zero (warning + continua)
#   - Ao concluir um ano, os .rds daquele ano sao removidos
#
# FGV Agro -- Projeto Fundo Amazonia
################################################################################

library(sf)
library(terra)

# ==============================================================================
# CONFIGURACAO
# ==============================================================================

SAVE_EVERY <- 200   # salvar checkpoint a cada N celulas

cells_dir  <- "H:/Meu Drive/GV_DATA/MAgPIE/VERSÃO 4/cells"
raster_dir <- "H:/Meu Drive/GV_DATA/MAgPIE/VERSÃO 4/raster"
ckpt_dir   <- file.path(cells_dir, "ckpt")   # diretorio de checkpoints

gpkg_path  <- file.path(cells_dir, "clustermap_rev4.117_BRA.gpkg")
out_gpkg   <- gpkg_path

anos      <- c(1995, 2000, 2005, 2010, 2020)
anos_rest <- c(2000, 2005, 2010, 2020)      # anos com RESTORE+ disponivel

dir.create(ckpt_dir, showWarnings = FALSE, recursive = TRUE)

# Helper: ano tem RESTORE+?
has_restore <- function(ano) ano %in% anos_rest

# Rasters RESTORE+ v2 -- originais em EPSG:10857; sufixo _w = reprojetado para
# EPSG:4326 pela Secao 0 (criado automaticamente se ausente).
# IMPORTANTE: 1995 NAO tem RESTORE+, logo nao entra aqui.
tif_rest_orig <- list(
  "2000" = file.path(raster_dir, "restore_v2_2000.tif"),
  "2005" = file.path(raster_dir, "restore_v2_2005.tif"),
  "2010" = file.path(raster_dir, "restore_v2_2010.tif"),
  "2020" = file.path(raster_dir, "restore_v2_2020.tif")
)

tif_rest <- list(
  "2000" = file.path(raster_dir, "restore_v2_2000_w.tif"),
  "2005" = file.path(raster_dir, "restore_v2_2005_w.tif"),
  "2010" = file.path(raster_dir, "restore_v2_2010_w.tif"),
  "2020" = file.path(raster_dir, "restore_v2_2020_w.tif")
)

# Rasters LUC MapBiomas v10 (EPSG:4326) -- todos os anos incluidos
tif_mb <- list(
  "1995" = file.path(raster_dir, "brazil_coverage_1995.tif"),
  "2000" = file.path(raster_dir, "brazil_coverage_2000.tif"),
  "2005" = file.path(raster_dir, "brazil_coverage_2005.tif"),
  "2010" = file.path(raster_dir, "brazil_coverage_2010.tif"),
  "2020" = file.path(raster_dir, "brazil_coverage_2020.tif")
)

# VRTs SECVEG MapBiomas v10 (EPSG:4326) -- todos os anos incluidos
vrt_secveg <- list(
  "1995" = file.path(raster_dir, "secveg_mosaic_1995.vrt"),
  "2000" = file.path(raster_dir, "secveg_mosaic_2000.vrt"),
  "2005" = file.path(raster_dir, "secveg_mosaic_2005.vrt"),
  "2010" = file.path(raster_dir, "secveg_mosaic_2010.vrt"),
  "2020" = file.path(raster_dir, "secveg_mosaic_2020.vrt")
)

# Padrao (regex) dos tiles SECVEG brutos por ano (mesma nomenclatura para
# todos os anos em VERSAO 4: mp_secveg_{YEAR}-*.tif).
secveg_tile_pattern <- list(
  "1995" = "^mp_secveg_1995-.*\\.tif$",
  "2000" = "^mp_secveg_2000-.*\\.tif$",
  "2005" = "^mp_secveg_2005-.*\\.tif$",
  "2010" = "^mp_secveg_2010-.*\\.tif$",
  "2020" = "^mp_secveg_2020-.*\\.tif$"
)

# ==============================================================================
# DEFINICAO DE CLASSES
# ==============================================================================

secveg_classes <- list(
  primforest = c(2),
  secdforest = c(3, 5)
)

luc_classes <- list(
  cropt    = c(39, 20, 40, 62, 41),
  cropp    = c(46, 47, 35, 48),
  past     = c(15),
  forestry = c(9),
  urban    = c(24)
)

# RESTORE+ v2 -- rotulos atualizados (cropt = 1, cropp = 2)
rest_classes <- list(
  primforest = c(4, 11),
  secdforest = c(6),
  cropt      = c(1),
  cropp      = c(2),
  past       = c(10),
  forestry   = c(5),
  urban      = c(8),
  other      = c(3, 7, 9, 12)
)

classes_diretas <- c("primforest", "secdforest", "cropt", "cropp",
                     "past", "forestry", "urban")

# ==============================================================================
# SECAO 0: REPROJECAO RESTORE+ (EPSG:10857 -> EPSG:4326)
# ==============================================================================

cat(strrep("=", 60), "\n")
cat(" SECAO 0: Reprojecao RESTORE+ v2 -> EPSG:4326\n")
cat(strrep("=", 60), "\n")

for (a in as.character(anos)) {
  if (!has_restore(as.integer(a))) {
    cat(sprintf("  %s: RESTORE+ nao aplicavel, pulando\n", a)); next
  }
  out_w <- tif_rest[[a]]
  if (file.exists(out_w)) {
    cat(sprintf("  %s: ja existe, pulando\n", basename(out_w))); next
  }
  orig <- tif_rest_orig[[a]]
  if (!file.exists(orig)) {
    cat(sprintf("  [AVISO] Original nao encontrado: %s\n", basename(orig))); next
  }
  cat(sprintf("  Reprojetando %s ...\n", basename(orig)))
  r_orig <- rast(orig)
  r_w    <- project(r_orig, "EPSG:4326", method = "near")
  writeRaster(r_w, out_w, overwrite = FALSE)
  cat(sprintf("  -> %s criado\n", basename(out_w)))
  rm(r_orig, r_w); gc()
}

# ==============================================================================
# SECAO 1: MOSAICOS SECVEG (VRT)
# ==============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" SECAO 1: Mosaicos SECVEG MapBiomas v10 (VRT)\n")
cat(strrep("=", 60), "\n")

for (a in as.character(anos)) {
  vrt_path <- vrt_secveg[[a]]
  if (file.exists(vrt_path)) {
    cat(sprintf("  VRT %s ja existe: %s\n", a, basename(vrt_path))); next
  }
  patt <- secveg_tile_pattern[[a]]
  if (is.null(patt)) {
    cat(sprintf("  [AVISO] Sem padrao de tile definido para SECVEG %s -- pulando\n", a))
    next
  }
  tiles <- list.files(raster_dir, pattern = patt, full.names = TRUE)
  cat(sprintf("  SECVEG %s: %d tiles encontrados (padrao: %s)\n",
              a, length(tiles), patt))
  if (length(tiles) == 0) {
    cat(sprintf("  [AVISO] Nenhum tile SECVEG %s -- primforest/secdforest_mb = 0\n", a))
    next
  }
  vrt(tiles, vrt_path)
  cat(sprintf("  -> %s criado\n", basename(vrt_path)))
}

# ==============================================================================
# SECAO 2: LER GRID
# ==============================================================================

cat("\n", strrep("=", 60), "\n")
cat(" SECAO 2: Clustermap rev4.117 BRA\n")
cat(strrep("=", 60), "\n")

grid <- st_read(gpkg_path, quiet = TRUE)
if (is.na(st_crs(grid))) st_crs(grid) <- 4326
cat(sprintf("  -> %d celulas | CRS: %s\n", nrow(grid), st_crs(grid)$input))

for (col in c("area_Mha", "frac_amz")) {
  ok <- col %in% names(grid)
  cat(sprintf("  %-10s: %s\n", col,
              ifelse(ok, "OK", "AUSENTE -- rode calc_frac_amz.R primeiro!")))
  if (!ok) stop(sprintf("Coluna '%s' ausente. Rode calc_frac_amz.R primeiro.", col))
}
cat(sprintf("\n  area_Mha total : %.2f Mha\n", sum(grid$area_Mha)))
cat(sprintf("  frac_amz media : %.3f\n\n", mean(grid$frac_amz)))

cat("Verificando rasters:\n")
for (a in as.character(anos)) {
  files_ano <- tif_mb[[a]]
  if (has_restore(as.integer(a))) files_ano <- c(files_ano, tif_rest[[a]])
  for (f in files_ano) {
    cat(sprintf("  %-60s -> %s\n", basename(f),
                ifelse(file.exists(f), "OK", "NAO ENCONTRADO")))
  }
}
cat("\n")

# ==============================================================================
# SECAO 3: FUNCAO DE COMPUTO COM CHECKPOINT
# ==============================================================================
#
# ck_file : caminho para o .rds de checkpoint (NULL = sem checkpoint)
# save_every : salvar ck_file a cada N celulas (e ao fim)
#
# Retorna vetor area_Mha de comprimento nrow(grid_sf).
#
# Erros GDAL por celula sao capturados: aquela celula recebe 0 e o loop continua.

compute_class_Mha <- function(grid_sf, raster_path, classe_alvo,
                              area_col   = "area_Mha",
                              na_as_zero = FALSE,
                              ck_file    = NULL,
                              save_every = SAVE_EVERY) {

  n        <- nrow(grid_sf)
  area_Mha <- numeric(n)
  start_i  <- 1L

  # ---- Retomar checkpoint se existir ----------------------------------------
  if (!is.null(ck_file) && file.exists(ck_file)) {
    ck <- readRDS(ck_file)
    if (isTRUE(ck$complete) && length(ck$area_Mha) == n) {
      cat("  [SKIP] Checkpoint completo -- pulando.\n")
      return(ck$area_Mha)
    }
    if (length(ck$area_Mha) == n && !is.null(ck$last_i)) {
      area_Mha <- ck$area_Mha
      start_i  <- ck$last_i + 1L
      cat(sprintf("  [RESUME] Continuando da celula %d/%d\n", start_i, n))
    }
  }

  if (start_i > n) {
    cat("  [SKIP] Ja concluido.\n")
    return(area_Mha)
  }

  # ---- Abrir raster ----------------------------------------------------------
  r <- rast(raster_path)
  cat(sprintf("  Raster : %s\n", basename(raster_path)))
  cat(sprintf("  Classes: %s\n", paste(classe_alvo, collapse = ", ")))
  cat(sprintf("  Denom. : %s\n",
              ifelse(na_as_zero, "ncell total", "pixels validos")))
  cat(sprintf("  Dim    : %d x %d | res = %.6f\n", ncol(r), nrow(r), res(r)[1]))
  if (start_i > 1L)
    cat(sprintf("  Progresso anterior: %d celulas ja processadas\n", start_i - 1L))

  t0 <- Sys.time()

  for (i in seq(start_i, n)) {

    # Processar celula com tratamento de erros GDAL
    area_Mha[i] <- tryCatch({
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
      cat(sprintf("\n  [AVISO] Erro GDAL na celula %d: %s -- usando 0\n",
                  i, conditionMessage(e)))
      0
    })

    # Progresso + checkpoint periodico
    if (i %% save_every == 0L || i == n) {
      elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
      n_done  <- i - start_i + 1L
      eta     <- if (i < n) elapsed / n_done * (n - i) else 0
      cat(sprintf("\r    [%3d%%] %d/%d | %.1f min | ETA: %.1f min   ",
                  round(100 * i / n), i, n, elapsed, eta))

      if (!is.null(ck_file)) {
        saveRDS(list(area_Mha = area_Mha,
                     last_i   = i,
                     complete = (i == n)),
                ck_file)
      }
    }
  }

  mins <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  cat(sprintf("\n  -> Total: %.2f Mha (%.1f min)\n", sum(area_Mha), mins))
  return(area_Mha)
}

# ==============================================================================
# SECAO 4: LOOP PRINCIPAL
# ==============================================================================

for (ano in anos) {
  a       <- as.character(ano)
  use_rest <- has_restore(ano)

  cat("\n", strrep("=", 70), "\n")
  cat(sprintf(" ANO: %d%s\n", ano,
              if (!use_rest) "  [somente MapBiomas -- sem RESTORE+]" else ""))
  cat(strrep("=", 70), "\n")

  # ---- Verificar se este ano ja esta completo no gpkg ------------------------
  col_check <- paste0("primforest_", a)
  if (col_check %in% names(grid)) {
    cat(sprintf("  [SKIP] Ano %d ja presente no grid -- pulando.\n", ano))
    next
  }

  # ---- SECVEG MapBiomas v10: primforest + secdforest -------------------------
  if (file.exists(vrt_secveg[[a]])) {
    for (cls in c("primforest", "secdforest")) {
      col_int <- paste0(cls, "_mb_", a)
      # Verificar se coluna intermediaria ja foi carregada de checkpoint anterior
      if (col_int %in% names(grid)) {
        cat(sprintf("\n>> %s (%d) via SECVEG -- ja em memoria, pulando\n", cls, ano))
        next
      }
      cat(sprintf("\n>> %s (%d) via SECVEG MapBiomas v10\n", cls, ano))
      ck_file <- file.path(ckpt_dir, sprintf("%s_mb_%s.rds", cls, a))
      grid[[col_int]] <- compute_class_Mha(
        grid, vrt_secveg[[a]], secveg_classes[[cls]],
        na_as_zero = FALSE, ck_file = ck_file
      )
    }
  } else {
    cat(sprintf("\n  [AVISO] SECVEG %d ausente -- primforest/secdforest_mb = 0\n", ano))
    grid[[paste0("primforest_mb_", a)]] <- 0
    grid[[paste0("secdforest_mb_", a)]] <- 0
  }

  # ---- LUC MapBiomas v10: cropt, cropp, past, forestry, urban ----------------
  if (file.exists(tif_mb[[a]])) {
    for (cls in c("cropt", "cropp", "past", "forestry", "urban")) {
      col_int <- paste0(cls, "_mb_", a)
      if (col_int %in% names(grid)) {
        cat(sprintf("\n>> %s (%d) via LUC -- ja em memoria, pulando\n", cls, ano))
        next
      }
      cat(sprintf("\n>> %s (%d) via LUC MapBiomas v10\n", cls, ano))
      ck_file <- file.path(ckpt_dir, sprintf("%s_mb_%s.rds", cls, a))
      grid[[col_int]] <- compute_class_Mha(
        grid, tif_mb[[a]], luc_classes[[cls]],
        na_as_zero = FALSE, ck_file = ck_file
      )
    }
  } else {
    cat(sprintf("\n  [AVISO] LUC MapBiomas v10 %d ausente -- _mb_ = 0\n", ano))
    for (cls in c("cropt", "cropp", "past", "forestry", "urban"))
      grid[[paste0(cls, "_mb_", a)]] <- 0
  }

  # crop_mb intermediario
  grid[[paste0("crop_mb_", a)]] <-
    grid[[paste0("cropt_mb_", a)]] + grid[[paste0("cropp_mb_", a)]]

  # ---- RESTORE+ v2: todas as classes diretas (SOMENTE anos com RESTORE+) ----
  if (use_rest && file.exists(tif_rest[[a]])) {
    for (cls in classes_diretas) {
      col_int <- paste0(cls, "_rest_", a)
      if (col_int %in% names(grid)) {
        cat(sprintf("\n>> %s (%d) via RESTORE+ -- ja em memoria, pulando\n", cls, ano))
        next
      }
      cat(sprintf("\n>> %s (%d) via RESTORE+ v2\n", cls, ano))
      ck_file <- file.path(ckpt_dir, sprintf("%s_rest_%s.rds", cls, a))
      grid[[col_int]] <- compute_class_Mha(
        grid, tif_rest[[a]], rest_classes[[cls]],
        na_as_zero = TRUE, ck_file = ck_file
      )
    }
  } else if (use_rest) {
    cat(sprintf("\n  [AVISO] RESTORE+ v2 %d ausente -- _rest_ = 0\n", ano))
    for (cls in classes_diretas)
      grid[[paste0(cls, "_rest_", a)]] <- 0
  } else {
    cat(sprintf("\n  [INFO] Ano %d sem RESTORE+: usando somente MapBiomas\n", ano))
  }

  # ---- Combinacao ------------------------------------------------------------
  # Anos com RESTORE+:
  #   {classe}_{ano} = rest + mb * (1 - frac_amz)
  # Anos SEM RESTORE+ (ex.: 1995):
  #   {classe}_{ano} = mb    (MapBiomas cobre todo Brasil)
  cat(sprintf("\n--- Combinando %d ---\n", ano))

  for (cls in classes_diretas) {
    col_out <- paste0(cls, "_", a)
    if (use_rest) {
      grid[[col_out]] <- (grid[[paste0(cls, "_rest_", a)]] +
                            grid[[paste0(cls, "_mb_",   a)]] * (1 - grid$frac_amz))
    } else {
      grid[[col_out]] <- grid[[paste0(cls, "_mb_", a)]]
    }
    cat(sprintf("  %s: %.2f Mha\n", col_out, sum(grid[[col_out]])))
  }

  # crop = cropt + cropp
  grid[[paste0("crop_", a)]] <-
    grid[[paste0("cropt_", a)]] + grid[[paste0("cropp_", a)]]
  cat(sprintf("  crop_%s (cropt+cropp): %.2f Mha\n", a,
              sum(grid[[paste0("crop_", a)]])))

  # other como residual
  grid[[paste0("other_", a)]] <- pmax(
    grid$area_Mha -
      grid[[paste0("primforest_", a)]] -
      grid[[paste0("secdforest_", a)]] -
      grid[[paste0("crop_",       a)]] -
      grid[[paste0("past_",       a)]] -
      grid[[paste0("forestry_",   a)]] -
      grid[[paste0("urban_",      a)]],
    0)
  cat(sprintf("  other_%s: %.2f Mha\n", a,
              sum(grid[[paste0("other_", a)]])))

  # ---- Remover colunas intermediarias ----------------------------------------
  for (cls in c(classes_diretas, "crop")) {
    col_rest <- paste0(cls, "_rest_", a)
    col_mb   <- paste0(cls, "_mb_",   a)
    if (col_rest %in% names(grid)) grid[[col_rest]] <- NULL
    if (col_mb   %in% names(grid)) grid[[col_mb]]   <- NULL
  }

  # ---- Salvar gpkg + limpar checkpoints deste ano ----------------------------
  cat(sprintf("\nSalvando ano %d no gpkg...\n", ano))
  st_write(grid, out_gpkg,
           layer        = "clustermap_rev4.117_BRA",
           delete_layer = TRUE, quiet = TRUE)
  cat(sprintf("  -> Salvo (%d colunas)\n", ncol(grid)))

  # Remover .rds deste ano (ja nao sao necessarios)
  rds_ano <- list.files(ckpt_dir,
                        pattern    = sprintf("_%s\\.rds$", a),
                        full.names = TRUE)
  if (length(rds_ano) > 0) {
    file.remove(rds_ano)
    cat(sprintf("  -> %d checkpoint(s) do ano %d removidos\n",
                length(rds_ano), ano))
  }
}

# ==============================================================================
# SECAO 5: RESUMO
# ==============================================================================

cat("\n", strrep("=", 70), "\n")
cat(" RESUMO -- Area por Classe (Mha) -- Brasil\n")
cat(strrep("=", 70), "\n")

resumo_classes <- c("primforest", "secdforest",
                    "cropt", "cropp", "crop",
                    "past", "forestry", "urban", "other")

resumo_labels <- c(
  primforest = "Floresta Primaria",
  secdforest = "Floresta Secundaria",
  cropt      = "  Agri. Temporaria",
  cropp      = "  Agri. Permanente",
  crop       = "Agricultura (total)",
  past       = "Pastagem",
  forestry   = "Silvicultura",
  urban      = "Area Urbana",
  other      = "Outras"
)

for (ano in anos) {
  a     <- as.character(ano)
  total <- 0
  fonte <- if (has_restore(ano)) "RESTORE+ + MapBiomas" else "somente MapBiomas"
  cat(sprintf("\n--- %d  (%s) ---\n", ano, fonte))
  cat(sprintf("%-22s | %10s\n", "Classe", "Mha"))
  cat(strrep("-", 36), "\n")
  for (cls in resumo_classes) {
    col <- paste0(cls, "_", a)
    v   <- if (col %in% names(grid)) sum(grid[[col]], na.rm = TRUE) else NA
    cat(sprintf("%-22s | %s\n", resumo_labels[cls],
                ifelse(is.na(v), "   ---   ", sprintf("%10.2f", v))))
    if (!is.na(v) && !cls %in% c("cropt", "cropp")) total <- total + v
  }
  cat(strrep("-", 36), "\n")
  cat(sprintf("%-22s | %10.2f\n", "TOTAL",    total))
  cat(sprintf("%-22s | %10.2f\n", "area_Mha", sum(grid$area_Mha)))
}

# ==============================================================================
cat("\n", strrep("=", 60), "\n")
cat(" CONCLUIDO!\n")
cat(strrep("=", 60), "\n")
cat(sprintf("\nGeoPackage : %s\n", out_gpkg))
cat(sprintf("Celulas BR : %d\n",  nrow(grid)))
cat(sprintf("Colunas    : %d\n",  ncol(grid)))
cat("\nColunas de uso da terra:\n")
col_luc <- sort(grep(
  paste0("^(", paste(resumo_classes, collapse = "|"), ")_\\d{4}$"),
  names(grid), value = TRUE, perl = TRUE))
cat(paste(" ", col_luc, collapse = "\n"), "\n")

