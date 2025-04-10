# LiDAR_metrics

This function is used to calculate various LiDAR metrics used in ecology. The function takes LAS or LAScatalog objects created with the lidR package as inputs and returns a multi-layered terra SpatRaster, with each band corresponding to a metric. The choice of metrics, band names, and definitions are mostly based on Shokirov et al. (2023), with some minor changes being made for metrics that were not clearly defined in the paper. Notably, the roughness_L1, roughness_L2, roughness_L3 have not been included in the current edition.

# Installation

Option 1: Load Directly from GitHub

You can source the latest version of the functions directly into R:

```source("https://raw.githubusercontent.com/alandhyc/GIS_housekeeping/main/LiDAR_metrics.R")```

Option 2: Clone the Repository

If you prefer a local copy, clone the repository using Git:

```git clone https://github.com/alandhyc/LiDAR_metrics.git```

Then, in R:

```source("path/to/functions.R")```

# License

See the LICENSE file for details.

# Contact

For questions or suggestions, open an issue or contact hyc43@cam.ac.uk
