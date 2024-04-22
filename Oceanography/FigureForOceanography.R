# Script to make long-term figures for Oceanography paper

# load libraries ####
library(tidyverse)
library(ggthemes)
library(patchwork)
# library(cowplot)
early <- read_csv("Oceanography/EGWD 2013-2017_MEPS.csv")
late <- read_csv("Oceanography/disease_blade_level.csv")
den <- read_csv("Oceanography/meter_level_density.csv")
og <- read_csv("Oceanography/SJ_SWD_blade18.csv")
og_den <- read_csv("Oceanography/SJ_density18.csv")
og_den <- select(og_den, -SiteName)
sitenames_og <- data.frame(Site=c("A", "B", "C", "D", "E"), 
                           SiteName=c("Beach Haven", "North Cove", "Indian Cove", "False Bay", "Fourth of July"))
og <- left_join(og, sitenames_og)
og_den <- left_join(og_den, sitenames_og, )

sitenames <- data.frame(SiteName=c("Fourth of July", "False Bay", "Beach Haven", "North Cove", "Indian Cove"),
                        SiteCode=c("A", "B", "C", "D", "E"))
den <- left_join(den, sitenames)
late <- left_join(late, sitenames)
early <- left_join(early, sitenames, by=c("site"="SiteName"))

early <- early[-which(is.na(early$SiteCode)),]
early <- subset(early, depth=="Shallow")
late <- subset(late, Region=="WA")
names(late)
den <- subset(den, Region=="WA")
names(den)
names(og_den)
den_summ <- den %>%
  group_by(Year, Region, SiteCode, SiteName, TidalHeight, Transect) %>%
  summarise(DensityShoots=mean(DensityShoots))
# bh <- data.frame(Year=2021, Region= "WA", SiteCode="C", SiteName="Beach Haven", TidalHeight=c("L", "L", "L", "U", "U", "U"),
#                  Transect=c(4, 5,6, 1,2,3), DensityShoots=0)
# den_summ <- rbind(den_summ, bh)
den_og_summ <- og_den %>%
  group_by(Year, Region, SiteCode=Site, SiteName, TidalHeight=TidalRegime, Transect) %>%
  summarise(DensityShoots=mean(Density))
den_og_site <- den_og_summ %>%
  group_by(Year, Region, SiteName) %>%
  summarise(DensityMean=mean(DensityShoots), DensitySE=sd(DensityShoots)/sqrt(length(DensityShoots)))
den_summ_site <- den_summ %>%
  group_by(Year, Region, SiteName) %>%
  summarise(DensityMean=mean(DensityShoots, na.rm=TRUE), DensitySE=sd(DensityShoots)/sqrt(length(DensityShoots)))

den_all <- rbind(den_summ_site, den_og_site)
ggplot(den_all, aes(x=Year, y=DensityMean, color=SiteName))+geom_line()

den_early <- select(early, c("year", "site", "transect", "density"))
den_early <- den_early[-which(is.na(den_early$density)),]
den_early <- distinct(den_early)
den_early_summ <- den_early %>%
  group_by(Year=year, Region="WA", SiteName=site) %>%
  summarise(DensityMean=mean(density), DensitySE=sd(density)/sqrt(length(density)))
den_all <- rbind(den_summ_site, den_og_site, den_early_summ)
den_all$DensitySE[which(is.na(den_all$DensitySE))] <- 0
dp <- ggplot(den_all, aes(x=Year, y=DensityMean))+
  geom_ribbon(aes(ymin=DensityMean-DensitySE, ymax=DensityMean+DensitySE, fill=SiteName),alpha=0.5)+
  geom_line(aes(color=SiteName))+
  scale_x_continuous(limits=c(2013, 2022), breaks=c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022))+
  xlab("Year")+
  ylab(expression(atop("Seagrass shoot density", "(shoots per m"^2~")")))+
  labs(title="A")+
  scale_y_continuous(limits=c(0,600),breaks=c(0, 200, 400, 600), expand = c(0.02,0.02))+
  scale_color_viridis_d()+
  scale_fill_viridis_d()+
  theme_bw(base_size = 11)+
  theme(panel.grid = element_blank(),
        legend.position = c(0.7, 0.65),
        legend.title = element_blank(),
        legend.background = element_blank(),
        legend.spacing = unit(0, 'pt'),
        legend.key.size = unit(4, "mm"),
        axis.title = element_text(size=9)
        )#+
  theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank()) +
  theme(plot.margin = margin(b = 2, unit = "pt"))
dp
# late <- full_join(late, den_summ, by=c("Year", "Region", "SiteCode", "SiteName", "TidalHeight", "Transect"))

# early_summ <- early %>%
#   group_by(year, site, SiteCode) %>%
#   summarise(DiseasedPlants=sum(diseased), Total=length(diseased), DiseasedPer=DiseasedPlants/Total,
#             HealthyPer=1-DiseasedPlants/Total,
#             Severity=mean(severity), DensityMean=mean(density), DensitySE=sd(density)/sqrt(length(density)))
# late_summ <- late %>%
#   group_by(Year, SiteName, SiteCode) %>%
#   summarise(DiseasedPlants=sum(Prevalence), Total=length(Prevalence), Prevalence=sum(Prevalence)/length(Prevalence),
#             DiseasedPer=DiseasedPlants/Total,
#             HealthyPer=1-DiseasedPlants/Total,
#             Severity=mean(Severity), DensityMean=mean(DensityShoots, na.rm=TRUE),DensitySE=sd(DensityShoots)/sqrt(length(DensityShoots)))

late_tran <- late %>%
  group_by(Year, SiteName, SiteCode, Transect) %>%
  summarise(DiseasedPlants=sum(Prevalence), Total=length(Prevalence), Prevalence=sum(Prevalence)/length(Prevalence),
            DiseasedPer=DiseasedPlants/Total,
            HealthyPer=1-DiseasedPlants/Total,
            Severity=mean(Severity))
late_site <- late_tran %>%
  group_by(Year, SiteName) %>%
  summarise(PrevalenceMean=mean(Prevalence), PrevalenceSE=sd(Prevalence)/sqrt(length(Prevalence)))

og_tran <- og %>%
  group_by(Year, SiteName, Transect) %>%
  summarise(Prevalence=sum(Prevalence)/length(Prevalence))
og_site <- og_tran %>%
  group_by(Year, SiteName) %>%
  summarise(PrevalenceMean=mean(Prevalence), PrevalenceSE=sd(Prevalence)/sqrt(length(Prevalence)))
early_prev <- select(early, c("year", "site", "transect", "diseased"))
early_prev_tran <- early_prev %>%
  group_by(Year=year, SiteName=site, Transect=transect) %>%
  summarise(Prevalence=sum(diseased)/length(diseased))
early_site <- early_prev_tran %>%
  group_by(Year, SiteName) %>%
  summarise(PrevalenceMean=mean(Prevalence), PrevalenceSE=sd(Prevalence)/sqrt(length(Prevalence)))
prev <- rbind(early_site, og_site, late_site)
prev$PrevalenceSE[which(is.na(prev$PrevalenceSE))] <- 0
pp <- ggplot(prev, aes(x=Year, y=PrevalenceMean))+
  geom_ribbon(aes(ymin=PrevalenceMean-PrevalenceSE, ymax=PrevalenceMean+PrevalenceSE, fill=SiteName),alpha=0.5)+
  geom_line(aes(color=SiteName))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_x_continuous(limits=c(2013, 2022), breaks=c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022))+
  xlab("Year")+
  ylab(expression(atop("Wasting disease prevalence","(% infected)")))+
  labs(title = "B")+
  scale_color_viridis_d()+
  scale_fill_viridis_d()+
  # scale_color_tableau(palette = "Tableau 10")+
  # scale_fill_tableau(palette = "Tableau 10")+
  theme_bw(base_size = 11)+
  theme(panel.grid = element_blank(),
        legend.position = "",
        legend.title = element_blank(),
        axis.title = element_text(size=9))
pp
dp / pp
ggsave(filename = "Oceanography/Density_Prevalence_update_2022.jpg", width = 6, height = 3.6)
ggsave(filename = "Oceanography/Density_Prevalence_update_2022.tiff", width = 6, height = 3.6)
# ggsave(filename = "Oceanography/Density_Prevalence.jpg", width = 6, height = 3.6)
# ggsave(filename = "Oceanography/Density_Prevalence.tiff", width = 6, height = 3.6)
# ggsave(filename = "Oceanography/Density_Prevalence_resize.jpg", width = 4.25, height = 2.55)
# all <- rbind(early_summ, late_summ)
# all <- full_join(early_summ, late_summ, by=c("year"="Year", "site"="SiteName", "SiteCode", "DiseasedPlants",
#                                              "DiseasedPer", "HealthyPer", 
#                                              "Total", "Severity",
#                                              "DensityMean", "DensitySE"))
# all$fYear <- as.factor(all$year)
# 
# ggplot(all, aes(x=year, y=DiseasedPer, color=SiteCode))+geom_line()+
#   scale_x_continuous(limits=c(2013, 2021), breaks=c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021))
# ggplot(all, aes(x=year, y=Diseased))                      
# ggplot(all, aes(x=year, y=Severity, color=SiteCode))+geom_line()+
#   scale_x_continuous(limits=c(2013, 2021), breaks=c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021))
# ggplot(all, aes(x=year, y=DensityMean, color=site))+geom_line()+
#   scale_x_continuous(limits=c(2013, 2021), breaks=c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021))+
#   xlab("Year")+
#   ylab("Seagrass shoot density (shoots per m2)")+
#   theme_bw(base_size = 14)
den_all_summ <- den_all %>%
  group_by(Year) %>%
  summarise(TotalDensityMean=mean(DensityMean), TotalDensitySE=TotalDensityMean/sqrt(length(DensityMean)))
prev_summ <- prev %>%
  group_by(Year) %>%
  summarise(TotalPrevalenceMean=mean(PrevalenceMean), TotalPrevalenceSE=TotalPrevalenceMean/sqrt(length(PrevalenceMean)))
