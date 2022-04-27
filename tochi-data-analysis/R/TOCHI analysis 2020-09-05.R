# Results for this study begin in section 5.3.
#
# 
# Checks:
#   X Comprehension x id.passage
#   X WPM x id.passage
#   X Comprehension x font
#   X Familiarity effect (comprehension / WPM x timestamp)
#   X Ordering of passages.
#   X Fiction vs. non-fiction: WPM and comprehension
#   X Counterbalancing of passages. (typefaces varied by user, so cannnot check that)
#     - No big worries on these checks.
#   X Font familiarity, passage familiarity, passage interest.
# 
# Key Questions:
#   - Each user saw 5 fonts: Noto (best overall), Times (baseline), preferred font from pref test, and two random fonts.
#   - Did the preferred font perform better? Was comprehension higher?
#   - Same for Noto and Times.
#   X Omnibus differences across typefaces for comprehension and WPM.
#     X Posthoc tests for biggest differences.
#   X WPM ~ age, comprehension ~ age
#   X Is the effect of font more pronounced among users >= 35 years old?
#    - YES!
#   X Effect of device type (should be non-sig, but good to include)
#
# GENERAL NOTES
# Shaun's email on 2020-09-03 indicates that the old avg_wpm metric is incorrect.
# The avg_wpm_new metric matches my own data, and unfortunately does not show a wpm ~ font significant relationship.
# This is why even a simple model specification of wpm ~ font + (1|id.user) is no longer significant (as it was in my 2020-06-07 analysis).
#
# I have played around with many, many specifications for LME models. 
# While there are many possible ways to specify a model, in practice, once you have the main fixed and random effects in place, most variations end up similar.
# It looks like we simply do not have significant differences in either WPM or comprehension by font, across the board.
# Even doing the simplest aggregation possible (avg wpm per user and font), and then testing that, fails to find significance.
# Significant effect of font appears with participants aged 35 or order.

rm(list = ls())

library(tidyverse)
library(readxl)
library(lme4)
library(lmerTest)
library(broom)
library(janitor)
library(r2glmm) # to get R2 values for LME objects
library(MuMIn)
library(performance) # for check_collinearity()
source('R/repeated-se.R') # custom function for comuting within-subject summaries

lme.effect.size <- function(lme.object) {
  
  # Taken from a general method described in Brysbaert & Stevens, 2018. "Power Analysis and Effect Size in Mixed Effects Models".
  # Per that paper, effect size estimates using this technique tend to be quite small, since they account for all factors at once.
  
  var.corr <- VarCorr(lme.object)
  ranefs <- sapply(var.corr, '[[', 1)
  ranefs['residuals'] <- attr(var.corr, 'sc')^2
  fixed.ef <- fixef(lme.object) / sqrt(sum(ranefs))
  
  return(fixed.ef)

}

data.main <- read_csv('Data/main combined data set 2020-09-05.csv')

# wpm ~  age + device + is.fave.font + font + order.passage + iteration + is.non.fiction + pass.fam + pass.int + font.fam + (1|id.user) + (1|id.passage), data = data.main)

# A quick check to see if WPM depends on each font's *relative rank* within participant (i.e., 1 = slowest, 5 = fastest).
# There is such an effect, but it turns out to be entirely dependent on Avantgarde. Without that font, there is no effect.
# Additionally, in order to create a tidy set of 5 ranks per participant, a lot of other predictors must be dropped.
data.wpm.rank <- data.main %>% 
  group_by(id.user, age, device, is.fave.font, font, font.fam) %>% 
  summarize(mean.wpm = mean(wpm), mean.order = mean(order.passage)) %>% 
  group_by(id.user) %>% 
  arrange(id.user, mean.wpm) %>% 
  mutate(rank.wpm = as.numeric(factor(mean.wpm))) %>% 
  ungroup %>% 
  filter(font != 'avantgarde')

summary.wpm.rank <- repeated.se(data.wpm.rank, rank.wpm, font, id.user) %>% 
  arrange(mean) %>% 
  mutate(font = factor(font, font, ordered = T))

ggplot(data = summary.wpm.rank, aes(x = font, y = mean, ymin = mean - adj.se, ymax = mean + adj.se)) +
  geom_point() +
  geom_errorbar(width = 1/5) +
  coord_flip()

lme.rank <- lmer(rank.wpm ~ font + device + font.fam + (1|id.user), data = data.wpm.rank)
car::Anova(lme.rank)

# end of ranking test

# 118 unique users
data.older <- data.main %>% 
  filter(age >= 35) %>% 
  na.omit

# Demographics
data.demo <- data.main %>% 
  select(id.user, age, gender, fave.font, minutes, avg.user.wpm, avg.user.comp) %>% 
  unique

summary.demo <- data.demo %>% 
  summarize_at(vars(age, minutes, avg.user.wpm, avg.user.comp), mean, na.rm = T)

summary.demo.gender <- data.demo %>% 
  filter(gender %in% c('male', 'female')) %>% 
  group_by(gender) %>% 
  mutate(n = n()) %>% 
  summarize_at(vars(age, minutes, avg.user.wpm, avg.user.comp, n), mean, na.rm = T)

count.age <- data.demo %>% 
  group_by(age.range = floor(age / 10) * 10) %>% 
  count %>% 
  ungroup %>% 
  mutate(perc = n / sum(n))

# No differences by gender for age, total minutes, avg wpm, or avg comprehension (all p > 0.06).
# Though age and avg comprehension do come a bit close. 
# The avg comprehension is bounded at 100%, so I wouldn't worry about any near significance there.
# Wilcoxon rank sum test with continuity correction used for all tests due to skewed distributions.
t.gender <- data.demo %>% 
  select(-fave.font) %>% 
  filter(gender %in% c('male', 'female')) %>% 
  pivot_longer(c(age, minutes, avg.user.wpm, avg.user.comp), names_to = 'variable', values_to = 'value') %>% 
  nest(data = c(id.user, gender, value)) %>% 
  mutate(
    t.test = map(data, function(x) wilcox.test(value ~ gender, data = x)),
    t.broom = map(t.test, tidy)
  ) %>% 
  unnest(t.broom)

# Counterbalancing of passage order
# Order did not depend on passage ID, randomization worked. 
order.passage <- data.main %>% 
  select(id.user, id.passage, order.passage) %>% 
  distinct %>% 
  mutate(id.passage = as.character(id.passage))

lme.order <- order.passage %>% 
  lmer(order.passage ~ id.passage + (1|id.user), data = .) %>% 
  car::Anova()

count.passage.order <- order.passage %>% 
  group_by(id.passage, order.passage) %>% 
  count() %>% 
  group_by(id.passage) %>% 
  arrange(id.passage, desc(n)) %>% 
  ungroup %>% 
  mutate(
    order.bin = cut(n, seq(0, 100, 10)),
    order.bin = factor(order.bin, sort(unique(order.bin)), ordered = T)
  )

plot.order.grid <- ggplot(data = count.passage.order, aes(x = factor(id.passage), y = factor(order.passage), fill = order.bin)) +
  geom_tile()
print(plot.order.grid)

# Counterbalancing of font order
# It's just shy of significant Given how sparse the font assignments are, it's probably fine.
# If we remove avantgarde from the data, we are well outside significance. Probably just a fluke. avantgrade was only seen by 37 participants.
data.font.order <- data.main %>% 
  select(id.user, id.passage, font, order.passage) %>% 
  distinct %>% 
  group_by(id.user, font) %>% 
  summarize(order.font = mean(order.passage)) 

order.font <- data.font.order %>% 
  filter(!(font %in% c('avantgarde'))) %>% 
  lmer(order.font ~ font + (1|id.user), data = .) %>% 
  car::Anova()

data.font.order %>% 
  group_by(font) %>% 
  summarize(mean = mean(order.font)) %>% 
  arrange(mean) %>%  
  mutate(font = factor(font, font, ordered = T)) %>% 
  ggplot(data = ., aes(x = font, y = mean)) + 
  geom_point() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

# Omnibus model for WPM
# Technically, a model where each user is weighted by number of available screens (max of 20) performs better than an unweighted model.
# However, it produces no meaningful differences in the final results. Let a reviewer catch this one.
# Important: Effect of font is significant among participants >= 35 years of age.
# Garamond and Open Sans stick out as outliers in this group, but even removing them, effect of font remains.

lme.omni.wpm <- lmer(wpm ~ age + device + font + order.passage + iteration + is.non.fiction + pass.fam + pass.int + font.fam + (1|id.user) + (1|id.passage), data = data.main)
step.omni.wpm <- lmerTest::step(lme.omni.wpm)
check_collinearity(lme.omni.wpm) # Variable Inflation Factors (VIF) all < 2, well below the "problematic" cutoff of 10+

# Test to see if a screen * font interaction matters. Nope!
lme.iteration.wpm <- lmer(wpm ~  age + device + font + order.passage + iteration + (iteration:font) + is.non.fiction + pass.fam + pass.int + font.fam + (1|id.user) + (1|id.passage), data = data.main)
step.iter.wpm <- lmerTest::step(lme.iteration.wpm)

# pseudo-R2 measures for each fixed effect
rsq.omni.wpm <- r2beta(lme.omni.wpm, method = 'nsj')

# overall R2 for the entire model
# R2m (marginal) = contribution of fixed effects; R2c (conditional) = contribution of random + fixed effects
MuMIn::r.squaredGLMM(lme.omni.wpm)

# WPM models for first and second screens separately.
# In the overall model, font p = 0.20; 1st screen only: p = 0.06; 2nd only: p = 0.38
# Points to fonts exerting a greater effect on the first screen than the second.
data.first <- data.main %>% filter(iteration == 1)
lme.first.wpm <- lmer(wpm ~  age + device + font + order.passage + is.non.fiction + pass.fam + pass.int + font.fam + (1|id.user) + (1|id.passage), data = data.first)
step.first.wpm <- lmerTest::step(lme.first.wpm)
rsq.first.wpm <- r2beta(lme.first.wpm, method = 'nsj')

data.second <- data.main %>% filter(iteration == 2)
lme.second.wpm <- lmer(wpm ~ age + device + font + order.passage + is.non.fiction + pass.fam + pass.int + font.fam + (1|id.user) + (1|id.passage), data = data.second)
step.second.wpm <- car::Anova(lme.second.wpm)
rsq.second.wpm <- r2beta(lme.second.wpm, method = 'nsj')

lme.omni.wpm.older <- lmerTest::lmer(wpm ~ is.fave.font + age + device + font + order.passage + iteration + is.non.fiction + pass.fam + pass.int + font.fam + (1|id.user) + (1|id.passage), data = data.older)
step.omni.wpm.older <- lmerTest::step(lme.omni.wpm.older)

rsq.omni.wpm.older <- r2beta(lme.omni.wpm.older, method = 'nsj')
rsq.font.older.total <- filter(rsq.omni.wpm.older, grepl('font', Effect)) %>% 
  pull(Rsq) %>% 
  sum

# Test to see if a screen * font interaction matters. Nope!
lme.iteration.wpm.older <- lmer(wpm ~  age + device + font + order.passage + iteration + (iteration:font) + is.non.fiction + pass.fam + pass.int + font.fam + (1|id.user) + (1|id.passage), data = data.older)
step.iter.wpm.older <- lmerTest::step(lme.iteration.wpm.older)

lme.first.wpm.older <- lmerTest::lmer(wpm ~ age + device + font + order.passage + is.non.fiction + pass.fam + pass.int + font.fam + (1|id.user) + (1|id.passage), data = data.older %>% filter(iteration == 1))
step.first.wpm.older <- step(lme.first.wpm.older)

lme.second.wpm.older <- lmerTest::lmer(wpm ~ age + device + font + order.passage + is.non.fiction + pass.fam + pass.int + font.fam + (1|id.user) + (1|id.passage), data = data.older %>% filter(iteration == 2))
step.second.wpm.older <- step(lme.second.wpm.older)

# Omnibus model for comprehension
# These data are really weird. Since the only possible comprehension values are 0, 0.5, and 1, and 84% are 1, 
# let's treat anything that isn't 1 as 0, and use a logistic GLM for prediction.
data.comprehend <- data.main %>% 
  select(id.user, is.fave.font, device, font, id.passage, order.passage, font.fam, pass.fam, pass.int, age, pass.comprehend, comp.binary, is.non.fiction) %>% 
  unique

data.comprehend.older <- data.comprehend %>% 
  filter(age >= 35) %>% 
  mutate_at(vars(age, order.passage), ~((. - min(.)) / (max(.) - min(.))))


glmer.omni.comp <- glmer(comp.binary ~ id.passage + device + font + age + order.passage + font.fam + pass.fam + pass.int + is.non.fiction + (1|id.user) + (1|id.passage), data = data.comprehend, family = 'binomial')
car::Anova(glmer.omni.comp)
rsq.omni.comp <- r2beta(glmer.omni.comp)
check_collinearity(glmer.omni.comp)

glmer.omni.comp.older <- glmer(comp.binary ~ device + font + age + order.passage + font.fam + pass.fam + pass.int + is.non.fiction + (1|id.user) + (1|id.passage), 
                               data = data.comprehend.older, 
                               family = 'binomial'
                               )

glmer.omni.comp.older.es <- glmer(comp.binary ~ device + age + order.passage + pass.int + is.non.fiction + (1|id.user) + (1|id.passage), 
                               data = data.comprehend.older, 
                               family = 'binomial'
)

car::Anova(glmer.omni.comp.older.es)
rsq.omni.comp.older <- r2beta(glmer.omni.comp.older.es)

rsq.device.older.total <- filter(rsq.omni.comp.older, grepl('device', Effect)) %>% 
  pull(Rsq) %>% 
  sum

# Very simple tests to see if favorite font affected anything.
# Nope.
data.fave.font.wpm <- data.main %>% 
  select(id.user, age, fave.font, is.fave.font, wpm) %>% 
  group_by(id.user, age, fave.font, is.fave.font) %>% 
  summarize(wpm = mean(wpm))

lme.fave.font.wpm <- lmer(wpm ~ is.fave.font + (1|id.user), data = data.fave.font.wpm)
lmerTest::step(lme.fave.font.wpm)

t.test(wpm ~ is.fave.font, paired = T, data = data.fave.font.wpm %>% group_by(id.user) %>% filter(n() == 2))

# is favorite font more likely to be fastest font?
# Not even remotely. Similar to original report, the favorite font is equally likely to be the participant's fastest or slowest font (19.6% vs 20.2%, respectively)
data.fave.fast <- data.main %>% 
  group_by(id.user, fave.font, font) %>% 
  summarize(wpm = mean(wpm)) %>% 
  group_by(id.user) %>% 
  mutate(is.fastest = wpm == max(wpm), is.slowest = wpm == min(wpm)) %>% 
  filter(font == fave.font) %>% 
  select(id.user, is.fastest, is.slowest) %>% 
  distinct %>% 
  ungroup %>% 
  summarize_at(vars(is.fastest, is.slowest), mean)

# Visualizations and data tables
summary.font.wpm <- data.main %>% 
  mutate(age.group = ifelse(age >= 35, '35 and Older', 'Under 35'),
         age.group = factor(age.group, c('Under 35', '35 and Older'), ordered = T)
  ) %>% 
  group_by(id.user, age.group, font) %>% 
  summarize(wpm = mean(wpm)) %>% 
  group_by(age.group) %>% 
  repeated.se(wpm, font, id.user) %>% 
  arrange(desc(age.group), mean) %>% 
  ungroup %>% 
  mutate(font = factor(font, unique(font), ordered = T))
write_csv(summary.font.wpm, 'Output/fonts by age means and SEs 2020-12-09.csv')

plot.font.wpm <- summary.font.wpm %>% 
  ggplot(data = ., aes(x = font, y = mean, ymin = mean - adj.se, ymax = mean + adj.se, color = age.group)) +
  geom_point(position = position_dodge(width = 0.45)) +
  geom_errorbar(width = 1/2, position = position_dodge(width = 0.45), show.legend = F) +
  coord_flip() +
  scale_color_manual(values = c('red', 'black')) +
  labs(x = NULL, y = 'Average Reading Speed (WPM)', color = NULL) +
  theme(legend.position = c(1, 0), legend.justification = c(1, 0), legend.background = element_rect(fill = NA))
print(plot.font.wpm)
ggsave('Output/Plots/reading speed per font and age 2020-09-08.png', width = 6.5, height = 6.5, scale = 0.75)

# Effect of passage order on WPM
plot.order.passage <- data.main %>% 
  group_by(id.user, order.passage) %>% 
  summarize(wpm = mean(wpm)) %>% 
  ungroup %>%  
  repeated.se(wpm, order.passage, id.user) %>% 
  ggplot(data = ., aes(x = order.passage, y = mean, ymin = mean - adj.se, ymax = mean + adj.se)) + 
  geom_point() + 
  geom_errorbar(width = 1/5) +
  scale_x_continuous(breaks = 1:10)
print(plot.order.passage)

lme.order.passage <- data.main %>% 
  group_by(id.user, order.passage) %>% 
  summarize(wpm = mean(wpm)) %>% 
  lmer(wpm ~ order.passage + (1|id.user), data = .)

# Did preference for Garamond matter? Seemingly yes, but why only this one?
data.garamond <- data.main %>% 
  group_by(id.user, font, fave.font) %>% 
  summarize(wpm = mean(wpm)) %>% 
  group_by(id.user) %>% 
  mutate(garamond = fave.font == 'garamond') %>% 
  group_by(id.user, garamond) %>% 
  summarize(mean.wpm = mean(wpm))

wilcox.garamond <- wilcox.test(mean.wpm ~ garamond, data = data.garamond)
data.garamond %>% group_by(garamond) %>% summarize(wpm = mean(mean.wpm))

# Visualizing and summarizing effect of order and iteration
data.iteration <- data.main %>% 
  group_by(id.user, order.passage, iteration) %>% 
  summarize(wpm = mean(wpm)) %>% 
  group_by(iteration) %>% 
  repeated.se(wpm, order.passage, id.user)

plot.iteration <- data.iteration %>% 
  mutate(iteration = as.character(iteration)) %>% 
  ggplot(data = ., aes(x = order.passage, y = mean, ymin = mean - adj.se, ymax = mean + adj.se, color = iteration)) +
  geom_point() +
  geom_errorbar(width = 1/5) +
  scale_x_continuous(breaks = 1:10)
print(plot.iteration)

mean.iteration <- data.iteration %>% 
  group_by(iteration) %>% 
  summarize(wpm = mean(mean))

# Strong main effects of passage order and screen number, as well as an interaction of the two,
# which suggests that the two iterations have different slopes across passage order.
lme.iteration <- lmer(wpm ~ order.passage * iteration + (1|id.user), data = data.main)

# For Screen 1, there is a non-significant slope across passage (0.63 WPM/passage, = 0.118)
# For Screen 2, significant slope (2.15 WPM/passage, p = 0.002)
slope.iteration <- data.iteration %>% 
  nest(data = c(order.passage, mean, adj.se, n)) %>% 
  mutate(
    lm = map(data, ~(lm(mean ~ order.passage, data = .))),
    lm.broom = map(lm, tidy)
  ) %>% 
  unnest(lm.broom)

# Fiction vs. non-fiction
mean.fiction <- data.main %>% 
  group_by(is.non.fiction) %>% 
  summarize(wpm = mean(wpm))

# Device usage counts and percentages
data.device <- data.main %>% 
  select(id.user, age, gender, device) %>% 
  unique %>% 
  group_by(device) %>% 
  count %>% 
  ungroup %>% 
  mutate(perc = n / sum(n))

# Does WPM depend on passage length, perchance?
# Sort of? It's a positive effect.  The more words, the higher the WPM, which seems counterintuitive.
# Maybe suggests skimming? But the effect is much weaker for chars, and slightly negative (and non-sig) for sentences.

data.length <- data.main %>% 
  select(id.user, id.passage, order.passage, age, font, words, wpm) %>% 
  unique

lme.length <- lmer(wpm ~ age + words + order.passage + font + (1|id.user) + (1|id.passage), data = data.length)
car::Anova(lme.length)

# is.fave.font did not matter in the larger models, and was removed. But does a simpler model show anything?
# Definitely not.
lme.fave <- lmer(wpm ~ is.fave.font + (1|id.user), data = data.main) %>% 
  car::Anova()

# Simple paired t-test also fails to find signficance
t.fave <- data.main %>% 
  select(id.user, is.fave.font, wpm) %>% 
  group_by(id.user, is.fave.font) %>% 
  summarize(wpm = mean(wpm)) %>% 
  pivot_wider(names_from = is.fave.font, values_from = wpm) %>% 
  .[complete.cases(.), ] %>% 
  pivot_longer(-c(id.user)) %>% 
  t.test(value ~ name, data = ., paired = T)

# Simple effect of age
lm.age <- data.main %>% 
  group_by(id.user, age) %>% 
  summarize(wpm = mean(wpm)) %>% 
  lm(wpm ~ age, data = .)

# Simple effect of age among older cohort
lm.age <- data.older %>% 
  group_by(id.user, age) %>% 
  summarize(wpm = mean(wpm)) %>% 
  lm(wpm ~ age, data = .)

# Observed effect sizes for the first-screen model
data.first.order <- data.first %>% 
  group_by(id.user, order.passage) %>% 
  summarize(wpm = mean(wpm))

# In this case, a within-subject model is the correct way to report the effect size
lme.first.order <- data.first.order %>% 
  lmer(wpm ~ order.passage + (1|id.user), data = .)
summary(lme.first.order)

# Mean device WPM for first screens
data.device <- data.first %>% 
  group_by(device) %>% 
  summarize(wpm = mean(wpm))

# effect of age for first screens
lm.first.age <- data.first %>% 
  group_by(id.user, age) %>% 
  summarize(wpm = mean(wpm)) %>% 
  lm(wpm ~ age, data = .)

# effect of age for second screens
lm.second.age <- data.second %>% 
  group_by(id.user, age) %>% 
  summarize(wpm = mean(wpm)) %>% 
  lm(wpm ~ age, data = .)

data.second.order <- data.second %>% 
  group_by(id.user, order.passage) %>% 
  summarize(wpm = mean(wpm))

lme.second.order <- data.second.order %>% 
  lmer(wpm ~ order.passage + (1|id.user), data = .)
summary(lme.second.order)

# Fiction vs. non-fiction: second screens
mean.fiction.second <- data.second %>% 
  group_by(is.non.fiction) %>% 
  summarize(wpm = mean(wpm))

# Comprehension vs. fiction status
mean.comprehend.fiction <- data.comprehend %>% 
  group_by(is.non.fiction) %>% 
  summarize(comprehend = mean(pass.comprehend))

mean.comprehend.fiction <- data.comprehend.older %>% 
  group_by(is.non.fiction) %>% 
  summarize(comprehend = mean(pass.comprehend))

# Effect of age on comprehension for older participants
lm.comprehend.older <- data.comprehend.older %>% 
  glm(pass.comprehend ~ age, data = ., family = 'binomial')
