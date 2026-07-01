################################################################################
# pam_culturas_v4.R
#
# Objetivo: Espacializar dados PAM-IBGE de TODAS as culturas MAgPIE nas
#           celulas MAgPIE (clustermap rev4.117_BRA) com ponderacao HIBRIDA,
#           coerente com luc_hibrido_v4.R.
#           Anos: 1995, 2000, 2005, 2010, 2020.
#
# Fonte PAM: H:/Meu Drive/GV_DATA/MAgPIE/VERSAO 4/cells/PAM_MAGPIE_Culturas_13c4d.gpkg
#   - CRS : EPSG:4674 (SIRGAS 2000) -- sera reprojetado para 4326 do grid
#   - 5.573 municipios, 13 culturas x 5 anos (colunas {cultura}_{ano})
#   - Nomenclatura mista (ex.: Soybean_2000, maize_2000, cottn_pro_2000);
#     o casamento e case-insensitive.
#
# Culturas processadas (13 com serie completa, conferido em 2026-04):
#   tece, trce, maize, Rice_pro, Soybean, Groundnut, Oilpalm, Puls_pro,
#   Potato, Cassav_sp, Sugr_cane, Others, Cottn_pro
#
# Auto-detecao: o script casa cada cultura com a coluna {cultura}_{ano}
# no gpkg (case-insensitive). Uma checagem defensiva ainda marca como
# ZERO qualquer coluna totalmente zerada que venha a aparecer em releases
# futuros dos dados, e pula essa combinacao sem erro.
#
# Formula de peso (por fragmento municipio x celula, por ano):
#
#   Anos com RESTORE+ (2000, 2005, 2010, 2020):
#     cropt_hyb_frag = cropt_px_rest_frag
#                    + cropt_px_mb_frag * (1 - frac_amz_celula)
#
#   Ano SEM RESTORE+ (1995):
#     cropt_hyb_frag = cropt_px_mb_frag
#
#   w_frag  = cropt_hyb_frag / sum(cropt_hyb_frag)  [por municipio x ano]
#   mvalue  = PAM_value * w_frag * CONV_FACTOR
#
# Onde:
#   cropt_px_rest_frag  = pixels RESTORE+ v2 com classes cropt no fragmento
#                         (classe: 1) -- raster _w.tif em EPSG:4326
#   cropt_px_mb_frag    = pixels MapBiomas v10 com classes cropt no fragmento
#                         (classes: 39, 20, 40, 62, 41)
#   frac_amz_celula     = fracao Amazonia da celula MAgPIE (coluna do gpkg)
#
# Coerencia: esta formula e a mesma de luc_hibrido_v4.R aplicada ao nivel
#            do fragmento (sub-celular), garantindo consistencia metodologica.
#
# RESTORE+ cobre apenas a Amazonia Legal -> fora dela retorna 0 por design.
# Para celulas com frac_amz = 0, o peso reduz a cropt_px_mb puro.
#
# Fallback: municipio sem nenhum pixel cropt_hyb > 0 -> peso por area geografica.
#
# Preservacao: o script LE todas as colunas existentes do gpkg (incluindo as
#              do 02_luc_hibrido_v4.R), ADICIONA as colunas de cultura e
#              regrava o layer. Nada do que ja existe e perdido.
#
# Checkpoints (retomaveis):
#   ckpt/inter_df.rds                   -- intersecao vetorizada (1x)
#   ckpt/cropt_px_rest_{ano}.rds        -- pixels RESTORE+ por fragmento x ano
#   ckpt/cropt_px_mb_{ano}.rds          -- pixels MapBiomas por fragmento x ano
#
# FGV Agro -- Projeto Fundo Amazonia
################################################################################

library(sf)
library(terra)
library(dplyr)
library(tidyr)

sf::sf_use_s2(FALSE)

# ==============================================================================
# CONFIGURACAO
# ==============================================================================

cells_dir  <- "H:/Meu Drive/GV_DATA/MAgPIE/VERSÃO 4/cells"
raster_dir <- "H:/Meu Drive/GV_DATA/MAgPIE/VERSÃO 4/raster"
ckpt_dir   <- file.path(cells_dir, "ckpt")

gpkg_path <- file.path(cells_dir, "clustermap_rev4.117_BRA.gpkg")
pam_path  <- file.path(cells_dir, "PAM_MAGPIE_Culturas_13c4d.gpkg")

anos      <- c(1995, 2000, 2005, 2010, 2020)
anos_rest <- c(2000, 2005, 2010, 2020)   # anos com RESTORE+ disponivel

# 13 culturas MAgPIE com serie completa na PAM-IBGE
MAGPIE_CROPS <- c(
  "tece", "trce", "maize", "Rice_pro", "Soybean", "Groundnut",
  "Oilpalm", "Puls_pro", "Potato", "Cassav_sp", "Sugr_cane",
  "Others", "Cottn_pro"
)

# Classes cropt -- MapBiomas v10
CROPT_MB   <- c(39, 20, 40, 62, 41)
# Classes cropt -- RESTORE+ v2 (rotulo atualizado: cropt = 1)
CROPT_REST <- c(1)

# Conversao ha -> Mha
CONV_FACTOR <- 1 / 1e6

SAVE_EVERY  <- 500L

# Rasters MapBiomas v10 (EPSG:4326)
tif_mb <- list(
  "1995" = file.path(raster_dir, "brazil_coverage_1995.tif"),
  "2000" = file.path(raster_dir, "brazil_coverage_2000.tif"),
  "2005" = file.path(raster_dir, "brazil_coverage_2005.tif"),
  "2010" = file.path(raster_dir, "brazil_coverage_2010.tif"),
  "2020" = file.path(raster_dir, "brazil_coverage_2020.tif")
)

# Rasters RESTORE+ v2 reprojetados (mesmo sufixo _w do luc_hibrido_v4.R)
# 1995 NAO tem RESTORE+.
tif_rest <- list(
  "2000" = file.path(raster_dir, "restore_v2_2000_w.tif"),
  "2005" = file.path(raster_dir, "restore_v2_2005_w.tif"),
  "2010" = file.path(raster_dir, "restore_v2_2010_w.tif"),
  "2020" = file.path(raster_dir, "restore_v2_2020_w.tif")
)

has_restore <- function(ano) ano %in% anos_rest

dir.create(ckpt_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# FUNCAO AUXILIAR: contar pixels de classes-alvo em um bbox
# ==============================================================================

count_px <- function(r, bbox_vec, classes) {
  # bbox_vec: c(xmin, xmax, ymin, ymax)
  tryCatch({
    cell_ext <- ext(bbox_vec[1], bbox_vec[2], bbox_vec[3], bbox_vec[4])
    r_frag   <- crop(r, cell_ext)
    if (is.null(r_frag) || ncell(r_frag) == 0) return(0L)
    ft <- freq(r_frag)
    as.integer(sum(ft$count[ft$value %in% classes], na.rm = TRUE))
  }, error = function(e) 0L)
}

# ==============================================================================
# SECAO 1: CARREGAR DADOS
# ==============================================================================

cat(strrep("=", 60), "\n")
cat(" SECAO 1: Carregando dados\n")
cat(strrep("=", 60), "\n\n")

grid <- st_read(gpkg_path, quiet = TRUE)
if (is.na(st_crs(grid))) st_crs(grid) <- 4326
cat(sprintf("  Grid  : %d celulas | CRS: %s\n", nrow(grid), st_crs(grid)$input))

# Verificar colunas obrigatorias do grid
for (col in c("area_Mha", "frac_amz")) {
  if (!col %in% names(grid))
    stop(sprintf("Coluna '%s' ausente no grid. Rode luc_hibrido_v4.R primeiro.", col))
}
cat(sprintf("  frac_amz : min=%.3f  max=%.3f  media=%.3f\n",
            min(grid$frac_amz), max(grid$frac_amz), mean(grid$frac_amz)))

grid$.cell_id <- seq_len(nrow(grid))

# PAM: agora em GeoPackage com todas as culturas MAgPIE
pam <- st_read(pam_path, quiet = TRUE)
cat(sprintf("  PAM   : %d municipios | CRS: %s\n", nrow(pam), st_crs(pam)$input))
pam$.muni_id <- seq_len(nrow(pam))

# ---- AUTO-DETECCAO DE COLUNAS CULTURA x ANO --------------------------------
# Vamos casar cada cultura MAgPIE com um ou mais anos possiveis.
# Padroes aceitos (case-insensitive): {cultura}_{ano}, {cultura}.{ano}, {cultura}{ano}
detect_pam_column <- function(pam_names, cultura, ano) {
  patts <- c(
    sprintf("^%s_%d$",  cultura, ano),
    sprintf("^%s\\.%d$", cultura, ano),
    sprintf("^%s%d$",   cultura, ano)
  )
  for (p in patts) {
    hit <- grep(p, pam_names, ignore.case = TRUE, value = TRUE)
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}

pam_names <- names(pam)

culturas <- list()
# Para cada candidato, tambem chamar um teste de "coluna nao-zero":
# culturas existentes mas zeradas sao puladas para evitar carga inutil.
is_coluna_vazia <- function(col_name) {
  # Considera "vazia" se soma absoluta = 0 (tudo zero ou NA)
  v <- suppressWarnings(as.numeric(pam[[col_name]]))
  s <- sum(v, na.rm = TRUE)
  isTRUE(!is.finite(s) || s == 0)
}

cat("\n  Culturas detectadas na PAM (OK = col existe e tem dados; ZERO = existe mas e toda zero):\n")
header_anos <- paste(sprintf("%-6s", as.character(anos)), collapse = "  ")
cat(sprintf("  %-12s  %s\n", "cultura", header_anos))
cat("  ", strrep("-", 14 + 8 * length(anos)), "\n", sep = "")

for (cult in MAGPIE_CROPS) {
  cols_per_year <- sapply(anos, function(a) detect_pam_column(pam_names, cult, a))
  names(cols_per_year) <- as.character(anos)

  # Marca como NA as colunas que existem mas estao totalmente zeradas
  cols_ok <- cols_per_year
  marcas  <- character(length(anos))
  for (i in seq_along(anos)) {
    cp <- cols_per_year[i]
    if (is.na(cp)) {
      marcas[i] <- "  -  "
    } else if (is_coluna_vazia(cp)) {
      marcas[i] <- " ZERO"
      cols_ok[i] <- NA_character_   # nao usa no processamento
    } else {
      marcas[i] <- "  OK "
    }
  }
  names(cols_ok) <- as.character(anos)

  tem_dados <- any(!is.na(cols_ok))
  cat(sprintf("  %-12s  %s\n", cult, paste(marcas, collapse = "  ")))
  if (tem_dados) {
    culturas[[cult]] <- list(
      nome       = cult,
      out_prefix = tolower(cult),         # ex.: Soybean -> soybean
      cols       = cols_ok
    )
  }
}

n_combi <- sum(sapply(culturas, function(c) sum(!is.na(c$cols))))
cat(sprintf("\n  -> %d culturas com ao menos 1 ano de dados (total: %d cruzamentos cultura x ano).\n\n",
            length(culturas), n_combi))
if (length(culturas) == 0)
  stop("Nenhuma coluna cultura x ano com dados em PAM_MAGPIE_Culturas_13c4d.gpkg.")

# Todas as colunas da PAM que vamos usar (somente as com dados)
cols_usar <- unique(unlist(lapply(culturas, function(c) c$cols[!is.na(c$cols)])))
cat(sprintf("  Colunas PAM a usar (%d): %s\n\n",
            length(cols_usar), paste(cols_usar, collapse = ", ")))

# Verificar rasters
cat("  Rasters:\n")
for (a in as.character(anos)) {
  tifm <- tif_mb[[a]]
  ok_m <- file.exists(tifm)
  cat(sprintf("    MapBiomas %s : %s\n", a,
              ifelse(ok_m, "OK", paste("NAO ENCONTRADO ->", tifm))))
  if (!ok_m)
    stop("Raster MapBiomas ausente: ", tifm)

  if (has_restore(as.integer(a))) {
    tifr <- tif_rest[[a]]
    ok_r <- file.exists(tifr)
    cat(sprintf("    RESTORE+  %s : %s\n", a,
                ifelse(ok_r, "OK", paste("NAO ENCONTRADO ->", tifr))))
    if (!ok_r)
      cat("    [INFO] RESTORE+ ausente -> cropt_rest = 0 (so Amazon, OK fora dela)\n")
  } else {
    cat(sprintf("    RESTORE+  %s : n/a (so MapBiomas)\n", a))
  }
}
cat("\n")

# ==============================================================================
# SECAO 2: HARMONIZACAO DE CRS
# ==============================================================================

cat(strrep("=", 60), "\n")
cat(" SECAO 2: Harmonizacao de CRS\n")
cat(strrep("=", 60), "\n\n")

crs_ref <- st_crs(grid)
cat(sprintf("  CRS grid : %s\n", crs_ref$input))
cat(sprintf("  CRS PAM  : %s\n", st_crs(pam)$input))

if (!isTRUE(st_crs(pam) == crs_ref)) {
  cat(sprintf("  Reprojetando PAM -> %s ...\n", crs_ref$input))
  pam <- st_transform(pam, crs_ref)
} else {
  cat("  PAM ja esta no mesmo CRS do grid\n")
}
pam  <- st_make_valid(pam)
grid <- st_make_valid(grid)
cat("  CRS e geometrias OK\n\n")

# ==============================================================================
# SECAO 3: INTERSECAO PAM x GRID  (checkpoint: inter_df.rds)
# ==============================================================================

cat(strrep("=", 60), "\n")
cat(" SECAO 3: Intersecao PAM x Grid\n")
cat(strrep("=", 60), "\n\n")

inter_ck <- file.path(ckpt_dir, "inter_df.rds")

if (file.exists(inter_ck)) {
  cat("  [RESUME] Carregando de checkpoint...\n")
  ck_inter    <- readRDS(inter_ck)
  inter_df    <- ck_inter$inter_df
  inter_bbox  <- ck_inter$inter_bbox
  cat(sprintf("  -> %d fragmentos\n", nrow(inter_df)))

  # Validar que o checkpoint contem as colunas PAM necessarias.
  # Se algo novo (ex.: novo ano 2020 ou nova cultura), refazer.
  faltando <- setdiff(cols_usar, names(inter_df))
  if (length(faltando) > 0) {
    cat(sprintf("  [INVALID] Checkpoint nao cobre %d colunas (%s). Recalculando...\n",
                length(faltando), paste(faltando, collapse = ", ")))
    file.remove(inter_ck)
  } else {
    cat("\n")
  }
}

if (!file.exists(inter_ck)) {
  cat("  Calculando st_intersection...\n")
  t0 <- Sys.time()

  cols_pam_sel <- c(".muni_id", cols_usar)
  inter_raw    <- st_intersection(pam[, cols_pam_sel],
                                  grid[, c(".cell_id", "frac_amz")])

  cat(sprintf("  -> %d fragmentos (%.1f min)\n",
              nrow(inter_raw),
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))

  inter_raw$.inter_area_m2 <- as.numeric(st_area(inter_raw))
  inter_raw$.frag_idx      <- seq_len(nrow(inter_raw))

  # Guardar bbox de cada fragmento (para recorte raster)
  inter_bbox <- lapply(seq_len(nrow(inter_raw)), function(i) {
    bb <- st_bbox(inter_raw[i, ])
    c(bb["xmin"], bb["xmax"], bb["ymin"], bb["ymax"])
  })

  # Area geografica do municipio
  muni_areas <- data.frame(
    .muni_id       = pam$.muni_id,
    .muni_area_m2  = as.numeric(st_area(pam))
  )

  inter_df <- inter_raw %>%
    as.data.frame() %>%
    select(-any_of(c("geom", "geometry"))) %>%
    left_join(muni_areas, by = ".muni_id") %>%
    filter(.inter_area_m2 > 0, is.finite(.inter_area_m2))

  saveRDS(list(inter_df = inter_df, inter_bbox = inter_bbox), inter_ck)
  cat(sprintf("  -> Checkpoint salvo (%d fragmentos validos)\n\n", nrow(inter_df)))
  rm(inter_raw); gc()
}

n_frags <- nrow(inter_df)

# ==============================================================================
# SECAO 4: PIXELS CROPT POR FRAGMENTO x ANO (RESTORE+ e MapBiomas)
# ==============================================================================

cat(strrep("=", 60), "\n")
cat(" SECAO 4: Contagem de pixels cropt por fragmento x ano\n")
cat(strrep("=", 60), "\n\n")

px_rest_list <- list()
px_mb_list   <- list()

for (a in as.character(anos)) {

  fontes <- if (has_restore(as.integer(a))) c("rest", "mb") else c("mb")

  for (fonte in fontes) {

    ck_file  <- file.path(ckpt_dir, sprintf("cropt_px_%s_%s.rds", fonte, a))
    tif_path <- if (fonte == "rest") tif_rest[[a]] else tif_mb[[a]]
    classes  <- if (fonte == "rest") CROPT_REST else CROPT_MB
    label    <- if (fonte == "rest") "RESTORE+" else "MapBiomas"

    # Se raster ausente (RESTORE+ fora da Amazonia e esperado), preenche zeros
    if (!file.exists(tif_path)) {
      cat(sprintf("  [SKIP] %s %s ausente -> zeros\n", label, a))
      if (fonte == "rest") px_rest_list[[a]] <- integer(n_frags)
      else                 px_mb_list[[a]]   <- integer(n_frags)
      next
    }

    if (file.exists(ck_file)) {
      ck <- readRDS(ck_file)
      if (isTRUE(ck$complete) && length(ck$cropt_px) == n_frags) {
        cat(sprintf("  [SKIP] %s %s ja completo\n", label, a))
        if (fonte == "rest") px_rest_list[[a]] <- ck$cropt_px
        else                 px_mb_list[[a]]   <- ck$cropt_px
        next
      }
      cropt_px <- ck$cropt_px
      start_i  <- ck$last_i + 1L
      cat(sprintf("  [RESUME] %s %s -> frag %d/%d\n", label, a, start_i, n_frags))
    } else {
      cropt_px <- integer(n_frags)
      start_i  <- 1L
      cat(sprintf("  Iniciando %s %s (%d fragmentos)...\n", label, a, n_frags))
    }

    r  <- rast(tif_path)
    t0 <- Sys.time()

    for (i in seq(start_i, n_frags)) {
      cropt_px[i] <- count_px(r, inter_bbox[[inter_df$.frag_idx[i]]], classes)

      if (i %% SAVE_EVERY == 0L || i == n_frags) {
        elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
        n_done  <- i - start_i + 1L
        eta     <- if (i < n_frags) elapsed / n_done * (n_frags - i) else 0
        cat(sprintf("\r    [%3d%%] %d/%d | %.1f min | ETA %.1f min   ",
                    round(100 * i / n_frags), i, n_frags, elapsed, eta))
        saveRDS(list(cropt_px = cropt_px, last_i = i,
                     complete = (i == n_frags)), ck_file)
      }
    }
    cat(sprintf("\n  -> %s %s: %d fragmentos com cropt > 0\n\n",
                label, a, sum(cropt_px > 0)))
    if (fonte == "rest") px_rest_list[[a]] <- cropt_px
    else                 px_mb_list[[a]]   <- cropt_px
    rm(r); gc()
  }

  # Para anos sem RESTORE+, garantir px_rest_list[[a]] = 0 (simplifica sec 5)
  if (!has_restore(as.integer(a))) {
    px_rest_list[[a]] <- integer(n_frags)
  }
}

# ==============================================================================
# SECAO 5: PESO HIBRIDO E DISTRIBUICAO
# ==============================================================================

cat(strrep("=", 60), "\n")
cat(" SECAO 5: Pesos hibridos e distribuicao PAM\n")
cat(strrep("=", 60), "\n\n")

# Tabela de resumo por cultura x ano (coletada ao longo do loop)
resumo_rows <- list()

for (a in as.character(anos)) {
  ano      <- as.integer(a)
  use_rest <- has_restore(ano)
  fonte_txt <- if (use_rest) "hibrido RESTORE+/MapBiomas" else "somente MapBiomas"
  cat(sprintf("  --- Ano %d  (%s) ---\n", ano, fonte_txt))

  df_ano <- inter_df %>%
    mutate(
      # Formula hibrida ao nivel do fragmento
      # Anos com RESTORE+ : rest + mb*(1-frac_amz)
      # Anos SEM RESTORE+ : mb (rest_list ja e zero)
      .cropt_hyb = if (use_rest)
        px_rest_list[[a]][seq_len(n_frags)] +
        px_mb_list[[a]][seq_len(n_frags)] * (1 - frac_amz)
      else
        px_mb_list[[a]][seq_len(n_frags)]
    )

  # Somar cropt_hyb por municipio
  muni_cropt <- df_ano %>%
    group_by(.muni_id) %>%
    summarise(.cropt_muni = sum(.cropt_hyb, na.rm = TRUE), .groups = "drop")

  df_ano <- df_ano %>%
    left_join(muni_cropt, by = ".muni_id") %>%
    mutate(
      .w_hyb  = ifelse(.cropt_muni > 0,
                       .cropt_hyb / .cropt_muni,
                       NA_real_),
      # Fallback geografico para municipios sem nenhum cropt_hyb
      .w_area = .inter_area_m2 / .muni_area_m2,
      .w      = ifelse(!is.na(.w_hyb), .w_hyb, .w_area)
    )

  n_fallback <- df_ano %>%
    filter(is.na(.w_hyb)) %>%
    pull(.muni_id) %>%
    n_distinct()
  if (n_fallback > 0)
    cat(sprintf("    [AVISO] %d municipios sem cropt_hyb -> fallback area geografica\n",
                n_fallback))

  for (cultura in culturas) {
    col_pam <- cultura$cols[[a]]
    if (is.na(col_pam)) {
      next  # cultura sem dado pra este ano
    }
    col_out <- paste0(cultura$out_prefix, "_", a)

    if (!col_pam %in% names(df_ano)) {
      cat(sprintf("    [SKIP] %s ausente no fragmento\n", col_pam)); next
    }

    agg <- df_ano %>%
      mutate(mvalue = .data[[col_pam]] * .w * CONV_FACTOR) %>%
      filter(!is.na(mvalue), is.finite(mvalue)) %>%
      group_by(.cell_id) %>%
      summarise(!!col_out := sum(mvalue, na.rm = TRUE), .groups = "drop")

    if (col_out %in% names(grid)) grid[[col_out]] <- NULL
    grid <- grid %>%
      left_join(agg, by = ".cell_id") %>%
      mutate(!!col_out := replace_na(.data[[col_out]], 0))

    total_grid <- sum(grid[[col_out]], na.rm = TRUE)
    total_pam  <- sum(pam[[col_pam]], na.rm = TRUE) * CONV_FACTOR
    pct <- if (total_pam > 0) total_grid / total_pam * 100 else NA

    cat(sprintf("    %-16s -> %-18s | PAM: %9.4f Mha | Grid: %9.4f Mha | %.2f%%\n",
                col_pam, col_out, total_pam, total_grid, pct))

    resumo_rows[[length(resumo_rows) + 1]] <- data.frame(
      cultura   = cultura$nome,
      ano       = ano,
      col_pam   = col_pam,
      col_out   = col_out,
      PAM_Mha   = total_pam,
      Grid_Mha  = total_grid,
      pct       = pct
    )
  }
  cat("\n")
}

# ==============================================================================
# SECAO 6: SALVAR GPKG E RESUMO
# ==============================================================================
#
# IMPORTANTE: o grid foi lido com TODAS as colunas pre-existentes (incluindo
# as colunas de uso da terra do 02_luc_hibrido_v4.R). Aqui apenas adicionamos
# as colunas de cultura -- nada do que ja existia e perdido.
# delete_layer = TRUE substitui o layer pelo grid em memoria, que ja contem
# tudo (antigas + novas).

cat(strrep("=", 60), "\n")
cat(" SECAO 6: Salvando GeoPackage\n")
cat(strrep("=", 60), "\n\n")

grid$.cell_id <- NULL

st_write(grid, gpkg_path,
         layer        = "clustermap_rev4.117_BRA",
         delete_layer = TRUE,
         quiet        = TRUE)

cat(sprintf("  -> Salvo: %d celulas | %d colunas\n\n", nrow(grid), ncol(grid)))

# Resumo em CSV
if (length(resumo_rows) > 0) {
  resumo_df <- do.call(rbind, resumo_rows)
  csv_path  <- file.path(cells_dir, "resumo_pam_culturas.csv")
  write.csv(resumo_df, csv_path, row.names = FALSE, fileEncoding = "UTF-8")
  cat(sprintf("  Resumo CSV : %s\n\n", csv_path))
}

# ==============================================================================
# SECAO 7: RESUMO NO CONSOLE
# ==============================================================================

cat(strrep("=", 60), "\n")
cat(" RESUMO -- Area Colhida PAM (Mha) -- pesos hibridos RESTORE+/MapBiomas\n")
cat(strrep("=", 60), "\n\n")

header_anos <- paste(sprintf("%12s", as.character(anos)), collapse = "")
cat(sprintf("%-16s %s\n", "Cultura", header_anos))
cat(strrep("-", 16 + 12 * length(anos)), "\n")

for (cultura in culturas) {
  vals <- sapply(anos, function(ano) {
    col <- paste0(cultura$out_prefix, "_", ano)
    if (col %in% names(grid))
      sprintf("%12.4f", sum(grid[[col]], na.rm = TRUE))
    else
      sprintf("%12s", "---")
  })
  cat(sprintf("%-16s %s\n", cultura$out_prefix, paste(vals, collapse = "")))
}

cat("\n")
cat(strrep("=", 60), "\n")
cat(" CONCLUIDO!\n")
cat(strrep("=", 60), "\n")
cat(sprintf("\nGeoPackage : %s\n", gpkg_path))
cat(sprintf("Celulas BR : %d\n",  nrow(grid)))
cat(sprintf("Colunas    : %d\n",  ncol(grid)))
cat("\nColunas adicionadas (prefixos de cultura MAgPIE):\n")
prefix_regex <- paste0("^(", paste(tolower(MAGPIE_CROPS), collapse = "|"), ")_\\d{4}$")
cols_new <- sort(grep(prefix_regex, names(grid), value = TRUE, ignore.case = TRUE))
cat(paste(" ", cols_new, collapse = "\n"), "\n")
