# LiDAR_metrics

This function is used to calculate various LiDAR metrics used in ecology. The function takes LAS or LAScatalog objects created with the lidR package as inputs and returns a multi-layered terra SpatRaster, with each band corresponding to a metric. The choice of metrics, band names, and definitions are mostly based on Shokirov et al. (2023), with some minor changes being made for metrics that were not clearly defined in the paper. Notably, the roughness_L1, roughness_L2, roughness_L3 have not been included in the current edition.

Shokirov, S. et al. (2023) ‘Habitat highs and lows: Using terrestrial and UAV LiDAR for modelling avian species richness and abundance in a restored woodland’, Remote Sensing of Environment. Elsevier, 285, p. 113326. doi: 10.1016/J.RSE.2022.113326.

# Installation

Option 1: Load Directly from GitHub

You can source the latest version of the functions directly into R:

```source("https://raw.githubusercontent.com/alandhyc/LiDAR_metrics/main/LiDAR_metrics.R")```

Option 2: Clone the Repository

If you prefer a local copy, clone the repository using Git:

```git clone https://github.com/alandhyc/LiDAR_metrics.git```

Then, in R:

```source("path/to/functions.R")```

# Example

```
#Basic info

library(lidR)
library(terra)
library(dplyr)

ncores<-13
input_dir<-"C:/Point_Cloud"
out_dir<-"C:/LiDAR_metrics"

#Now apply LiDAR_metrics() function

plan(multisession, workers = ncores)
set_lidr_threads(ncores)

ctg<-readLAScatalog(input_dir)

opt_output_files(ctg)<-paste0(out_dir,"/{ORIGINALFILENAME}")
opt_chunk_buffer(ctg)<-20

ctg<-LiDAR_metrics(las = ctg,
                   res=5,
                   h_cutoff=1.3,
                   mcc_s=1.5,
                   mcc_t=0.3,
                   zmax=35,
                   cov_grid=0.25,
                   shannon_cut=c(-1,2,5,10,15,35),
                   vox_res=0.5,
                   L1_range=c(0,1),
                   L2_range=c(1,10),
                   L3_range=c(10,35))
```

# License

See the LICENSE file for details.

# Contact

For questions or suggestions, open an issue or contact hyc43@cam.ac.uk
