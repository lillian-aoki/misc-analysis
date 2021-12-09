## Looking at the eDNA from 2019 samples
library(tidyverse)
info <- read.csv("eDNA/2019_DNA_extracts.csv")
cells <- read.csv("eDNA/2019_water_eDNA_summary.csv")
region_order <- c("AK","BC","WA","OR","BB","SD")
head(info)
head(cells)
cells$SampleID <- gsub('w',"-W",cells$Sample)
cells_info <- left_join(cells,info,by=c("SampleID"="sampleid"))
head(cells_info)
cells_info$CellsPerMl <- cells_info$TotalCellsInSample/cells_info$TotalWaterVolumeFiltered
cells_info$CellsPerL <- cells_info$CellsPerMl*1000
cells_info$Region <- ordered(cells_info$Region,levels=region_order)
ggplot(cells_info,aes(x=Region,y=CellsPerL,color=SiteCode))+geom_jitter(width=0.15, size=4)+
  ylab("Laby cells per L")+
  labs(title="eDNA analysis of seawater samples",
       subtitle = "Collected July 2019")+
  theme_bw()
ggsave(filename = "eDNA/eDNA_positive_2019.jpg")
ggplot(cells_info,aes(x=Region))+geom_histogram(aes(fill=SiteCode),stat = "count",color="black")
