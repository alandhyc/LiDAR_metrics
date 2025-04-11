#Function to calculate LiDAR metrics
#Written by Aland Chan, referencing Shokirov et al. (2023)
#Input LAS or LAScatalog files
#Returns terra SpatRaster with one band per metric

LiDAR_metrics<-function(las,
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
                        L3_range=c(10,35)){
  
  require(lidR)
  require(terra)
  
  if(is(las,"LAS")){
    
    las<-classify_ground(las,mcc(s=mcc_s,t=mcc_t))
    las<-normalize_height(las,knnidw())
    
    #Most metrics carries a filter of Z>1.3
    
    las_filtered<-filter_poi(las,Z>h_cutoff)
    
    std_metrics<-pixel_metrics(las_filtered,.stdmetrics_z,res = res)
    
    #Select the relevant metrics
    
    std_metrics<-std_metrics[[c("zmax","zmean","zsd","zskew","zkurt","zq5","zq10","zq25","zq50","zq75","zq90","zq95")]]
    
    names(std_metrics)<-c("maxH","meanH","stdH","skewH","kurH","p_05","p_10","p_25","p_50","p_75","p_90","p_95")
    
    #Also add the 99th quantile
    q99_f<-function(z){
      list(p_99 = quantile(z,probs = 0.99))
    }
    q99<-pixel_metrics(las_filtered,func = ~q99_f(Z),res = res)
    
    std_metrics<-c(std_metrics,q99)
    
    #VCI
    
    vci2<-pixel_metrics(las_filtered,VCI(z=Z,by = 2,zmax = zmax),res = res)
    vci5<-pixel_metrics(las_filtered,VCI(z=Z,by = 5,zmax = zmax),res = res)
    vci10<-pixel_metrics(las_filtered,VCI(z=Z,by = 10,zmax = zmax),res = res)
    vci15<-pixel_metrics(las_filtered,VCI(z=Z,by = 15,zmax = zmax),res = res)
    vci20<-pixel_metrics(las_filtered,VCI(z=Z,by = 20,zmax = zmax),res = res)
    
    VCI_combined<-c(vci2,vci5,vci10,vci15,vci20)
    names(VCI_combined)<-paste0("VCI_",c(2,5,10,15,20))
    
    
    #Canopy cover (cov)
    #For each pixel, the area of 0.25m (or cov_grid) pixels being canopy (max_z>1.3) is divided by the total area of the pixel
    
    cov_f<-function(z,cov_grid){
      maxZ<-max(z,na.rm = T)
      area<-ifelse(maxZ>1.3,cov_grid^2,0)
      list(Cov = area)
    }
    
    cov<-pixel_metrics(las,func = ~cov_f(z = Z,cov_grid = cov_grid),res = cov_grid)
    cov<-terra::resample(cov,vci2,method = "sum")
    cov<-cov/(res^2)
    names(cov)<-"Cov"
    
    #Roughness metrics 
    #Takes the filtered point cloud (>1.3m) as input
    
    roughness_metrics_f<-function(z,shannon_cut){
      
      #Coefficient of variation
      CV<-sd(z,na.rm = T)/mean(z,na.rm = T)
      
      #Roughness according to Herrero-Huerta et al. (2020)
      roughness<-IQR(z,na.rm = T)^(median(z,na.rm=T))
      
      #Shannon according to Davison et al. (2023)
      
      z_cut<-cut(z,shannon_cut)
      z_cut<-na.omit(z_cut)
      prop<-as.numeric(table(z_cut))/length(z_cut)
      shannon<-(-1)*sum(prop*log(prop))
      
      list(height_cv = CV,
           canopy_roughness = roughness,
           canopy_shannon = shannon)
    }
    
    rough<-pixel_metrics(
      las,
      func = ~roughness_metrics_f(z=Z,shannon_cut = shannon_cut),
      res = res)
    
    
    #Vegetation volume
    #Number of 0.5 m3 voxels divided by 8
    
    las_nonground<-filter_poi(las,Classification==1)
    
    las_vox<-voxel_metrics(las_nonground,
                           ~list(vol = vox_res^3),
                           res = vox_res)
    
    las_vox<-LAS(las_vox)
    
    Tvolume<-pixel_metrics(las_vox,~list(Tvolume = sum(vol)),res = res)
    
    
    #Layer metrics
    #Let's first create subsets of the point clouds
    
    L1<-filter_poi(las_nonground,Z<=L1_range[2] & Z>=L1_range[1])
    L2<-filter_poi(las_nonground,Z<=L2_range[2] & Z>L2_range[1])
    L3<-filter_poi(las_nonground,Z<=L3_range[2] & Z>L3_range[1])
    
    #vlayer
    #volume in each layer
    
    vlayer_L1<-voxel_metrics(L1,
                             ~list(vol = vox_res^3),
                             res = vox_res)
    vlayer_L1<-LAS(vlayer_L1)
    vlayer_L1<-pixel_metrics(vlayer_L1,~list(vlayer_L1=sum(vol)),res = res)
    
    vlayer_L2<-voxel_metrics(L2,
                             ~list(vol = vox_res^3),
                             res = vox_res)
    vlayer_L2<-LAS(vlayer_L2)
    vlayer_L2<-pixel_metrics(vlayer_L2,~list(vlayer_L2=sum(vol)),res = res)
    
    vlayer_L3<-voxel_metrics(L3,
                             ~list(vol = vox_res^3),
                             res = vox_res)
    vlayer_L3<-LAS(vlayer_L3)
    vlayer_L3<-pixel_metrics(vlayer_L3,~list(vlayer_L3=sum(vol)),res = res)
    
    
    #mean, sd, roughness, and vci
    
    layer_mean_sd_f<-function(z){
      list(meanH = mean(z,na.rm = T),
           sdH = sd(z,na.rm = T))
    }
    
    mean_sd_L1<-pixel_metrics(L1,func = ~layer_mean_sd_f(Z),res = res)
    mean_sd_L2<-pixel_metrics(L2,func = ~layer_mean_sd_f(Z),res = res)
    mean_sd_L3<-pixel_metrics(L3,func = ~layer_mean_sd_f(Z),res = res)
    
    names(mean_sd_L1)<-paste0(names(mean_sd_L1),"_L1")
    names(mean_sd_L2)<-paste0(names(mean_sd_L2),"_L2")
    names(mean_sd_L3)<-paste0(names(mean_sd_L3),"_L3")
    
    #VCI by layer
    #The paper did not specify bin size
    #Here we do 5 bins for L1 and L2, then use the bin size of L2 for L3 (because L3 theoretically has no upper bound)
    
    bin_size_L1<-(L1_range[2]-L1_range[1])/5
    bin_size_L2<-(L2_range[2]-L2_range[1])/5
    
    vci_L1<-pixel_metrics(L1,VCI(z=Z,by = bin_size_L1,zmax = L1_range[2]),res = res)
    vci_L2<-pixel_metrics(L2,VCI(z=Z,by = bin_size_L2,zmax = L2_range[2]),res = res)
    vci_L3<-pixel_metrics(L3,VCI(z=Z,by = bin_size_L2,zmax = L3_range[2]),res = res)
    
    VCI_L123<-c(vci_L1,vci_L2,vci_L3)
    names(VCI_L123)<-paste0("vci_L",c(1,2,3))
    
    #Put everything back together
    
    all_metrics<-c(std_metrics,VCI_combined,cov,rough,Tvolume,vlayer_L1,vlayer_L2,vlayer_L3,mean_sd_L1[[1]],mean_sd_L2[[1]],mean_sd_L3[[1]],mean_sd_L1[[2]],mean_sd_L2[[2]],mean_sd_L3[[2]],VCI_L123)
    
    return(all_metrics)
    
  } # End of is(las,"LAS")
  
  if(is(las,"LAScatalog")){
    
    options<-list(
      need_output_file=T,
      need_buffer = T
    )
    
      res<-catalog_map(las,
                       LiDAR_metrics,
                       res = res,
                       h_cutoff = h_cutoff,
                       mcc_s = mcc_s,
                       mcc_t = mcc_t,
                       zmax = zmax,
                       cov_grid = cov_grid,
                       shannon_cut = shannon_cut,
                       vox_res = vox_res,
                       L1_range = L1_range,
                       L2_range = L2_range,
                       L3_range = L3_range,
                       .options = options)
    
  } #End of is(las,"LAScatalog")
  
}
