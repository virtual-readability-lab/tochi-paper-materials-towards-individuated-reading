rm(list = ls())

library(tidyverse)
library(lme4)
library(car)
library(broom)
library(readxl)
library(janitor)
source('~/Documents/R/Functions/repeated-se.R')

data.comp <- read_csv('Data/comprehension.csv') %>% 
  clean_names(sep_out = '.') %>% 
  mutate_at(vars(id.user, id.passage, font.fam, pass.fam, is.non.fiction), as.character)

data.comp.complete <- data.comp %>% 
  group_by(id.user) %>% 
  mutate(n.passages = length(unique(id.passage))) %>% 
  filter(n.passages == 10 & id.user != 355) # all complete users

mat.comp.font <- data.comp %>% 
  group_by(score, font) %>% 
  count() %>% 
  pivot_wider(names_from = font, values_from = n, values_fill = 0)

mat.comp.font <- as.data.frame(mat.comp.font)
rownames(mat.comp.font) <- mat.comp.font$score
mat.comp.font$score <- NULL
mat.comp.font <- as.matrix(mat.comp.font)

mat.comp.passage <- data.comp %>% 
  group_by(score, id.passage) %>% 
  count() %>% 
  pivot_wider(names_from = id.passage, values_from = n, values_fill = 0)

mat.comp.passage <- as.data.frame(mat.comp.passage)
rownames(mat.comp.passage) <- mat.comp.passage$score
mat.comp.passage$score <- NULL
mat.comp.passage <- as.matrix(mat.comp.passage)

# No sig difference in comprehension between fonts: X2 test of independence. X2 = 32.6, p = 0.338
chisq.comp.font <- chisq.test(mat.comp.font)

# No sig difference in comprehension between passages: X2 test of independence. X2 = 32.6, p = 0.338
chisq.comp.passage <- chisq.test(mat.comp.passage)

# Friedman test among block-complete subjects
# Highly significant effect of passage on reading speed, X2(9) = 71.84, p < 0.001
# Simple ANOVA is inappropriate, since observations are non-indepndent (nested within id.user)
fried.passage <- friedman.test(avg.wpm ~ id.passage | id.user, data = data.comp.complete)

# more complete test
# Difficult to think of the correct nesting, given the design, but this comes out non-significant.
lme.passage <- lmer(avg.wpm ~ id.passage + font + (1|id.user), data = data.comp)
car::Anova(lme.passage)

# Fiction vs. Non-Fiction
data.comp %>% 
  group_by(is.non.fiction) %>% 
  summarize(avg.wpm = mean(avg.wpm, na.rm = T))

lme.fiction <- lmer(avg.wpm ~ 1 + (1|id.user) + (1|id.passage), data = data.comp)
lme.b <- lmer(avg.wpm ~ 1 + (1|id.user), data = data.comp)
anova(lme.fiction, lme.b)

summary.passage <- data.comp %>% 
  repeated.se(avg.wpm, id.passage, id.user)

plot.passage <- ggplot(data = summary.passage, aes(x = id.passage, y = mean, ymin = mean - adj.se, ymax = mean + adj.se)) +
  geom_point() +
  geom_errorbar(width = 1/5) +
  labs(y = 'avg_wpm')
print(plot.passage)

lme.font <- lmer(avg.wpm ~ font + (1|id.user), data = data.comp)
car::Anova(lme.font)
