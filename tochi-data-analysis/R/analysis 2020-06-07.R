# NOTE: reading_speed.csv is based on old, erroneous WPM averages and SHOULD NOT BE USED.

rm(list = ls())

library(tidyverse)
library(lme4)
library(car)
library(broom)

data.speed.raw <- read_csv("Data/reading_speed.csv")

data.speed <- data.speed.raw %>% 
  pivot_longer(-id_user, names_to = 'font', values_to = 'wpm') %>% 
  filter(!is.na(wpm)) %>% 
  group_by(id_user) %>% 
  arrange(id_user, wpm) %>% 
  mutate(
    rank = 0:(n()-1) / 4,
    user_wpm = mean(wpm),
    wpm.adj = wpm - mean(wpm),
    wpm.z = (wpm - mean(wpm)) / sd(wpm)
  )

data.top.font <- data.speed %>% 
  group_by(font) %>% 
  summarize(
    font_tested = n(), 
    fastest_font_n = sum(rank == 1),
    fastest_font_pct = fastest_font_n / font_tested,
    font_wpm = mean(wpm),
    user_wpm_fastest = mean(user_wpm[rank == 1]),
    user_wpm_overall = mean(user_wpm)
  ) %>% 
  arrange(user_wpm_fastest)

summary.speed <- data.speed %>% 
  group_by(font) %>% 
  summarize(
    mean = mean(wpm),
    median = median(wpm),
    n = n()
  ) %>% 
  ungroup %>% 
  arrange(mean)

hist.fonts <- ggplot(data = data.speed, aes(x = wpm)) +
  geom_histogram() +
  facet_wrap(facets = ~font)
print(hist.fonts)

plot.fonts <- data.speed %>% 
  group_by(id_user) %>% 
  mutate(adj.wpm = wpm - mean(wpm)) %>% 
  group_by(font) %>% 
  summarize(
    mean = mean(wpm),
    n = n(),
    adj.se = sd(adj.wpm) / sqrt(n - 1)
  ) %>% 
  arrange(mean) %>% 
  mutate(
    font = gsub('_', ' ', font),
    font = factor(font, unique(font), ordered = T)
  ) %>% 
  ggplot(data = ., aes(x = font, y = mean, ymin = mean - adj.se, ymax = mean + adj.se)) +
  geom_point() +
  geom_errorbar(width = 1/5) +
  geom_text(aes(label = n, y = 250)) +
  scale_y_continuous(breaks = seq(260, 320, 10)) +
  labs(x = NULL, y = 'WPM (±1 SEM)') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))
print(plot.fonts)
ggsave('Output/Plots/reading speed per font 2020-06-07.png', width = 6.5, height = 3.5, dpi = 150)

plot.fonts.z <- data.speed %>% 
  group_by(font) %>% 
  summarize(mean = mean(wpm.z), adj.se = sd(wpm.z) / sqrt(n()), n = n()) %>% 
  arrange(mean) %>% 
  mutate(
    font = gsub('_', ' ', font),
    font = factor(font, unique(font), ordered = T)
  ) %>% 
  ggplot(data = ., aes(x = font, y = mean, ymin = mean - adj.se, ymax = mean + adj.se)) +
  geom_point() +
  geom_errorbar(width = 1/5) +
  #geom_text(aes(label = n, y = 250)) +
  #scale_y_continuous(breaks = seq(260, 320, 10)) +
  labs(x = NULL, y = 'WPM (±1 SEM)') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))
print(plot.fonts.z)
ggsave('Output/Plots/reading speed per font 2020-06-07.png', width = 6.5, height = 3.5, dpi = 150)

# Simplest model to check for effect of font
lme.speed <- lmer(wpm ~ font + (1|id_user), data = data.speed)

# Include user's avg WPM as a covariate
lme.speed.user <- lmer(wpm ~ font * user_wpm + (1|id_user) + (1|user_wpm), data = data.speed)

# significant effect of font, traditional p-value: 0.01997
car::Anova(lme.speed) 

# Significant effects of font, user's WPM (included as a covariate), and their interaction
car::Anova(lme.speed.user) 

# Does font choice depend on reading speed in some way?
  
data.pick <- data.speed %>% 
  ungroup %>% 
  dplyr::select(id_user, user_wpm, font, wpm) %>% 
  mutate(wpm = 1) %>% 
  pivot_wider(names_from = font, values_from = wpm, values_fill = list(wpm = 0)) %>% 
  mutate(reading_group = user_wpm >= median(user_wpm)) %>% 
  pivot_longer(arial:oswald, names_to = 'font', values_to = 'picked') %>% 
  count(font, reading_group, picked) %>% 
  pivot_wider(names_from = reading_group, values_from = n) %>% 
  filter(!(font %in% c('times', 'noto_sans')))

chisq.pick <- data.pick %>% 
  nest(data = c(picked, `FALSE`, `TRUE`)) %>% 
  mutate(p.val = map_dbl(data, function(x) {
    x %>% 
      dplyr::select(-picked) %>% 
      as.matrix %>% 
      chisq.test %>% 
      .$p.value
  }))
