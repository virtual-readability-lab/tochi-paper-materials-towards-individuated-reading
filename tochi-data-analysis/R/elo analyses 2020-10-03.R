rm(list = ls())
library(tidyverse)
library(lme4)
source('R/repeated-se.R')

subjects <- read_csv('Data/main combined data set 2020-09-05.csv') %>% 
  pull(id.user) %>% 
  unique

data.elo <- read_csv('Data/elo ratings 2020-10-03.csv') %>% 
  filter(id_user %in% subjects) %>% 
  mutate(elo.norm =(elo - mean(elo)) / sd(elo))

lme.elo <- lmer(elo.norm ~ font + (1|id_user), data = data.elo)
car::Anova(lme.elo)

data.elo %>% 
  select(id_user, font, elo) %>% 
  pivot_wider(names_from = font, values_from = elo) %>% 
  View

summary.elo <- repeated.se(data.elo, elo.norm, font, id_user)
plot.elo <- ggplot(data = summary.elo, aes(x = font, y = mean, ymin = mean - adj.se, ymax = mean + adj.se)) +
  geom_point() +
  geom_errorbar(width = 1/5) +
  coord_flip()
print(plot.elo)

hist.elo <- ggplot(data = data.elo, aes(x = elo)) +
  geom_histogram() +
  facet_wrap(facets = ~font) +
  geom_vline(xintercept = 1500)
print(hist.elo)

elo.user <- data.elo %>% 
  group_by(id_user) %>% 
  summarize(mean = mean(elo), sd = sd(elo))
