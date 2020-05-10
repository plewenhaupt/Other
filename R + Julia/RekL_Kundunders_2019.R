library(googlesheets)
library(ggplot2)
library(ggrepel)
library(dplyr)
library(tidyr)
library(scales)
library(lubridate)
library(cowplot)
library(ggrepel)

# IMPORT  #####################
gs_auth(new_user = FALSE)
sheet <- gs_ls()
utv <- gs_key(pull(sheet[1,6]))
utv_data <- gs_read(utv)
colnames(utv_data) <- c("tid","kontakt", "service", "information", "forvantan", "svar", "alder", "kon")
utv_data$tid <- as.Date(utv_data$tid)
utv_data$year <- as.factor(year(utv_data$tid))
utv_data[24, 2] <- "E-post"
utv_data[108, 2] <- "Hemsida"
utv_data[114, 2] <- "Hemsida"
utv_data[173, 2] <- "Hemsida"
utv_data[194, 2] <- "Hemsida"
utv_data[137, 8] <- "Annat"
utv_data <- utv_data %>% mutate(kon = ifelse(is.na(kon), 'Annat', kon))

utv_2018 <- utv_data[utv_data$tid < '2019-08-19',]
utv_2019 <- utv_data[utv_data$tid >= '2019-08-19',]

# ANALYSIS  ###################
#Frequency contact
freq_kontakt <- utv_data %>% group_by(year, kontakt) %>% tally()
freq_kontakt <- freq_kontakt %>% 
                group_by(year) %>% 
                mutate(CountT = sum(n)) %>% 
                ungroup %>% 
                mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))

kontaktchart <- ggplot(freq_kontakt, aes(x=kontakt))
kontaktchart <- kontaktchart + geom_col(aes(y=percent_num, group = year, fill=year), position = "dodge")
kontaktchart <- kontaktchart + geom_text(aes(y=percent_num, label=percent_labels, group = year), vjust = -.4, size=3, position = position_dodge(width = 1))
kontaktchart <- kontaktchart + theme_light()
kontaktchart <- kontaktchart + theme(plot.margin = margin(10, 10, 20, 20), axis.text.x = element_text(hjust = 1, size = 9, angle=30), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
kontaktchart <- kontaktchart + scale_fill_brewer(palette = "Set1", direction = -1)
kontaktchart <- kontaktchart + ggtitle("Hur kontaktade du Försvarsmaktens rekryteringslinje?")

#Frequency service
freq_service <- utv_data %>% group_by(year, service) %>% tally()
freq_service <- freq_service %>% 
  group_by(year) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))


servicechart <- ggplot(freq_service, aes(x=service))
servicechart <- servicechart + geom_col(aes(y=percent_num, group=year, fill=year), position = "dodge")
servicechart <- servicechart + geom_text(aes(y=percent_num, label=percent_labels, group = year), vjust = -.4, size=3, position = position_dodge(width = 1))
servicechart <- servicechart + scale_x_reverse(labels=c(7, 6, 5, 4, 3, 2, 1), breaks=c(7, 6, 5, 4, 3, 2, 1))
servicechart <- servicechart + theme_light()
servicechart <- servicechart + theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
servicechart <- servicechart + scale_fill_brewer(palette = "Set1", direction = -1)
servicechart <- servicechart + ggtitle("Hur upplevde du servicen som helhet när du var i kontakt med rekryteringslinjen?")


#Frequency förväntan
freq_forvantan <- utv_data %>% group_by(year, forvantan) %>% tally()
freq_forvantan <- freq_forvantan %>% 
  group_by(year) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))

forvantanchart <- ggplot(freq_forvantan, aes(x=forvantan))
forvantanchart <- forvantanchart + geom_col(aes(y=percent_num, group=year, fill=year), position = "dodge")
forvantanchart <- forvantanchart + geom_text(aes(y=percent_num, label=percent_labels, group = year), vjust = -.4, size=3, position = position_dodge(width = 1))
forvantanchart <- forvantanchart + scale_x_reverse(labels=c(7, 6, 5, 4, 3, 2, 1), breaks=c(7, 6, 5, 4, 3, 2, 1))
forvantanchart <- forvantanchart + theme_light()
forvantanchart <- forvantanchart + theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
forvantanchart <- forvantanchart + scale_fill_brewer(palette = "Set1", direction = -1)
forvantanchart <- forvantanchart + ggtitle("Vilken förväntan hade du på din kontakt med rekryteringslinjen?")

#Frequency svar
freq_svar <- utv_data %>% group_by(year, svar) %>% tally()
freq_svar <- freq_svar %>% 
  group_by(year) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))
freq_svar$svar <- factor(freq_svar$svar, levels = c('Ja, fullständigt', 'Ja, till stor del', 'Ja, delvis', 'Nej, inte alls'))

svarchart <- ggplot(freq_svar, aes(x=svar))
svarchart <- svarchart + geom_col(aes(y=percent_num, group=year, fill=year), position = "dodge")
svarchart <- svarchart + geom_text(aes(y=percent_num, label=percent_labels, group = year), vjust = -.4, size=3, position = position_dodge(width = 1))
svarchart <- svarchart + theme_light()
svarchart <- svarchart + theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
svarchart <- svarchart + scale_fill_brewer(palette = "Set1", direction = -1)
svarchart <- svarchart + ggtitle("Fick du svar på din fråga/dina frågor?")


#Frequency information
freq_information <- utv_data %>% group_by(year, information) %>% tally()
freq_information <- freq_information %>% 
  group_by(year) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))


informationchart <- ggplot(freq_information, aes(x=information))
informationchart <- informationchart + geom_col(aes(y=percent_num, group=year, fill=year), position = "dodge")
informationchart <- informationchart + geom_text(aes(y=percent_num, label=percent_labels, group = year), vjust = -.4, size=3, position = position_dodge(width = 1))
informationchart <- informationchart + scale_x_reverse(labels=c(7, 6, 5, 4, 3, 2, 1), breaks=c(7, 6, 5, 4, 3, 2, 1))
informationchart <- informationchart + theme_light()
informationchart <- informationchart + theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
informationchart <- informationchart + scale_fill_brewer(palette = "Set1", direction = -1)
informationchart <- informationchart + ggtitle("Hur nöjd är du med den information du fick av rekryteringslinjen?")

#Frequency kön
freq_kon <- utv_data %>% group_by(year, kon) %>% tally()
freq_kon <- freq_kon %>% arrange(desc(kon)) %>%
  group_by(year) %>% 
  mutate(CountT = sum(n), pos = cumsum(n)-(n/2)) %>% 
  ungroup %>%
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")")) %>% 
  arrange(kon)
freq_kon_year <- group_split(freq_kon, year)

konchart <- lapply(freq_kon_year, function(i){
yr <- pull(i[1, 1])
konchart <- ggplot(i, aes(x=""))
konchart <- konchart + geom_col(aes(y=n, fill=kon), position="stack")
konchart <- konchart + geom_text_repel(aes(y=pos, label=percent_labels))
konchart <- konchart + theme_bw()
konchart <- konchart + theme(panel.border = element_blank(), axis.text = element_blank(), axis.ticks = element_blank(), panel.grid  = element_blank(), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
konchart <- konchart + coord_polar("y", start=0)
konchart <- konchart + scale_fill_brewer(palette = "Set1", direction = 1)
konchart <- konchart + ggtitle(paste0("Svarandens kön ", yr))
})

kon_grid <- plot_grid(konchart[[1]], 
                      konchart[[2]],
                      ncol = 2, align = "hv")

#kontakt per gender
freq_kontakt_kon <- utv_2019 %>% group_by(kontakt, kon) %>% tally()
freq_kontakt_kon <- freq_kontakt_kon %>% 
  group_by(kon) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))

kontaktchart_kon <- ggplot(freq_kontakt_kon, aes(x=kontakt))
kontaktchart_kon <- kontaktchart_kon + geom_col(aes(y=percent_num, group=kon, fill=kon), position = "dodge", width = .7)
kontaktchart_kon <- kontaktchart_kon + geom_text_repel(aes(y=percent_num, label=percent_labels, group = kon), vjust = -.4, size=3, position = position_dodge(width = .7))
kontaktchart_kon <- kontaktchart_kon + theme_light()
kontaktchart_kon <- kontaktchart_kon + theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
kontaktchart_kon <- kontaktchart_kon + scale_fill_brewer(palette = "Set2", direction = -1)
kontaktchart_kon <- kontaktchart_kon + ggtitle("Hur kontaktade du Försvarsmaktens rekryteringslinje?")

#Service per gender
freq_service_kon <- utv_2019 %>% group_by(service, kon) %>% tally()
freq_service_kon <- freq_service_kon %>% 
  group_by(kon) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))

servicechart_kon <- ggplot(freq_service_kon, aes(x=service))
servicechart_kon <- servicechart_kon + geom_col(aes(y=percent_num, group=kon, fill=kon), position = "dodge", width = .7)
servicechart_kon <- servicechart_kon + geom_text(aes(y=percent_num, label=percent_labels, group = kon), vjust = -.4, size=3, position = position_dodge(width = .7))
servicechart_kon <- servicechart_kon + scale_x_reverse(labels=c(7, 6, 5, 4, 3, 2, 1), breaks=c(7, 6, 5, 4, 3, 2, 1))
servicechart_kon <- servicechart_kon + theme_light()
servicechart_kon <- servicechart_kon + theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
servicechart_kon <- servicechart_kon + scale_fill_brewer(palette = "Set2", direction = -1)
servicechart_kon <- servicechart_kon + ggtitle("Hur upplevde du servicen som helhet när du var i kontakt med rekryteringslinjen?")

#Service per kontakt
freq_service_kontakt <- utv_2019 %>% group_by(service, kontakt) %>% tally()
freq_service_kontakt <- freq_service_kontakt %>% 
  group_by(kontakt) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))

servicechart_kontakt <- ggplot(freq_service_kontakt, aes(x=service)) +
                        geom_col(aes(y=percent_num, group=kontakt, fill=kontakt), position = "dodge", width = .7) +
                        geom_text(aes(y=percent_num, label=percent_labels, group = kontakt), vjust = -.4, size=3, position = position_dodge(width = .7)) +
                        scale_x_reverse(labels=c(7, 6, 5, 4, 3, 2, 1), breaks=c(7, 6, 5, 4, 3, 2, 1)) +
                        theme_light() +
                        theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top") +
                        scale_fill_brewer(palette = "Set2", direction = -1) + 
                        ggtitle("Hur upplevde du servicen som helhet när du var i kontakt med rekryteringslinjen?")

#Forvantan per gender
freq_forvantan_kon <- utv_2019 %>% group_by(forvantan, kon) %>% tally()
freq_forvantan_kon <- freq_forvantan_kon %>% 
  group_by(kon) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))

forvantanchart_kon <- ggplot(freq_forvantan_kon, aes(x=forvantan))
forvantanchart_kon <- forvantanchart_kon + geom_col(aes(y=percent_num, group=kon, fill=kon), position = "dodge", width = .7)
forvantanchart_kon <- forvantanchart_kon + geom_text_repel(aes(y=percent_num, label=percent_labels, group = kon), vjust = -.4, size=3, position = position_dodge(width = .7))
forvantanchart_kon <- forvantanchart_kon + scale_x_reverse(labels=c(7, 6, 5, 4, 3, 2, 1), breaks=c(7, 6, 5, 4, 3, 2, 1))
forvantanchart_kon <- forvantanchart_kon + theme_light()
forvantanchart_kon <- forvantanchart_kon + theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
forvantanchart_kon <- forvantanchart_kon + scale_fill_brewer(palette = "Set2", direction = -1)
forvantanchart_kon <- forvantanchart_kon + ggtitle("Vilken förväntan hade du på din kontakt med rekryteringslinjen?")

#Svar per gender
freq_svar_kon <- utv_2019 %>% group_by(svar, kon) %>% tally()
freq_svar_kon <- freq_svar_kon %>% 
  group_by(kon) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))
freq_svar_kon$svar <- factor(freq_svar$svar, levels = c('Ja, fullständigt', 'Ja, till stor del', 'Ja, delvis', 'Nej, inte alls'))

svarchart_kon <- ggplot(freq_svar_kon, aes(x=svar))
svarchart_kon <- svarchart_kon + geom_col(aes(y=percent_num, group=kon, fill=kon), position = "dodge", width = .7)
svarchart_kon <- svarchart_kon + geom_text_repel(aes(y=percent_num, label=percent_labels, group = kon), vjust = -.4, size=3, position = position_dodge(width = .7))
svarchart_kon <- svarchart_kon + theme_light()
svarchart_kon <- svarchart_kon + theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
svarchart_kon <- svarchart_kon + scale_fill_brewer(palette = "Set2", direction = -1)
svarchart_kon <- svarchart_kon + ggtitle("Fick du svar på din fråga/dina frågor?")


#Information per gender
freq_information_kon <- utv_2019 %>% group_by(information, kon) %>% tally()
freq_information_kon <- freq_information_kon %>% 
  group_by(kon) %>% 
  mutate(CountT = sum(n)) %>% 
  ungroup %>% 
  mutate(percent_num = n/CountT, percent_char = percent(percent_num), percent = percent_num*100, percent_labels = paste0(percent_char, " (", n, ")"))

informationchart_kon <- ggplot(freq_information_kon, aes(x=information))
informationchart_kon <- informationchart_kon + geom_col(aes(y=percent_num, group=kon, fill=kon), position = "dodge", width = .7)
informationchart_kon <- informationchart_kon + geom_text(aes(y=percent_num, label=percent_labels, group = kon), vjust = -.4, size=3, position = position_dodge(width = .7))
informationchart_kon <- informationchart_kon + scale_x_reverse(labels=c(7, 6, 5, 4, 3, 2, 1), breaks=c(7, 6, 5, 4, 3, 2, 1))
informationchart_kon <- informationchart_kon + theme_light()
informationchart_kon <- informationchart_kon + theme(axis.text.x = element_text(hjust = 1, size = 9), axis.title = element_blank(), legend.title = element_blank(), legend.position = "top")
informationchart_kon <- informationchart_kon + scale_fill_brewer(palette = "Set2", direction = -1)
informationchart_kon <- informationchart_kon + ggtitle("Hur nöjd är du med den information du fick av rekryteringslinjen?")

# SAVE  #########################
save(freq_kontakt, file = "freq_kontakt.RData")
save(kontaktchart, file = "kontaktchart.RData")
save(freq_service, file = "freq_service.RData")
save(servicechart, file = "servicechart.RData")
save(freq_information, file = "freq_forvantan_con.RData")
save(informationchart, file = "informationchart.RData")
save(freq_forvantan, file = "freq_forvantan.RData")
save(forvantanchart, file = "forvantanchart.RData")
save(freq_svar, file = "freq_svar.RData")
save(svarchart, file = "svarchart.RData")
save(freq_kon_year, file = "freq_kon_year.RData")
save(kon_grid, file = "kon_grid.RData")

save(freq_kontakt_kon, file = "freq_kon_con.RData")
save(kontaktchart_kon, file = "konchart_con.RData")
save(freq_service_kon, file = "freq_service_con.RData")
save(servicechart_kon, file = "servicechart_con.RData")
save(freq_information_kon, file = "freq_information_con.RData")
save(informationchart_kon, file = "informationchart_con.RData")
save(freq_forvantan_kon, file = "freq_forvantan_con.RData")
save(forvantanchart_kon, file = "forvantanchart_con.RData")
save(freq_svar_kon, file = "freq_svar_con.RData")
save(svarchart_kon, file = "svarchart_con.RData")



