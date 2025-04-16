# LiDAR_metrics

This repository is retired and does not work, please use ```lidRmetrics``` instead.

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
