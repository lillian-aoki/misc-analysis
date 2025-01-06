# Script to assemble dataset for 10-y paper

# load libraries ####
library(tidyverse)
library(ggthemes)
library(patchwork)
library(forecast)
library(fpp2)
# library(cowplot)
early <- read_csv("Oceanography/EGWD 2013-2017_MEPS.csv")
late <- read_csv("Oceanography/disease_blade_level.csv")
den <- read_csv("Oceanography/meter_level_density.csv")
og <- read_csv("Oceanography/SJ_SWD_blade18.csv")
fj <- read_csv("Oceanography/density_SJI_1719.csv")
fj <- subset(fj, Site=="Fourth of July" & TidalRegime=="intertidal" & Year!=2019) # no intertidal data in 2018 for FJ
# keep or not? 
fj$Meadow <- "WA_A"
fj$Site <- "E"
og_den <- read_csv("Oceanography/SJ_density18.csv")
og_den <- select(og_den, -SiteName)
og_den <- rbind(og_den, fj)
sitenames_og <- data.frame(Site=c("A", "B", "C", "D", "E"), 
                           SiteName=c("Beach Haven", "North Cove", "Indian Cove", "False Bay", "Fourth of July"))
og <- left_join(og, sitenames_og)
og_den <- left_join(og_den, sitenames_og, )

sitenames <- data.frame(SiteName=c("Fourth of July", "False Bay", "Beach Haven", "North Cove", "Indian Cove"),
                        SiteCode=c("A", "B", "C", "D", "E"))
den <- left_join(den, sitenames)
late <- left_join(late, sitenames)
early <- left_join(early, sitenames, by=c("site"="SiteName"))
early <- subset(early, depth=="Shallow")
late <- subset(late, Region=="WA")
names(late)
den <- subset(den, Region=="WA")

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

## add prevalence, severity, lesion area
## note, not averaging by transect and then site as don't care about site-level SE for prevalence
late_site <- late %>%
  group_by(Year, SiteName, SiteCode) %>%
  summarise(DiseasedPlants=sum(Prevalence), Total=length(Prevalence), Prevalence=sum(Prevalence)/length(Prevalence),
            DiseasedPer=DiseasedPlants/Total,
            HealthyPer=1-DiseasedPlants/Total,
            SeverityMean=mean(Severity), SeveritySE=sd(Severity)/sqrt(length(Severity)),
            LesionAreaMean=mean(LesionArea), LesionAreaSE=sd(LesionArea)/sqrt(length(LesionArea)))

og_site <- og %>%
  subset(TidalRegime=="inter") %>%
  group_by(Year, SiteName) %>%
  summarise(DiseasedPlants=sum(Prevalence), Total=length(Prevalence), Prevalence=sum(Prevalence)/length(Prevalence),
            DiseasedPer=DiseasedPlants/Total,
            HealthyPer=1-DiseasedPlants/Total,
            SeverityMean=mean(Severity), SeveritySE=sd(Severity)/sqrt(length(Severity)),
            LesionAreaMean=mean(LesionArea/100), LesionAreaSE=sd(LesionArea/100)/sqrt(length(LesionArea)))

early_dis <- early %>%
  group_by(Year=year, SiteName=site) %>%
  summarise(DiseasedPlants=sum(diseased), Total=length(diseased), Prevalence=sum(diseased)/length(diseased),
            DiseasedPer=DiseasedPlants/Total,
            HealthyPer=1-DiseasedPlants/Total,
            SeverityMean=mean(severity, na.rm=T), SeveritySE=sd(severity)/sqrt(length(severity)),
            LesionAreaMean=mean(lesionArea/100), LesionAreaSE=sd(lesionArea/100, na.rm=T)/sqrt(length(lesionArea)))
early_dis$SeverityMean[which(is.na(early_dis$SeverityMean))] <- NA
dis <- rbind(early_dis, og_site, late_site)

combo <- full_join(den_all, dis, by=c("Year", "SiteName"))
## add shoot morphologies

ggplot(combo, aes(x=DensityMean, y=Prevalence, color=SiteName))+geom_point()#+
  facet_wrap(~Year)
den_all_wide <- den_all %>%
  ungroup() %>%
  arrange(Year) %>%
  select(-c(DensitySE, Region)) %>%
  pivot_wider(names_from = Year, values_from = DensityMean, names_prefix = "Den") %>%
  mutate(D15_13=Den2015-Den2013, D16_15=Den2016-Den2015, D17_16=Den2017-Den2016, 
         D18_17=Den2018-Den2016, D19_18=Den2019-Den2018, 
         D20_19=Den2020-Den2019, D21_20=Den2021-Den2020, D22_21=Den2022-Den2021)

den_all_long <- den_all_wide %>%
  select(c(SiteName, D15_13, D16_15, D17_16, D18_17, D19_18, D20_19, D21_20, D22_21)) %>%
  pivot_longer(cols = c(D15_13:D22_21), values_to = "DeltaDensity", names_to = "YearPair")
den_all_long <- na.omit(den_all_long)
den_all_long$YearEnd <- as.integer(paste("20",str_extract(den_all_long$YearPair, pattern="\\d{2}"), sep=""))
den_all_long$YearStart <- as.integer(paste("20",str_extract(den_all_long$YearPair, pattern="\\d{2}$"), sep=""))
# raw density changes or percent changes?
# only 36 - would add 9 more with the 2013-2015 change...

combo_start <- full_join(combo, den_all_long, c("SiteName", "Year"="YearStart"))
ggplot(combo_start, aes(x=Prevalence, y=DeltaDensity, color=as.factor(Year)))+geom_point()
ggplot(combo_start, aes(x=SeverityMean, y=DeltaDensity, color=as.factor(Year)))+geom_point()


# shoot density in year+1
den_all_ts <- ts(data = den_all, start = 2013, frequency = 1)
autoplot(den_all_ts)
lag.plot()

den_wide2 <- den_all %>%
  ungroup() %>%
  arrange(Year) %>%
  select(-c(DensitySE, Region)) %>%
  pivot_wider(names_from = SiteName, values_from = DensityMean, names_prefix = "Den") 
den2_ts <- ts(data=select(den_wide2, -c(Year)), start=2013, frequency=1)
autoplot(den2_ts)
lag.plot(den2_ts,lags = 1)
dis_wide <- dis %>%
  ungroup() %>%
  arrange(Year) %>%
  select(Year, SiteName, Prevalence) %>%
  pivot_wider(names_from = SiteName, values_from = Prevalence, names_prefix = "Prev_")
dis_ts <- ts(data=select(dis_wide, -c(Year)), start=2013, frequency=1)
autoplot(dis_ts)
all_years = data.frame(t = seq.Date(from = min(dis$Year), to = max(dis$Year), by = "year"))
pad(dis,interval="year")

dis_long <- dis_wide %>%
  pivot_longer(cols = c(2:11), values_to = "Prevalence", names_to = "SiteName")
dis_long$SiteName <- gsub("Prev_", "",dis_long$SiteName)
ggplot(dis_long, aes(x=Year, y=Prevalence, color=SiteName))+geom_point()+geom_line()
den_all_long$YearEnd <- as.integer(paste("20",str_extract(den_all_long$YearPair, pattern="\\d{2}"), sep=""))
