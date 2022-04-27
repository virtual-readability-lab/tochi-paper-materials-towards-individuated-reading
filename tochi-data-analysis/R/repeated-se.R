# Calculates repeated measures standard errors (aka within-subject SEs) for a given data set.
# Respects any pre-existing grouping in the input data frame (handy for performing this operation on multiple DVs at once.)
# Built to play nicely with tidyverse.
#
# df: input data frame
# dep_var: unquoted column name containing the dependent variable
# indep_var: unquoted column name containing the independent variable
# group_var: unquoted column name containing the grouping variable (variable that contains the repeated measures)
# na.rm: should NA values be removed before performing calculations? Defaults to TRUE.
#
# Returns a data frame with columns: 
#   [indep_var]: each level of indep_var; column named in accordance with the unquoted name of "indep_var"
#   mean: simple mean per level of indep_var 
#   n: count of unique levels of group_var within each level of indep_var (usually represents the subject count)
#   adj.se: adjusted standard error for each level of indep_var
#
# In practice, group_var is almost always a subject or participant identifier, while indep_var represents the multiple conditions
# to which every subject was exposed.
# 
# Here "id.user" labels each subject, while "id.passage" is an experimental condition.
# Note that the function respects any tidyverse grouping already present in the data frame.
#
# data.comp %>% 
#   select(id.user, id.passage, score, avg.wpm) %>% 
#   pivot_longer(c(score, avg.wpm), names_to = 'variable', values_to = 'value') %>% 
#   group_by(variable) %>% 
#   repeated.se(value, id.passage, id.user)

repeated.se <- function(df, dep_var, indep_var, group_var, na.rm = T) {
  
  eq_dep_var <- enquo(dep_var)
  eq_indep_var <- enquo(indep_var)
  eq_group_var <- enquo(group_var)
  grps <- groups(df)
  
  summary.df <- df %>% 
    group_by(!!eq_group_var, !!!grps) %>% 
    mutate(adj.dv = !!eq_dep_var - mean(!!eq_dep_var, na.rm = na.rm)) %>% 
    group_by(!!eq_indep_var, !!!grps) %>% 
    summarize(
      mean = mean(!!eq_dep_var, na.rm = na.rm),
      n = n(),
      adj.se = sd(adj.dv, na.rm = na.rm) / sqrt(n - 1)
    ) %>% 
    ungroup
  
  return(summary.df)
  
}