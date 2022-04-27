rm(list = ls())
library(tidyverse)
library(janitor)

# 386 unique users, 10 unique passages, 16 unique fonts
# Screening out users affected by the font bug, we are down to 352
data.passage <- read_csv('Data/reading_data_2020-09-05.csv') %>% 
  clean_names(sep_out = '.') %>% 
  select(-id, -user.type, -avg.wpm, -x19, -study.step, -device) %>% 
  arrange(id.user, timestamp) %>% 
  group_by(id.user) %>% 
  mutate(
    order.passage = as.numeric(factor(id.passage, unique(id.passage), ordered = T))
  ) %>% 
  group_by(id.user, id.passage) %>% 
  mutate(fonts.per.passage = length(unique(font))) %>% 
  group_by(id.user) %>% 
  filter(id.user > 81) # screening out early participants who saw multiple fonts per passage

data.comprehension <- read_csv('Data/comprehension.csv')  %>% 
  clean_names(sep_out = '.') %>% 
  select(id.user, id.passage, pass.comprehend = score, font.fam, pass.fam, pass.int) %>% 
  arrange(id.user, id.passage) %>% 
  group_by(id.user) %>% 
  mutate(total.passages = length(unique(id.passage)))

data.demo.raw <- read_csv('Data/raw demographics 2020-09-06.csv') %>% 
  clean_names(sep_out = '.') %>% 
  mutate(
    gender = case_when(
      tolower(gender) == 'male' | tolower(gender) == 'm' ~ 'male',
      grepl('(female|f|woman|femaile)', tolower(gender)) ~ 'female',
      is.na(gender) ~ 'unknown',
      T ~ 'other'
    ),
    device = tolower(device),
    language = tolower(language),
    lang.comf = tolower(lang.comf)
  ) %>% 
  select(id.user, fave.font = font, fave.font.fam = font.familiarity, device, age, gender, language, lang.comf, minutes, avg.user.wpm = wpm, avg.user.comp = avg.comp) 

# final data set
# 352 users with Shaun's existing exclusion criteria
data.main <- data.passage %>% 
  ungroup %>% 
  inner_join(data.comprehension, by = c('id.user', 'id.passage')) %>% 
  left_join(data.demo.raw, by = 'id.user') %>% 
  mutate_at(vars(id.user, device, id.passage), as.character) %>% 
  mutate(
    comp.binary = ifelse(pass.comprehend  > 0.99, 1, 0), # binarize comprehension outcome so that logistic modeling is possible
    is.fave.font = font == fave.font
  ) %>% 
  group_by(id.user) %>% 
  mutate(weight = n() / 20)

write_csv(data.main, 'Data/main combined data set 2020-09-05.csv')
