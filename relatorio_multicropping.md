# Multicropping and Second Crop Analysis

**Agricultural Landcover vs. Second Crop vs. Number of Crop Cycles**
**MapBiomas and MODIS MCD12Q2**

Brazil — 2000, 2005, 2010, 2015, 2020 and 2024

*Support for adapting the MAgPIE model to the Brazilian context.*

**Fundo Amazônia Project**
FGV Agro — Getúlio Vargas Foundation
Internal Report — August 2026

## **Summary**

- **[Highlights](#highlights)**
- **[1. Data Sources and Temporal Coverage](#1-data-sources-and-temporal-coverage)**
  - [1.1 Products Descriptions](#11-products-descriptions)
  - [1.2 Methodological Note](#12-methodological-note)
- **[2. Agricultural Use by Class](#2-agricultural-use-by-class)**
- **[3. Second Crop Area](#3-second-crop-area)**
- **[4. Agricultural Use vs. Second Crop: Spatial Overlap](#4-agricultural-use-vs-second-crop-spatial-overlap)**
  - [4.1 Maize as a second crop](#41-maize-as-a-second-crop)
  - [4.2 Cotton as a second crop](#42-cotton-as-a-second-crop)
  - [4.3 Other Temporary Crops as a second crop](#43-other-temporary-crops-as-a-second-crop)
  - [4.4 Shifting composition within each first-crop class](#44-shifting-composition-within-each-first-crop-class)
- **[5. Number of Crop Cycles — MODIS MCD12Q2](#5-number-of-crop-cycles-modis-mcd12q2)**
  - [5.1 Overall trends in single and double-cycle area](#51-overall-trends-in-single-and-double-cycle-area)
  - [5.1 NumCycles cross-tabulated with landcover classes](#51-numcycles-cross-tabulated-with-landcover-classes)
- **[6. Comparison with PAM/IBGE Statistics](#6-comparison-with-pamibge-statistics)**
  - [6.1 Crops with direct correspondence](#61-crops-with-direct-correspondence)
  - [6.2 Crops without direct correspondence: Other Temporary Crops](#62-crops-without-direct-correspondence-other-temporary-crops)
  - [6.3 Maize: decomposition into first and second crop](#63-maize-decomposition-into-first-and-second-crop)
  - [6.4 Implications for modelling](#64-implications-for-modelling)
- **[7. Discussion](#7-discussion)**
- **[8. Conclusion](#8-conclusion)**
- **[Appendix A — Agricultural Use Maps](#appendix-a-agricultural-use-maps)**
- **[Appendix B — Second Crop Maps](#appendix-b-second-crop-maps)**
- **[Appendix C — Soybean x second crop Maps](#appendix-c-soybean-x-second-crop-maps)**
- **[Appendix D — Other Temporary Crops x Second Crop](#appendix-d-other-temporary-crops-x-second-crop)**
- **[Appendix E — Cotton x Second Crop](#appendix-e-cotton-x-second-crop)**
- **[Appendix F — Agricultural Use x 2 Cycles](#appendix-f-agricultural-use-x-2-cycles)**
- **[Appendix G — Soybean: PAM vs. MapBiomas](#appendix-g-soybean-pam-vs-mapbiomas)**

## **Executive Summary**

The Fundo Amazônia Project, implemented by FGV Agro, is adapting the MAgPIE, Model of Agricultural Production and its Impact on the Environment, to adequately represent land-use dynamics in Brazil. One of the key challenges being addressed is the spatial distribution of agricultural lands under double cropping — known in Brazil as the *safra-safrinha* system. To this end, three complementary remote-sensing products were analysed: the **Agricultural Use** (1985–2024) and the **Second Crop** (2000–2024) products, both derived from MapBiomas (Collection 10, 30 m resolution), and the number of vegetation cycles per year derived from the MODIS **Land Cover Dynamics** product (MCD12Q2 phenology product, 500 m resolution, 2001–2024). Official municipal agricultural statistics from PAM/IBGE were also incorporated to validate and contextualise the remotely sensed cropland estimates. 

The analysis covers six benchmark years: 2000, 2005, 2010, 2015, 2020 and 2024, enabling a long-run view of agricultural expansion and intensification across Brazil. All data were extracted and aggregated for the 2,901 cells of the MAgPIE global grid, providing spatially explicit inputs suitable for model calibration and scenario analysis. 

The **Agricultural Use** product is derived from Brazil’s annual land cover and land use maps and distinguishes nine crop classes across two levels. The first level separates Temporary from Perennial Crops. The second level includes Soybean, Sugarcane, Rice, Cotton and Other Temporary Crops (under Temporary Crops), and Coffee, Citrus, Oilpalm and Other Perennial Crops (under Perennial Crops). Given the focus on double cropping, only the five Temporary Crops classes were retained for this analysis. The **Second Crop** product comprises three classes of secondary crops, that are: Maize, Cotton and Other Temporary Crops, where the latter is defined as short- or medium-term agricultural crops with a vegetative cycle of less than one year that require replanting after harvest. This product has a limited spatial coverage, excluding the states of Rio Grande do Sul and Santa Catarina in the south, as well as some northern, northeastern and southeastern states. To compensate for this limitation, the **Number of Crop Cycles** product, that has a global coverage, was also used. This third product identifies the number of successive crop cycles in each pixel per year, based on phenological transitions, with values ranging from zero to seven; for this analysis, only pixels with one and two cycles were considered.

The analytical approach consisted of two steps. First, the Agricultural Use and Second Crop maps were spatially overlaid for each benchmark year, registering all coincident pixels across the fifteen possible class combinations (five temporary crop classes by three second-crop classes) and calculating the total area in Mha occupied within each MAgPIE cell. Second, to extend coverage to regions excluded from the Second Crop product, the Number of Crop Cycles was crossed with the Temporary Crops classes using the same approach. This second overlay also serves as a proxy for estimating wheat as a second crop.

As general statistics, and only considering the **temporary crops**, its coverage expanded substantially over the study period, rising from approximately 33.25 Mha in 2000 to 59.93 Mha in 2024 — an increase of over 80% in 24 years. Soybean drove most of this expansion in absolute terms, growing from 16.0 Mha in 2000 to 40.6 Mha in 2024 and consolidating its position as the dominant crop class across Brazil. Other temporary crops declined in relative share despite remaining significant in absolute area. The **second crop** underwent a structural transformation over the period. Its total area more than tripled between 2000 and 2024, from approximately 7.47 Mha to 23.68 Mha, driven almost entirely by the expansion of maize as a winter relay crop. By 2024, maize accounted for over 68% of all second-crop areas nationally. **Crop cycle**, measured independently, corroborates the significant expansion of the second-crop per year after 2010.

The **spatial overlap analysis** reveals that second-crop expansion over 2000–2024 was dominated by maize safrinha grown after soybean, which grew from 1.26 Mha in 2000 to 13.98 Mha in 2024, when accounted for 95% of all maize second-crop area nationally. Cotton as a second crop also expanded markedly, rising from 0.26 Mha to 2.49 Mha, with soybean similarly serving as the dominant first crop (97% of the total by 2024). Other temporary crops followed a different trajectory: total area remained relatively stable between 5.5 and 6.6 Mha throughout the period, but its internal composition shifted substantially. The share falling on soybean parcels grew from 61% in 2000 to 93% in 2024, while the share on other temporary crops as first crop declined from 39% to just 7%, reflecting the progressive consolidation of soybean as the near-universal first crop in double-cropping systems across Brazil. Across all three second-crop classes, the pattern is consistent: soybean is not only expanding in area but increasingly providing the productive base on which all forms of double cropping are built.

The **cross-tabulation** of agricultural use with MODIS-derived crop cycles confirms the intensification patterns identified in the second-crop mapping, while also revealing important differences across crops. Soybean stands out as the class with the largest and fastest-growing double-cycle area, expanding from 2.47 Mha in 2000 to 11.65 Mha in 2024 — consistent with the *safrinha* system documented in the second-crop layers — while its single-cycle area also grew substantially, from 12.07 to 24.76 Mha, reflecting continued frontier expansion alongside intensification. Other temporary crops show a contrasting pattern: single-cycle area declined from 9.23 to 5.85 Mha over the period, suggesting that this class is being partially displaced or consolidated into soybean systems, while double-cycle area remained modest and relatively stable (around 1.0–1.6 Mha). Sugarcane single-cycle area more than doubled from 3.36 to 9.35 Mha by 2020 before retreating slightly to 8.04 Mha in 2024, with double-cycle readings fluctuating around 0.1–1.1 Mha. Rice and cotton remain small in absolute terms across both cycle classes, though both show a gradual increase in double-cycle pixels after 2015. 

**Comparison with official statistics** from PAM/IBGE reveals a mixed picture. For soybean and sugarcane, MapBiomas agricultural use area estimates show strong agreement with declared planted areas, with discrepancies generally within ±10% across benchmark years. These crops are mapped as specific, spectrally distinct classes in the MapBiomas legend, which facilitates accurate detection. For rice and cotton, however, MapBiomas systematically under-estimates area relative to PAM, with gaps exceeding 70% in some years. This divergence likely reflects the partial absorption of these crops into the broader 'Other Temporary Crops' class in the MapBiomas methodology. For maize, direct comparison requires decomposition: since PAM reports total maize area (first plus second crop combined) while MapBiomas only maps maize as a second crop, the gap between the two sources narrows progressively as the *safrinha* system expands — by 2024, MapBiomas second-crop maize alone accounts for the majority of the total PAM maize area, suggesting that first-season maize has declined substantially relative to the *safrinha*. 

Taken together, these findings document a process of rapid agricultural intensification in Brazil that goes beyond area expansion. The simultaneous growth in soybean area and double-crop adoption reflects a systemic shift in the organisation of Brazilian crop production — one that has major implications for land-use modelling, since it means that a given parcel of agricultural land now generates significantly more output per unit area than it did two decades ago. Adequately representing this intensification in MAgPIE requires not only updated area estimates by crop class, but also spatially explicit information on the prevalence of double cropping and the distribution of cycle intensity across the model grid — precisely the data layers this report provides. 

## **Highlights**

* Agricultural area expansion over 2000–2024 was led by soybean, which became the dominant crop in terms of absolute growth and intensification.

* Double-cropping intensification — the planting of a second crop after soybean harvest — accelerated sharply after 2010. By 2020, over half of the soybean area in Brazil was followed by a second crop, predominantly maize (*safrinha*).

* The soybean–maize rotation now accounts for over 90% of the maize second-crop area (2024), consistent with the well-documented structural shift in Brazilian maize production from a primary summer crop to a winter relay crop after soybean.

* The MODIS NumCycles product independently confirms the intensification signal: the area with two crop cycles per year expanded significantly after 2010 and is spatially concentrated in the Cerrado and MATOPIBA regions — exactly where soybean–maize double-cropping is practised.

* Comparison with PAM/IBGE statistics confirms strong agreement for soybean and sugarcane, but reveals persistent under-representation of rice and cotton by MapBiomas landcover.

* The joint analysis of landcover, second crop and NumCycles provides a multi-source, cross-validated picture of Brazilian agricultural intensification. The spatial overlap layers are the key output for MAgPIE model calibration and scenario analysis.

## **1. Data Sources and Temporal Coverage**

This analysis draws on three complementary remote-sensing products and one set of official agricultural statistics (Table 1), covering six benchmark years: 2000, 2005, 2010, 2015, 2020 and 2024. All raster data were aggregated to the 2,901 cells of the MAgPIE global grid, which provides the spatial unit of analysis throughout the report.

### **1.1 Products Descriptions**

*Agricultural Use (MapBiomas, Collection 10)*

The Agricultural Use product is derived from Brazil's annual land cover and land use mapping produced by MapBiomas, using Landsat satellite imagery at 30 m spatial resolution. It is available annually from 1985 to 2024 and classifies agricultural areas at two hierarchical levels. The first level distinguishes Temporary from Perennial Crops. The second level disaggregates each into specific classes: Soybean, Sugarcane, Rice, Cotton and Other Temporary Crops under the temporary category, and Coffee, Citrus, Oil Palm and Other Perennial Crops under the perennial category. The Other Temporary Crops class is a residual category that aggregates a wide range of commodities — including cassava, groundnut, potato, pulses, and temperate and tropical cereals — that are individually too small or spatially fragmented to be mapped as separate classes at the national scale. Given the focus of this report on double cropping, only the five Temporary Crop classes were retained for analysis. The product is produced at levels 3 and 4 of the MapBiomas Landcover legend hierarchy. 

*Second Crop (MapBiomas, Collection 10)*

The Second Crop product maps agricultural land use classes associated with the second harvest season, also derived from Landsat imagery at 30 m resolution and available annually from 2000 to 2024. It comprises three classes: Maize, Cotton, and Other Temporary Crops — defined as short- or medium-term crops with a vegetative cycle of less than one year that require replanting after each harvest. Unlike the Agricultural Use product, which maps the dominant crop of the main growing season, the Second Crop product specifically targets the *safrinha* — the relay crop planted after the first harvest. An important limitation of this product is its incomplete spatial coverage: it does not include the states of Rio Grande do Sul and Santa Catarina in the south, both significant agricultural producers, nor some of the northern, northeastern and southeastern states of Brazil, where double cropping is less prevalent or occurs under different seasonal calendars. This geographic restriction means that national totals derived from this product should be interpreted as conservative estimates, particularly for rice- and wheat-based double-cropping systems in the southern states. 

*Number of Crop Cycles — MODIS MCD12Q2 (beta)*

To compensate for the spatial limitations of the Second Crop product and to provide an independent validation signal, the analysis also incorporates the Number of Crop Cycles product derived from the MODIS Land Cover Dynamics dataset (MCD12Q2). This product identifies the number of successive crop cycles per pixel per year by detecting phenological transitions — from vegetation emergence to senescence — in the MODIS EVI2 time series. It is produced at 500 m spatial resolution from combined Terra and Aqua MODIS observations, available annually from 2001 to 2024, and has global coverage, making it suitable for filling the regional gaps left by the MapBiomas Second Crop product. A key characteristic of this product is that it is crop-agnostic: it captures any recurring vegetative cycle, including commercial grain production, cover crops, ratoon crops and natural regrowth. As a result, in some regions the area classified as having more than one cycle per year may exceed official survey estimates, which focus exclusively on harvested grain production. For this analysis, only pixels with one or two detected cycles were retained — eliminating the small fraction of pixels with three or more cycles, which are likely artefacts or reflect highly specific irrigated systems, as well as pixels with zero detected cycles. Values ranging from zero to seven cycles are theoretically possible under the product specification, but the distribution across Brazil is heavily concentrated at one and two cycles. This layer is used both as an independent cross-check on the Second Crop mapping and as a proxy for estimating double-crop intensity in regions not covered by the MapBiomas product — including, importantly, as an indicator for wheat cultivation as a winter second crop in southern states. 

#### **Table 1.** Data source products.

| Product | Resolution | Sensor | Period | Benchmark years  | Source |
| ----- | ----- | ----- | ----- | ----- | ----- |
| **MapBiomas Agricultural Use (landcover)** | 30 m | Landsat | 1985–2024 | 2000, 2005, 2010, 2015, 2020, 2024 | [Uso agrícola](https://brasil.mapbiomas.org/iniciativas-e-produtos/cobertura-e-uso-da-terra/agricultura/uso-agricola/) |
| **MapBiomas Second Crop (double cropping)** | 30 m | Landsat | 2000–2024 | 2000, 2005, 2010, 2015, 2020, 2024 | [Uso agrícola – 2ª Safra](https://brasil.mapbiomas.org/iniciativas-e-produtos/cobertura-e-uso-da-terra/agricultura/uso-agricola-2a-safra/) |
| **MODIS MCD12Q2 — NumCycles** | 500 m | MODIS | 2001–2024 | 2001→LC2000, 2005, 2010, 2015, 2020, 2024 | [MCD12Q2.006](https://developers.google.com/earth-engine/datasets/catalog/MODIS_061_MCD12Q2?hl=pt-br) |
| **PAM/IBGE (official crop statistics)** | Municipal | Survey | Annual | 2000, 2005, 2010, 2015, 2020 | [PAM](https://data-basis.org/dataset/fc403b40-a7e1-40e7-9efe-910847b45a69?raw_data_source=6548f6d5-7ebf-4305-b8f9-4062b4d36fad) |
| **MAgPIE grid (spatial aggregation unit)** | ~50 × 50 km | — | Fixed | 2,901 cells covering Brazil | [MAgPIE](https://publications.pik-potsdam.de/rest/items/item_18526_1/component/file_18527/content) |

*Temporal alignment (Agricultural Use ↔ NumCycles): MODIS 2001 is used as the NumCycles reference for the landcover year 2000 (closest available). All other benchmark years share the same year across both products*

### **1.2 Methodological Note**

Data from MapBiomas (Collection 10) and MODIS MCD12Q2 were extracted for the six benchmark years and aggregated to the 2,901 cells of the MAgPIE global grid. The area of each class within each cell was computed as the fraction of pixels of that class over the total number of pixels within the cell boundary, multiplied by the geometric area of the cell in hectares. Before computing overlaps between the MapBiomas and MODIS layers, the NumCycles raster (500 m) was re-projected to the landcover grid (30 m) using nearest-neighbour resampling, in order to preserve the categorical nature of the cycle count values. Spatial coincidences represent the area, in millions of hectares per cell, where both maps assign a pixel to the respective classes simultaneously; only class combinations with a positive national total area are retained in the final dataset. All spatial operations were performed in R using the *terra* and *sf* packages. 

## **2. Agricultural Use by Class**

Total temporary crop area in Brazil expanded from 33.25 Mha in 2000 to 59.93 Mha in 2024, representing an increase of 80% over the 24-year study period (Table 2 and Figure 1). Growth was not linear: the most rapid phase of expansion occurred between 2000 and 2015, when total area grew by more than 21 Mha at an average rate of approximately 1.5 Mha per year (Table 3 and Figure 2). After 2015, the pace slowed considerably, with total area increasing by only 5.6 Mha over the following nine years, suggesting a degree of saturation in the most productive agricultural regions or a shift toward intensification of existing cropland rather than conversion of new land. 

#### **Table 2.** Agricultural area by landcover class (Mha), 2000–2024.

| Class | 2000 | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Soybean** | 15.95 | 22.30 | 24.33 | 30.63 | 36.88 | 40.58 |
| **Sugarcane** | 4.47 | 5.70 | 8.60 | 10.54 | 10.61 | 10.10 |
| **Rice** | 0.64 | 0.67 | 0.73 | 0.99 | 1.15 | 1.05 |
| **Cotton** | 0.01 | 0.07 | 0.13 | 0.13 | 0.19 | 0.16 |
| **Other Temp. Crops** | 12.18 | 11.22 | 13.08 | 12.02 | 10.45 | 8.04 |
| **TOTAL** | **33.25** | **39,96** | **46.87** | **54.31** | **59.28** | **59.93** |

Soybean was by far the dominant driver of expansion throughout the entire period, growing from 15.95 Mha in 2000 to 40.58 Mha in 2024 and accounting for 48% of total temporary crop area at the start of the period and 68% by the end. The largest absolute gains occurred in the sub-periods 2000–2005 (+6.35 Mha) and 2010–2015 (+6.30 Mha), with a further increment of +6.25 Mha between 2015 and 2020. Growth slowed after 2020, adding 3.70 Mha in the final four-year interval — still substantial in absolute terms but reflecting a deceleration consistent with increasing land constraints in the traditional soybean belt and a gradual northward shift of the production frontier into more remote areas of MATOPIBA and the Amazon transition zone. Across all sub-periods, soybean was the only class to record uninterrupted positive growth, underlining its structural role in the reorganisation of Brazilian crop agriculture over the past two decades. 

![Figure reference 1](figuras/figure01.png)

*Figure 1. Agricultural use area by class, 2000–2024 (Mha).*

Sugarcane followed a distinct trajectory, expanding steadily from 4.47 Mha in 2000 to a peak of 10.61 Mha in 2020, an increase of 137%, before contracting slightly to 10.10 Mha in 2024, a decline of 0.52 Mha in the final sub-period. The growth was particularly concentrated in the 2005–2010 interval (+2.91 Mha). Rice and cotton remained small throughout the period in absolute terms, though both recorded proportionally meaningful changes. Rice grew gradually from 0.64 Mha in 2000 to a peak of 1.15 Mha in 2020, with the most notable acceleration occurring between 2010 and 2020 (+0.42 Mha), before declining to 1.05 Mha in 2024. Cotton exhibited more volatile dynamics, growing from a negligible 0.01 Mha in 2000 to 0.19 Mha in 2020, with a slight contraction to 0.16 Mha by 2024. The small absolute size of these classes — together representing less than 2% of total temporary crop area throughout the period — should be interpreted alongside the known underestimation of these crops by MapBiomas relative to PAM/IBGE.

#### **Table 3.** Change in landcover area (Mha), full period 2000–2024.

| Class | Δ 2000–2005 | Δ 2005–2010 | Δ 2010–2015 | Δ 2015–2020 | Δ 2020–2024  |
| ----- | :---: | :---: | :---: | :---: | :---: |
| **Soybean** | 6.354 | 2.025 | 6.304 | 6.254 | 3.701 |
| **Sugarcane** | 1.227 | 2.905 | 1.937 | 0.073 | -0.517 |
| **Rice** | 0.035 | 0.062 | 0.258 | 0.159 | -0.101 |
| **Cotton** | 0.062 | 0.061 | -0.003 | 0.065 | -0.036 |
| **Other Temp. Crops** | -0.955 | 1.861 | -1.059 | -1.570 | -2.410 |

Other Temporary Crops — the residual class aggregating cassava, groundnut, potato, pulses, temperate cereals and other minor commodities — showed the most complex and arguably most revealing trajectory of all the classes. Starting at 12.18 Mha in 2000, the class experienced alternating phases of decline and recovery before entering a sustained contraction after 2010, falling to 8.04 Mha by 2024, its lowest level in the study period. The sub-period change data clarify this pattern: declines of −0.96 Mha (2000–2005), −1.06 Mha (2010–2015) and −1.57 Mha (2015–2020) were punctuated by a recovery of +1.86 Mha in 2005–2010, while the final interval recorded the steepest contraction of all, at −2.41 Mha between 2020 and 2024. 

![Figure reference 2](figuras/figure02.png)

*Figure 2. Changes in agricultural use area 2000→2024 (ΔMha). Green bars = expansion; red bars = contraction.*

Taken as a whole, the Agricultural Use data paint a picture of a crop system undergoing simultaneous extensive and intensive transformation: extensive in the sense that the total farmed area grew by nearly 27 Mha over the study period, and intensive in the sense that the composition of that area shifted markedly toward a small number of high-productivity commodity crops — above all soybean — at the expense of a more diverse agricultural mosaic. This structural convergence has direct implications for the double-cropping patterns analysed in subsequent sections, since the dominance of soybean as a first crop is the primary precondition for the expansion of the *safrinha* system. 

## **3. Second Crop Area**

Total second-crop area grew from 7.47 Mha in 2000 to 23.68 Mha in 2024, representing a more than three-fold increase over the study period (Table 4 and Figure 3). This trajectory contrasts with that of the Agricultural Use classes in an important respect: while primary crop expansion slowed markedly after 2015, second-crop growth accelerated precisely in that period, with total area jumping from 11.80 Mha in 2010 to 18.46 Mha in 2015 — an addition of 6.66 Mha in a single five-year interval, the largest absolute gain recorded across any class and any sub-period in the entire dataset. This divergence between decelerating extensive growth and accelerating intensive growth is one of the central findings of the report, and it points to a structural shift in Brazilian agriculture in which the productivity gains of existing cropland are increasingly driving output growth rather than the conversion of new land. 

#### **Table 4.** Second-crop area by class (Mha), 2000–2024.

| Class (2nd crop) | 2000 | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Maize** | 1.76 | 2.82 | 4.32 | 11.67 | 13.14 | 14.72 |
| **Other Temp. Crops** | 5.45 | 6.56 | 6.62 | 5.74 | 6.44 | 6.47 |
| **Cotton** | 0.26 | 0.70 | 0.87 | 1.05 | 1.58 | 2.49 |
| **TOTAL** | **7.47** | **10.08** | **11.80** | **18.46** | **21.17** | **23.68** |

Maize *safrinha* was overwhelmingly responsible for this expansion. From a modest 1.76 Mha in 2000, maize second-crop area grew to 14.72 Mha in 2024 — an increase of nearly 13 Mha, representing an eight-fold expansion over 24 years (Figure 4). The growth was heavily concentrated in the 2010–2015 sub-period, when maize second-crop area nearly tripled from 4.32 to 11.67 Mha in just five years, reflecting the rapid diffusion of the soybean–maize double-cropping system (Figure 4). Growth continued in subsequent periods, though at a more moderate pace — adding 1.47 Mha between 2015 and 2020 and a further 1.58 Mha between 2020 and 2024. By 2024, maize accounted for 62% of all second-crop area nationally, up from just 24% in 2000, a compositional shift that fundamentally redefines the nature of Brazilian double cropping over this period. The scale of this transformation also has direct implications for the comparison with PAM/IBGE statistics, since PAM reports total maize area — first and second crop combined — making it impossible to directly compare the two sources without decomposition. 

![Figure reference 3](figuras/figure03.png)

*Figure 3 — Stacked bar: Second-crop area by class, 2000–2024 (ha and %) Stacked composition of second-crop area by class — 2000–2024*

Cotton as a second crop grew steadily throughout the period, from 0.26 Mha in 2000 to 2.49 Mha in 2024, with particularly notable acceleration after 2015 (+0.53 Mha between 2015 and 2020, and +0.91 Mha between 2020 and 2024). By 2024, cotton represented approximately 10% of total second-crop area — a share that remains modest in absolute terms but signals an important diversification of the double-cropping system beyond the soybean–maize combination that dominates the national picture.

Other Temporary Crops — the second-crop residual class, capturing relay plantings of crops such as sorghum, millet, sunflower and cover crops — followed a strikingly different and more stable trajectory. Area fluctuated between 5.45 and 6.62 Mha throughout the study period, with no clear directional trend, ending at 6.47 Mha in 2024. This relative stability stands in marked contrast to the explosive growth of maize and the steady rise of cotton, and reflects the heterogeneous and partially substitutable nature of the crops within this class. In proportional terms, however, Other Temporary Crops declined sharply as a share of total second-crop area — from 73% in 2000 to just 27% in 2024 — as maize expanded to dominate the class composition. This compositional shift is itself analytically important: the near-constant absolute area of Other Temporary Crops, combined with its declining share, suggests that the total capacity for relay cropping in Brazil has grown substantially, but that the additional capacity has been captured almost entirely by maize rather than by the more diverse set of secondary crops that characterised the system at the beginning of the period.

![Figure reference 4](figuras/figure04.png)

*Figure 4. Change in second crop area 2000→2024 (ΔMha)*

Taken together, the second-crop data reveal a system that has undergone both quantitative and qualitative transformation. Quantitatively, the total area under double cropping has tripled, adding more than 16 Mha of productive capacity without any additional conversion of primary land. Qualitatively, the system has become significantly more specialised, converging toward a soybean–maize rotation that now defines the dominant agricultural model across Brazil. This specialisation has efficiency advantages — the soybean–maize rotation is one of the most productive and economically efficient cropping systems in tropical agriculture — but it also implies increased exposure to commodity price volatility and climate risks that affect both crops simultaneously. For MAgPIE calibration purposes, the key implication is that second-crop area cannot be treated as a fixed proportion of primary crop area: the ratio of second to first crop has changed dramatically over the period, and continues to evolve, making spatially explicit and temporally resolved data essential for accurate representation of Brazilian agricultural productivity in the model. 

## **4. Agricultural Use vs. Second Crop: Spatial Overlap**

This section presents the complete pixel-level cross-tabulation between the Agricultural Use and Second Crop products for each benchmark year. For each agricultural use × second-crop combination the overlap area (Mha) is reported. The analysis reveals that spatial double cropping — defined here as the simultaneous presence of a first-crop class and a second-crop class within the same pixel and the same year — is not uniformly distributed across crop classes. Of the five temporary crop classes considered, only three show meaningful overlap with any second-crop class: Soybean, Other Temporary Crops and Cotton (Figure 5). Sugarcane and Rice show no detectable overlap with any second-crop class across any benchmark year, which is consistent with their agronomic calendars: sugarcane is a perennial ratoon crop that occupies the same land continuously across seasons and is therefore structurally incompatible with relay cropping, while rice in Brazil is predominantly cultivated as a single-season irrigated crop in the southernmost states, which fall outside the spatial coverage of the MapBiomas Second Crop product entirely. 

![Figure reference 5](figuras/figure05.png)

*Figure 5. Spatial overlap area (Mha) by agricultural use × second-crop combination, 2000–2024*

### **4.1 Maize as a second crop**

The soybean–maize combination is by far the most spatially extensive form of double cropping in Brazil, and its growth over the study period is remarkable in both scale and speed. Maize second-crop pixels coinciding with soybean as the first crop grew from 1.26 Mha in 2000 to 13.98 Mha in 2024 (Table 5 and Figure 6), with the most dramatic acceleration occurring between 2010 and 2015, when this combination alone added 6.49 Mha in a single five-year interval. By 2024, the soybean–maize overlap accounted for 95% of all maize second-crop area nationally, up from 71% in 2000, confirming that the diffusion of the safrinha system has been almost exclusively a soybean-based phenomenon. Other Temporary Crops as a first crop contributed a secondary but non-trivial share of maize relay area in the early years (0.50 Mha in 2000, or 29% of the total), but this share declined progressively as the system became more soybean-dominated, falling to 0.73 Mha and just 5% of the total by 2024. Cotton as a first crop for maize relay remained negligible throughout, never exceeding 0.013 Mha in any year.

#### **Table 5.** Maize as the Second crop.

| Landcover (1st crop) | 2000 | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Soybean** | 1.255 | 2.396 | 3.797 | 10.288 | 12.275 | 13.980 |
| **Other Temp. Crops** | 0.504 | 0.426 | 0.516 | 1.372 | 0.861 | 0.727 |
| **Cotton** | 0.001 | 0.002 | 0.009 | 0.013 | 0.008 | 0.011 |
| **TOTAL** | **1.760** | **2.824** | **4.322** | **11.673** | **13.144** | **14.718** |

![Figure reference 6](figuras/figure06a.png)  ![Figure reference 7](figuras/figure06b.png)

*Figure 6. Maize as a second crop for years 2000 and 2024.*

### **4.2 Cotton as a second crop**

Cotton relay cropping — the planting of cotton as a secondary crop after soybean in the same growing season — expanded from 0.26 Mha in 2000 to 2.49 Mha in 2024 (Table 6 and Figure 7), with growth concentrated in the two most recent sub-periods (+0.53 Mha between 2015 and 2020, and +0.91 Mha between 2020 and 2024). Soybean was the dominant first-crop base for cotton relay throughout the period, accounting for 93% of the total in 2000 and maintaining a share above 88% for most benchmark years, before rising to 97% in 2024. The contribution of Other Temporary Crops as a first crop for cotton relay was small and declining — from 0.014 Mha in 2000 to 0.027 Mha in 2024 — while cotton-on-cotton (the same land class hosting both first and second crop cotton) fluctuated between 0.04 and 0.07 Mha and declined to 0.045 Mha by 2024.

#### **Table 6.** Cotton as the Second crop.

| Landcover (1st crop) | 2000 | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Soybean** | 0.240 | 0.629 | 0.771 | 0.880 | 1.431 | 2.414 |
| **Other Temp. Crops** | 0.014 | 0.027 | 0.052 | 0.104 | 0.071 | 0.027 |
| **Cotton** | 0.004 | 0.040 | 0.047 | 0.066 | 0.074 | 0.045 |
| **TOTAL** | **0.258** | **0.696** | **0.870** | **1.050** | **1.576** | **2.486** |

![Figure reference 8](figuras/figure07a.png)  ![Figure reference 9](figuras/figure07b.png)

*Figure 7. Cotton as a second crop for years 2000 and 2024.*

### **4.3 Other Temporary Crops as a second crop**

The third second-crop class — Other Temporary Crops, capturing sorghum, millet, sunflower, cover crops and other minor relay plantings — presents a more complex picture. Total overlap area remained relatively stable over the study period, fluctuating between 5.45 and 6.62 Mha, with no sustained directional trend (Table 7 and Figure 8). However, the internal composition of this total shifted profoundly. In 2000, Other Temporary Crops as a first crop accounted for 2.15 Mha of the total 5.45 Mha — 39% — while soybean accounted for 3.30 Mha (61%). By 2024, this balance had reversed sharply: soybean contributed 6.01 Mha (93%) of the total 6.47 Mha, while Other Temporary Crops as a first crop had contracted to just 0.43 Mha (7%). Cotton as a first crop for Other Temporary Crops relay was negligible in 2000 (no overlap detected) but grew to 0.034 Mha by 2024, remaining a very minor component. 

#### **Table 7.** Other Temporary crops as the Second crop.

| Landcover (1st crop) | 2000 | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Soybean** | 3.304 | 4.591 | 4.782 | 4.330 | 5.701 | 6.009 |
| **Other Temp. Crops** | 2.148 | 1.959 | 1.796 | 1.390 | 0.697 | 0.431 |
| **Cotton** | — | 0.015 | 0.038 | 0.022 | 0.042 | 0.034 |
| **TOTAL** | **5.452** | **6.565** | **6.616** | **5.742** | **6.440** | **6.474** |

![Figure reference 10](figuras/figure08a.png)  ![Figure reference 11](figuras/figure08b.png)

*Figure 8. Other Temporary Crops as a second crop for years 2000 and 2024.*

### **4.4 Shifting composition within each first-crop class**

This section presents, for each Agricultural Use class and year, the percentage of its total overlap area that coincides with each second-crop class (Figures 9 and 10). Within the soybean first-crop class, the share of overlap area going to maize as a second crop rose dramatically from 26% in 2000 to 66% in 2015, before stabilising at around 62–63% in 2020–2024. Simultaneously, the share going to Other Temporary Crops as a second crop — which dominated in 2000 at 69% — fell to 27% by 2015 and 27% by 2024, while the cotton relay share grew modestly from 5% to 11% (Tables 8, 9 and 10). 

![Figure reference 12](figuras/figure09.png)

*Figure 9. Distribution of second-crop types within each agricultural use class — % of agricultural use overlap area, 2000–2024*

This internal rebalancing within the soybean second-crop system reflects the progressive substitution of diverse relay crops (sorghum, millet, cover crops) by commercially oriented maize *safrinha*.

#### **Table 8.** Soybean (1st).

| Soybean — % going to each 2nd crop | 2000 | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Maize (2nd)** | 26.1% | 31.5% | 40.6% | **66.4%** | **63.3%** | **62.4%** |
| **Cotton (2nd)** | 5.0% | 8.3% | 8.2% | 5.7% | 7.4% | 10.8% |
| **Other Temp. (2nd)** | **68.8%** | **60.3%** | **51.1%** | 27.9% | 29.4% | 26.8% |

Within Other Temporary Crops as a first class, the pattern is analogous but more pronounced: the maize relay share rose from 19% in 2000 to 61% in 2024, while the Other Temporary Crops relay share fell from 81% to 36%. This shift likely reflects the gradual absorption of former mixed-farming land into soybean-adjacent systems, where cover crops and relay plantings increasingly follow the same commercial logic as in the soybean belt. 

#### **Table 9.** Other Temp. Crops (1st).

| Other Temp. Crops — % going to each 2nd crop | 2000 | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Maize (2nd)** | 18.9% | 17.7% | 21.8% | 47.9% | **52.8%** | **61.3%** |
| **Cotton (2nd)** | 0.5% | 1.1% | 2.2% | 3.6% | 4.4% | 2.3% |
| **Other Temp. (2nd)** | **80.6%** | **81.2%** | **76.0%** | 48.5% | 42.8% | 36.4% |

The Cotton first-crop class shows the most volatile composition, with no single second crop consistently dominant. Cotton-on-cotton relay ranged from 88% of the total in 2000 to 50% in 2024, while the Other Temporary Crops relay share grew from 1% to 38% over the same period. This volatility is likely a product of the small absolute size of the cotton first-crop class and the sensitivity of the percentage calculations to small area changes. 

#### **Table 10.** Cotton (1st)

| Cotton — % going to each 2nd crop | 2000 | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Maize (2nd)** | 11.2% | 3.1% | 9.9% | 13.1% | 6.8% | 12.0% |
| **Cotton (2nd)** | **87.8%** | **70.6%** | 49.7% | **65.6%** | **59.5%** | **50.4%** |
| **Other Temp. (2nd)** | 1.0% | 26.3% | 40.4% | 21.3% | 33.7% | 37.6% |

Taken together, the overlap analysis documents a dual process of expansion and convergence. Expansion: the total area under any form of double cropping grew from 7.47 to 23.68 Mha, adding productive capacity without any net conversion of natural land. Convergence: the increasing dominance of a single combination — soybean as first crop followed by maize *safrinha* — means that the Brazilian double-cropping system, while larger than ever, is also more homogeneous than at any previous point in the study period. This convergence has significant implications for MAgPIE, since it simplifies the representation of double-cropping dynamics while also increasing the model's sensitivity to assumptions about soybean area, yield and calendar — factors that now condition the productivity of a second harvest as well as the first. 

![Figure reference 13](figuras/figure10.png)

*Figure 10. Percentage of first crop area spatially covered by any second-crop, 2000–2024*

## **5. Number of Crop Cycles — MODIS MCD12Q2**

The MODIS MCD12Q2 Number of Crop Cycles product provides a phenology-based, crop-agnostic measure of cropping intensity that operates independently of the MapBiomas classification system. Rather than identifying specific crops, it counts the number of complete vegetative cycles — from emergence to senescence — detected within each 500 m pixel over the course of a year, based on transitions in the MODIS EVI2 time series. Because it captures any recurring vegetative signal, including commercial grain crops, cover crops, ratoon systems and managed grasslands with seasonal rest periods, the NumCycles totals are substantially larger than the agricultural areas reported in the MapBiomas products: the single-cycle class, for instance, reaches 453.73 Mha in 2024, far exceeding the 59.93 Mha of temporary crop area mapped by MapBiomas, because it includes pasture, natural savanna with seasonal phenology, and other non-crop vegetation types that also produce a single annual green-up and senescence cycle detectable by MODIS (Figure 11). For this reason, the NumCycles product is most informative not in absolute terms but in the cross-tabulation with specific agricultural land cover classes, which allows the phenological signal to be attributed to particular cropping systems. 

### **5.1 Overall trends in single and double-cycle area**

Considering all land cover types together, total area with at least one detected cycle ranged from 403.98 Mha in 2010 to 547.97 Mha in 2024, with single-cycle area consistently accounting for the large majority of the total (between 87% and 91% across all benchmark years). Double-cycle area — the phenological indicator most directly relevant to double cropping — showed a more dynamic and non-linear trajectory. Starting at 48.48 Mha in 2001, it rose to 60.54 Mha in 2005 before contracting sharply to 38.07 Mha in 2010. It then recovered progressively to 49.21 Mha in 2015 and accelerated strongly thereafter, reaching 79.99 Mha in 2020 and 94.24 Mha in 2024 — nearly double the 2010 level and the highest value recorded across the entire study period (Figures 11 and 12). This non-linear trajectory deserves careful interpretation. The contraction between 2005 and 2010 likely reflects a combination of climatic variability affecting the phenological detectability of the second cycle and year-to-year fluctuations in the spatial extent of relay cropping itself. The sustained acceleration after 2015 is consistent with the pattern documented in the MapBiomas Second Crop product — which recorded its largest five-year gain in the 2010–2015 period — though the MODIS signal lags slightly, capturing the structural consolidation of double cropping at scale in the 2015–2024 phase rather than the initial diffusion phase (Table 11).

It is important to note that the magnitude of double-cycle area in the NumCycles product (94.24 Mha in 2024) substantially exceeds the total second-crop area in the MapBiomas product (23.68 Mha in 2024). This discrepancy is expected and does not indicate an inconsistency between the two sources. Several factors account for the difference. First, the MODIS product captures double cycles in pasture and natural vegetation — including areas of managed grassland with dry-season rest periods that register as a cycle transition — none of which are mapped by the MapBiomas Second Crop product, which is restricted to agricultural areas. Second, the coarser spatial resolution of MODIS (500 m vs. 30 m for Landsat) means that mixed pixels at the boundaries of agricultural fields may record a double-cycle signal that does not correspond to true double cropping. Third, the MapBiomas Second Crop product has a geographically restricted coverage that excludes several states, meaning that some genuine double-crop area is absent from the MapBiomas total but present in the MODIS count. The two products are therefore best understood as measuring related but not identical phenomena: MapBiomas provides a higher-resolution, crop-specific map of where double cropping is occurring and what crops are involved, while MODIS provides a broader, independent signal of where land surfaces are exhibiting the phenological signature of more than one productive cycle per year.

#### **Table 11.** Area by number of crop cycles (Mha), 2001–2024

| NumCycles class | 2001 (→LC2000) | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1 — Single crop** | 373.63 | 423.61 | 365.91 | 384.21 | 414.57 | 453.73 |
| **2 — Double crop** | 48.48 | 60.54 | 38.07 | 49.21 | 79.99 | 94.24 |
| **Total**  | **422.11** | **484.15** | **403.98** | **433.42** | **494.56** | **547.97** |

![Figure reference 14](figuras/figure11.png)

*Figure 11. Area by NumCycles class over time, 2001–2024 (MODIS MCD12Q2).*

![Figure reference 15](figuras/figure12.png)

*Figure 12. Spatial distribution of two cycles per year — 2001, 2005, 2010, 2015, 2020 and 2024*

### **5.1 NumCycles cross-tabulated with landcover classes**

When the NumCycles layers are cross-tabulated with the MapBiomas Agricultural Use classes — restricting analysis to temporary crop pixels only — the patterns become considerably more informative. Across all temporary crop classes, the overwhelming majority of pixels fall into the single-cycle category, as expected given that the single-cycle signal includes all first-season crops regardless of whether they are followed by a relay planting. Double-cycle area within the temporary crop mask represents the subset of agricultural land where MODIS independently detects a second vegetative cycle, providing a cross-source validation of the MapBiomas second-crop mapping (Figure 13).

![Figure reference 16](figuras/figure13.png)

*Figure 13. The area overlapped between the number of cycles and the first crop, 2000-2024.*

Soybean shows by far the largest and fastest-growing double-cycle area among all temporary crop classes, expanding from 2.47 Mha in 2000 to 11.65 Mha in 2024 (Table 12 and Figure 14), closely tracking — though somewhat exceeding — the 13.98 Mha of soybean-based maize relay area documented in the MapBiomas Second Crop overlap analysis. Single-cycle soybean area grew from 12.07 to 24.76 Mha over the same period, confirming that intensification and frontier expansion advanced simultaneously rather than as substitutes. The ratio of double to single-cycle area within the soybean class rose from approximately 20% in 2000 to 47% in 2024, a remarkable shift that underscores the degree to which the soybean production system has been reorganised around the double-crop calendar over the past two decades (Figure 14).

Other Temporary Crops shows a contrasting pattern that mirrors the MapBiomas results. Single-cycle area contracted from 9.23 to 5.85 Mha between 2000 and 2024, while double-cycle area remained modest and relatively stable at 1.0–1.6 Mha. The declining single-cycle area is consistent with the long-run contraction of this class documented in the Agricultural Use analysis, while the stable double-cycle area suggests that whatever relay cropping occurs within this class — likely cover crops and minor commercial secondary plantings — has not expanded at scale. Sugarcane single-cycle area more than doubled from 3.36 to 9.35 Mha by 2020 before retreating to 8.04 Mha in 2024. Its double-cycle readings, fluctuating between 0.09 and 1.13 Mha with no clear directional trend. Rice and cotton remain small in absolute terms across both cycle classes throughout the study period, though both register a gradual increase in double-cycle pixels after 2015.

Taken together, the NumCycles analysis provides three distinct contributions to the overall picture. First, it offers independent cross-source validation of the MapBiomas Second Crop mapping: the two products converge on the same central finding — a rapid and soybean-driven expansion of double cropping after 2010 — despite using different sensors, resolutions and methodologies. Second, it extends spatial coverage to regions excluded from the MapBiomas Second Crop product, providing a nationally consistent signal of double-crop intensity that can be used in MAgPIE cells where the second-crop overlay is unavailable. Third, it reveals the phenological dimension of agricultural intensification: the shift from single to double-cycle dominance within the soybean class between 2000 and 2024 is not only a statistical finding but a description of a fundamental change in the seasonal organisation of land use across tens of millions of hectares of Brazilian agricultural land.

#### **Table 12.** Area overlapped between the number of cycles and each first crop (Mha), 2000-2024.

| Year | 2000 | 2005 | 2010 | 2015 | 2020 | 2024 |
| ----- | ----- | ----- | ----- | ----- | ----- | ----- |
|   **Cotton** |  |  |  |  |  |  |
| **1 cycle** | 0,01 | 0,06 | 0,12 | 0,09 | 0,18 | 0,12 |
| **2 cycles** | 0,0007 | 0,006 | 0,01 | 0,03 | 0,01 | 0,09 |
|   **Rice** |  |  |  |  |  |  |
| **1 cycle** | 0,46 | 0,58 | 0,66 | 0,86 | 0,89 | 0,84 |
| **2 cycles** | 0,03 | 0,03 | 0,03 | 0,07 | 0,15 | 0,18 |
|   **Sugarcane** |  |  |  |  |  |  |
| **1 cycle** | 3,36 | 4,69 | 6,16 | 7,78 | 9,35 | 8,04 |
| **2 cycles** | 0,09 | 0,31 | 0,19 | 1,13 | 0,12 | 0,49 |
|   **Other temporary crops** |  |  |  |  |  |  |
| **1 cycle** | 9,23 | 7,93 | 9,24 | 8,56 | 7,52 | 5,85 |
| **2 cycles** | 1,04 | 1,14 | 0,79 | 1,64 | 1,06 | 1,21 |
|   **Soybean** |  |  |  |  |  |  |
| **1 cycle** | 12,07 | 15,746 | 15,78 | 17,67 | 20,59 | 24,76 |
| **2 cycles** | 2,47 | 4,47 | 4,83 | 9,82 | 10,34 | 11,65 |

![Figure reference 17](figuras/figure14.png)

*Figure 14. Number of crop cycles within each first crop class — 2000, 2005, 2010, 2015, 2020, 2024 (Mha, stacked)*

## **6. Comparison with PAM/IBGE Statistics**

The Produção Agrícola Municipal (PAM), published annually by IBGE, provides official declared planted areas by crop and municipality based on field surveys conducted with local agricultural technicians. As a survey-based product, PAM follows a fundamentally different methodology from the remote-sensing classification of MapBiomas: it captures farmer-declared planted areas at the municipal level, regardless of whether those areas are detectable from satellite imagery, while MapBiomas identifies crop classes based on spectral and temporal signatures in Landsat time series. These methodological differences mean that the two sources are not expected to agree perfectly, and divergences between them carry specific diagnostic information about both the strengths and limitations of each approach. The comparison presented here covers four crops with a direct class equivalent in MapBiomas — soybean, sugarcane, rice and cotton — plus a residual comparison between the seven PAM crops without a dedicated MapBiomas class and the MapBiomas Other Temporary Crops category, and finally the information about maize first and second crop reported by PAM against the maize form MapBiomas Second Crop product. 

### **6.1 Crops with direct correspondence**

Soybean shows the strongest agreement between the two sources of any crop in the comparison, with discrepancies remaining within ±15% across four benchmark years (2000, 2005, 2010 and 2020; Table 13 and Figure 15). MapBiomas underestimated PAM by 14.2% in 2000 (15.95 vs. 13.68 Mha, noting that MapBiomas is larger here), and the two sources tracked each other closely through 2010 (24.33 Mha MapBiomas vs. 23.33 Mha PAM, a difference of just +4.1%) and 2020 (36.88 vs. 37.19 Mha). This level of agreement is notable given the methodological distance between the two sources and reflects the spectral distinctiveness of soybean — a uniform, high-biomass crop with a well-defined seasonal calendar — which makes it among the most reliably mapped crops from satellite imagery in the Brazilian context. 

Sugarcane also shows satisfactory agreement, with discrepancies ranging from −8.3% to +6.5% across benchmark years. MapBiomas recorded 4.47 Mha in 2000 against PAM's 4.88 Mha (−8.3%), and 8.60 Mha in 2010 against PAM's 9.16 Mha (−6.1%), before converging closely in 2020 (10.61 Mha MapBiomas vs. 10.01 Mha PAM, +5.7%). Overall, the agreement is sufficient to treat the MapBiomas sugarcane class as a reliable area estimate for modelling purposes.

Rice and cotton present a sharply contrasting picture, with MapBiomas underestimating PAM declared areas across all years. For rice, MapBiomas recorded 0.64 Mha in 2000 against PAM's 3.69 Mha — a gap of +479%. This gap narrowed progressively over the study period as PAM rice area declined (to 1.66 Mha in 2020) while MapBiomas rice area grew (to 1.15 Mha in 2020), bringing the discrepancy down to +44% by 2020 — still substantial but representing a significant convergence. 

The divergence for cotton is even more extreme in proportional terms, though the absolute gap is smaller given the small size of the class. MapBiomas recorded just 0.009 Mha for cotton in 2000 — essentially negligible — against PAM's 0.81 Mha, a difference of more than 8,700%. Even by 2020, when MapBiomas cotton had grown to 0.19 Mha, PAM reported 1.63 Mha, implying that MapBiomas captures only around 12% of the declared cotton area. MapBiomas cotton class is not a reliable direct substitute for PAM cotton area and should be used in conjunction with the second-crop cotton overlay data when calibrating MAgPIE cotton parameters.

#### **Table 13.** PAM vs. MapBiomas landcover — crops with direct correspondence (Mha).

| Year/ Change | 2000 | % | 2005 | % | 2010 | % | 2020 | % |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Cotton** |  |  |  |  |  |  |  |  |
| MapBiomas | 0,009 | +8701% | 0,071 | +1687% | 0,132 | +528% | 0,194 | +741% |
| PAM | 0,812 |  | 1,266 |  | 0,832 |  | 1,633 |  |
| **Rice** |  |  |  |  |  |  |  |  |
| MapBiomas | 0,636 | +479.1% | 0,671 | +492.6% | 0,733 | +276% | 1,15 | +44% |
| PAM | 3,685 |  | 3,977 |  | 2,756 |  | 1,656 |  |
| **Soybean** |  |  |  |  |  |  |  |  |
| MapBiomas | 15,946 | -14.2% | 22,3 | +5% | 24,325 | -4.1% | 36,883 | +0.8% |
| PAM | 13,682 |  | 23,416 |  | 23,332 |  | 37,194 |  |
| **Sugarcane** |  |  |  |  |  |  |  |  |
| MapBiomas | 4,472 | +9.1% | 5,699 | +2% | 8,604 | +6.5% | 10,614 | -5.7% |
| PAM | 4,879 |  | 5,814 |  | 9,164 |  | 10,008 |  |

![Figure reference 18](figuras/figure15.png)

*Figure 15. PAM vs. MapBiomas, crops with direct correspondence, 2000 / 2005 / 2010 / 2020.*

### **6.2 Crops without direct correspondence: Other Temporary Crops**

For the seven PAM crops without a dedicated MapBiomas class — cassava, groundnut, potato, pulses, temperate cereals, tropical cereals and other minor crops — the relevant comparator is the MapBiomas Other Temporary Crops class, which was designed precisely to aggregate these residual commodities (Figure 16 and Table 14). The comparison reveals a remarkably close alignment between the two totals across all four benchmark years. The sum of the seven PAM crops ranged from 10.57 to 12.69 Mha across the study period, while MapBiomas Other Temporary Crops ranged from 10.45 to 13.08 Mha. The discrepancies were modest in all cases and without a systematic directional bias, suggesting that the MapBiomas Other Temporary Crops class captures the aggregate footprint of these diverse commodities reasonably well at the national scale, even though it cannot distinguish between individual crops within the group. This alignment is notable because it is not guaranteed by construction: the two sources use entirely different observation methods, spatial resolutions and classification approaches, and the individual crops within the PAM residual group span a wide range of agronomic types, phenologies and geographies. 

#### **Tabla 14.** Other PAM crops vs. Other Temporary Crops (MapBiomas) (Mha).

|  | 2000 | 2005 | 2010 | 2020 | Note |
| ----- | :---: | :---: | :---: | :---: | ----- |
| **Sum PAM (7 unmatched crops)** | 11.69 | 12.69 | 11.63 | 10.57 | *Cassava, groundnut, potato, pulses, warm/cool cereals, other* |
| **Other Temp. Crops (MapBiomas)** | 12.18 | 11.22 | 13.08 | 10.45 | *MAgPIE codes: cassav_sp, groundnut, others, potato, puls_pro, tece, trce* |
| **Δ%** | -4% | +13.1 | +12.5% | -1.1% |  |

![Figure reference 19](figuras/figure16.png)

*Figure 16. Other PAM crops vs. Other Temporary Crops (MapBiomas) (Mha)*

### **6.3 Maize: decomposition into first and second crop**

The PAM/IBGE provides a disaggregation of maize planted area into first and second crop (*1ª safra* and *2ª safra*), enabling a direct comparison with the MapBiomas second-crop product. The national figures reveal a structural shift of exceptional scale and speed. In 2005, first year coincident with the benchmark years, Brazilian maize occupied a total of 12.25 Mha according to PAM, of which 9.02 Mha (73.7%) corresponded to first-crop plantings and only 3.23 Mha (26.3%) to the second crop. By 2024, this balance had inverted completely: total maize area grew to 21.44 Mha, but the entire net gain accrued to the safrinha — second-crop area expanded from 3.23 to 16.67 Mha while first-crop area contracted from 9.02 to 4.77 Mha. By 2024, 77.7% of all Brazilian maize area was planted as a second crop, compared to just 26.3% in 2005. The crossover point — when second-crop maize surpassed first-crop maize in absolute area — occurred between 2010 and 2015, when second-crop area grew from 5.05 to 9.93 Mha while first-crop area simultaneously contracted from 7.14 to 5.92 Mha.

#### **Table 15.** Disaggregation of maize into first and second crops. Comparison between PAM and MapBiomas data.

|  | PAM (Mha) |  |  | MapBiomas (Mha) | Diff PAM−MB |  |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Year** | **Total** | **1st crop** | **2nd crop** | **2nd crop** | **Mha** | **Diff %** |
| **2005** | 12.25 | 9.02 | **3.23** | **2.82** | +0.402 | +14.2% |
| **2010** | 12.19 | 7.14 | **5.05** | **4.32** | +0.725 | +16.8% |
| **2015** | 15.85 | 5.92 | **9.93** | **11.67** | −1.746 | −15.0% |
| **2020** | 18.36 | 4.93 | **13.43** | **13.14** | +0.284 | +2.2% |
| **2024** | 21.44 | 4.77 | **16.67** | **14.72** | +1.949 | +13.2% |

The comparison between PAM second-crop maize and the MapBiomas second-crop maize product is striking in its convergence. In 2020 — the year for which both sources are most reliable and coverage is most complete — MapBiomas maps 13.14 Mha while PAM declares 13.43 Mha, a difference of less than 2%. In 2010 and 2024, the PAM was slightly above MapBiomas. The only notable divergence occurs in 2015, when MapBiomas records 11.67 Mha against PAM's 9.93 Mha — a case where MapBiomas exceeds PAM. Overall, the two sources track each other with a consistency that is unusual in comparisons between remote-sensing and survey data, and provides strong cross-validation for both.

This decomposition also resolves what would otherwise appear as a paradox in the MapBiomas landcover data. In the Agricultural Use product, maize has no dedicated class — it appears entirely within Other Temporary Crops when grown as a first crop. The growth of second-crop maize area visible in the Second Crop product therefore represents not a simple expansion of the crop but a transformation of its seasonal position: the same land that previously hosted first-season maize has been progressively converted to soybean as the primary crop, with maize relegated to the relay slot. The PAM data confirm this: first-crop maize contracted by 4.25 Mha between 2005 and 2024, while second-crop maize expanded by 13.44 Mha.

### **6.4 Implications for modelling**

The PAM comparison yields four conclusions relevant to MAgPIE calibration. First, soybean and sugarcane area estimates from MapBiomas can be used directly with high confidence, requiring at most minor correction factors in earlier benchmark years. Second, rice and cotton MapBiomas classes significantly undercount declared planted areas and should be supplemented — for rice, by acknowledging the geographic restriction to irrigated systems; for cotton, by incorporating the second-crop cotton overlay and recognising that a large share of Brazilian cotton production is not captured in the primary landcover class. Third, the aggregate Other Temporary Crops class performs well as a proxy for the diverse residual of PAM crops, providing a reliable national-scale area estimate despite being unable to resolve individual commodities within the group. Fourth, disaggregation of maize into first and second crop provides the most direct available benchmark for the MapBiomas Second Crop maize product, and also reveals the full scale of the structural shift in Brazilian maize production. Together, these findings suggest a differentiated approach to data integration: direct use of MapBiomas area for the well-mapped classes, and a hybrid approach combining MapBiomas with PAM data for the underestimated crops, which is precisely the methodology adopted in the overlap and cycle intensity analyses presented in the preceding sections.

## **7. Discussion**

The analysis presented in this report documents a period of profound transformation in Brazilian agricultural land use, one that goes well beyond the simple expansion of farmed area to encompass a fundamental reorganisation of how land is used across the agricultural calendar. Drawing on three independent remote-sensing products and one set of official statistics, covering six benchmark years between 2000 and 2024 and aggregated to the 2,901 cells of the MAgPIE global grid, the findings converge on a coherent and mutually reinforcing picture of intensification led by soybean and expressed most visibly through the expansion of double cropping.

Soybean was the dominant driver of agricultural change across every dimension analysed. In terms of area, it grew from 15.95 Mha in 2000 to 40.58 Mha in 2024, accounting for the large majority of the 26.7 Mha net gain in total temporary crop area over the period. In terms of composition, its share of total temporary crop area rose from 48% to 68%, progressively displacing the more diverse agricultural mosaic — particularly the Other Temporary Crops class — that characterised the Brazilian agricultural landscape at the beginning of the study period. And in terms of intensification, soybean provided the productive base on which virtually all double-cropping expansion was built: by 2024, soybean was the first crop in 95% of all maize relay area, 97% of all cotton relay area, and 93% of all Other Temporary Crops relay area nationally. The structural centralisation of Brazilian crop agriculture around soybean, already well advanced at the start of the period, accelerated further over the 24 years studied here.

Double-cropping intensification — the planting of a second crop after soybean harvest within the same agricultural year — underwent a particularly dramatic acceleration after 2010, with total second-crop area jumping from 11.80 Mha in 2010 to 18.46 Mha in 2015, the largest five-year gain recorded across any class or metric in the entire dataset. By 2020, over half of the soybean area in Brazil was followed by a second crop within the same year, and by 2024, the soybean–maize relay combination alone covered 13.98 Mha — nearly equivalent to the total soybean area of the year 2000. This transformation is best understood not as a marginal adjustment to existing farming systems but as a structural shift in the seasonal organisation of Brazilian agriculture: the growing calendar that once treated the dry season as an agricultural off-season has been progressively replaced by a system in which a second productive cycle is the default rather than the exception across the most productive farming regions of the Centre-West.

The maize *safrinha* system is the most visible expression of this shift. The soybean–maize rotation now accounts for over 90% of all maize second-crop area, and total maize relay area grew eight-fold between 2000 and 2024. This is consistent with the well-documented structural transition of Brazilian maize production from a primary summer crop — historically grown in the South and Southeast — to a winter relay crop planted after soybean harvest across the Centre-West and MATOPIBA. The practical consequence of this transition is that Brazilian maize production is now deeply coupled to soybean: the area, timing and location of the maize second crop are determined almost entirely by decisions made about the soybean first crop, a dependency that has important implications for how both crops are represented in agricultural models and how shocks to one propagate through the system.

The MODIS MCD12Q2 Number of Crop Cycles product provides independent, crop-agnostic confirmation of these intensification trends. Double-cycle area within the agricultural mask — pixels where MODIS detects two complete vegetative cycles per year — expanded from 48.48 Mha in 2001 to 94.24 Mha in 2024, with the most sustained acceleration occurring after 2015. The spatial distribution of this double-cycle signal is concentrated in the Cerrado and MATOPIBA regions, precisely where the soybean–maize rotation is most prevalent, and the pixel-level cross-tabulation with the MapBiomas landcover classes shows that double-cycle growth is almost entirely driven by soybean pixels. The convergence between the MapBiomas Second Crop product and the MODIS NumCycles product on this central finding — reached through entirely different sensors, resolutions and algorithms — provides a robust, cross-validated confirmation of the intensification signal that substantially strengthens confidence in both data sources as inputs for modelling.

The comparison with PAM/IBGE official statistics adds a further dimension of validation while also identifying the limits of the remote-sensing approach. For soybean and sugarcane, the two sources agree closely across all benchmark years, confirming that the MapBiomas landcover classes for these crops can be used directly in MAgPIE calibration without systematic correction. For rice and cotton, however, MapBiomas persistently and substantially underestimates declared planted areas — by factors of up to six for rice in 2000 and more than eight for cotton — due to the geographic restriction of the rice class to irrigated systems and the partial absorption of cotton into residual classes. These discrepancies are not errors in the MapBiomas product per se, but rather the predictable consequence of mapping at national scale with a methodology optimised for the dominant commodity crops of the cerrado frontier. They do, however, require that rice and cotton parameters in MAgPIE be calibrated using a hybrid of remote-sensing and survey data rather than relying on the MapBiomas classes alone. The Other Temporary Crops comparison, by contrast, is encouraging: the aggregate of seven PAM residual crops tracks the MapBiomas Other Temporary Crops class with discrepancies of less than 14% across all benchmark years, suggesting that this residual class performs well as a proxy for the diverse group of minor commodities it is intended to represent.

## **8. Conclusion**

Considered as a whole, the three-product analysis presented in this report provides a multi-source, cross-validated and spatially explicit picture of Brazilian agricultural intensification that is well suited to the requirements of MAgPIE calibration. The spatial overlap layers — recording the coincident area of every landcover and second-crop class combination across all benchmark years and all 2,901 grid cells — are the primary analytical output, translating the complex dynamics documented in the preceding sections into a format directly usable for model parameterisation. The NumCycles layers extend this coverage to regions excluded from the MapBiomas Second Crop product and add a temporally consistent signal of cycle intensity that can inform assumptions about double-crop prevalence in cells where the second-crop overlay is unavailable. Together, these data layers capture not only how much land is farmed and with what crops, but how intensively that land is used across the agricultural calendar — a dimension of agricultural productivity that is increasingly central to understanding Brazilian land use and that has, until recently, been difficult to represent at the spatial resolution and temporal coverage required for global land-use modelling.

## **Appendix A — Agricultural Use Maps**

![Figure reference 20](appendix/figureA01.png)

![Figure reference 21](appendix/figureA02.png)

![Figure reference 22](appendix/figureA03.png)

![Figure reference 23](appendix/figureA04.png)

![Figure reference 24](appendix/figureA05.png)

## **Appendix B — Second Crop Maps**

![Figure reference 25](appendix/figureB01.png)

![Figure reference 26](appendix/figureB02.png)

![Figure reference 27](appendix/figureB03.png)

## **Appendix C — Soybean x second crop Maps**

![Figure reference 28](appendix/figureC01.png)

![Figure reference 29](appendix/figureC02.png)

![Figure reference 30](appendix/figureC03.png)

## **Appendix D — Other Temporary Crops x Second Crop**

![Figure reference 31](appendix/figureD01.png)

![Figure reference 32](appendix/figureD02.png)

![Figure reference 33](appendix/figureD03.png)

## **Appendix E — Cotton x Second Crop**

![Figure reference 34](appendix/figureE01.png)

![Figure reference 35](appendix/figureE02.png)

![Figure reference 36](appendix/figureE03.png)

## **Appendix F — Agricultural Use x 2 Cycles**

![Figure reference 37](appendix/figureF01.png)

![Figure reference 38](appendix/figureF02.png)

![Figure reference 39](appendix/figureF03.png)

![Figure reference 40](appendix/figureF04.png)

![Figure reference 41](appendix/figureF05.png)

## **Appendix G — Soybean: PAM vs. MapBiomas**

![Figure reference 42](appendix/figureG01.png)

