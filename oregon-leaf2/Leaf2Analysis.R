library(tidyverse)
library(readxl)

or <- read_xlsx(path = "oregon-leaf2/Data_WD_OR_2019_Comparison.xlsx",sheet="data final",trim_ws = TRUE)
head(or)

summary(or)
or$Estuary <- as.factor(or$Estuary)
or$Site <- as.factor(or$Site)
levels(or$Estuary)
levels(or$Site)
leaf <- tibble("Site"=or$Site,"Depth"=or$Depth,"Shoot"=or$`Shoot #`,"Leaf"=or$`Leaf #`,WD=or$`Wasting Disease?`)
head(leaf)
leaf$WD <- gsub("1","0",leaf$WD)
leaf$WD <- gsub("2","1",leaf$WD)

leaf$Leaf <- as.factor(leaf$Leaf)
ggplot(leaf,aes(x=Leaf,fill=WD))+geom_bar(position = "dodge")+facet_grid(rows=vars(Depth),cols = vars(Site))
ggplot(leaf,aes(x=Leaf,fill=WD))+geom_bar(position = position_dodge(preserve = "single"))+
  facet_wrap(~Site)+
  scale_y_continuous(expand = c(0,0),limits=c(0,62))+
  theme_bw()+
  scale_fill_manual(values=c("darkgreen","grey50"),labels=c("Healthy","Diseased"))+
  xlab("Leaf rank")+
  ylab("Number of leaves")+
  theme(legend.title = element_blank())

leaf_summ <- leaf %>%
  group_by(Site,Depth,Leaf)%>%
  summarise(n=length(WD),diseased=length(WD[WD==1]),healthy=length(WD[WD==0]),
            prevalence=diseased/n)
leaf_summ2 <- leaf %>%
  group_by(Site,Leaf)%>%
  summarise(n=length(WD),diseased=length(WD[WD==1]),healthy=length(WD[WD==0]),
            prevalence=diseased/n)

leaf23 <- subset(leaf,Leaf=="2" | Leaf=="3")
head(leaf23)
leaf23$WD <- as.integer(leaf23$WD)
m1 <- glm(WD~Leaf,data=leaf23, family=binomial)
summary(m1)
m2 <- glm(WD~Leaf*Site,data=leaf23, family=binomial)
summary(m2)
drop1(m2)
