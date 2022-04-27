import csv
import pandas as pd
import scipy as sp

from scipy.stats import mannwhitneyu
from scipy.stats import kruskal

from math import sqrt
from numpy import mean
from numpy import std
from numpy import var


df = pd.read_csv('../Data/main combined data set 2020-09-05_no_passages.csv')


# keys: wpm['id_user']['font'] = [] # arrar of wpms
# need function to grab array for slowest font, and array for fastest font
wpms = {}

def getData(rows):
    id_user = rows['id.user']
    font = rows['font']
    wpm = rows['wpm']
    return id_user,font,wpm


### standardized effect size
# function to calculate Cohen's d for independent samples
def cohensd(d1,d2):
   # calculate the size of samples
   n1, n2 = len(d1), len(d2)
   # calculate the variance of the samples
   s1, s2 = var(d1, ddof=1), var(d2, ddof=1)
   # calculate the pooled standard deviation
   s = sqrt(((n1 - 1) * s1 + (n2 - 1) * s2) / (n1 + n2 - 2))
   # calculate the means of the samples
   u1, u2 = mean(d1), mean(d2)
   # calculate the effect size
   d = (u1 - u2) / s
   #print(f'd = {d}\n')
   return d

# = diff_of_means / sqrt(var(<array all values>))
def cohensd_backup(d1,d2):
    diff_of_means = mean(d1) - mean(d2)
    values = d1 + d2
    return diff_of_means / sqrt(var(values))

def fastestFontWPM(fonts):
    fastestFont = list(fonts.keys())[0]
    fastestFontSpeeds = fonts[fastestFont]
    fastestWpm = mean(fastestFontSpeeds)
    for font,fontSpeeds in fonts.items():
        wpm = mean(fontSpeeds)
        if wpm > fastestWpm:
            fastestFont = font
            fastestFontSpeeds = fontSpeeds
            fastestWpm = wpm
    return fastestFont, fastestFontSpeeds, fastestWpm


def slowestFontWPM(fonts):
    slowestFont = list(fonts.keys())[0]
    slowestFontSpeeds = fonts[slowestFont]
    slowestWpm = mean(slowestFontSpeeds)
    for font,fontSpeeds in fonts.items():
        wpm = mean(fontSpeeds)
        if wpm <= slowestWpm:
            slowestFont = font
            slowestFontSpeeds = fontSpeeds
            slowestWpm = wpm
    return slowestFont, slowestFontSpeeds, slowestWpm


# populate data structure
for k,rows in df.iterrows():
    id_user,font,wpm = getData(rows)
    if id_user not in wpms:
        wpms[id_user] = {font:[wpm]}
    elif font not in wpms[id_user]:
        wpms[id_user][font] = [wpm]
    else:
        wpms[id_user][font].append(wpm)


with open('individual_stats.csv', mode='w') as file:
    writer = csv.writer(file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(['id_user','fastest_slowest_cohens_d','mann_whitney_stat','mann_whitney_p'])

    for id_user,fonts in wpms.items():
        

        fastFont,fastFontSpeeds,fastFontWpm = fastestFontWPM(fonts)
        slowFont,slowFontSpeeds,slowFontWpm = slowestFontWPM(fonts)
        fastSlowSpeeds = fastFontSpeeds + slowFontSpeeds
        
        # id_user 126 only has 1 value for their slowest font
        if len(fastFontSpeeds) == 1 or len(slowFontSpeeds) == 1:
            d = cohensd_backup(fastFontSpeeds,slowFontSpeeds)
        else:
            d = cohensd(fastFontSpeeds,slowFontSpeeds)
        statM, pM = mannwhitneyu(fastFontSpeeds,slowFontSpeeds)

        # kruskal
        i = 0
        fontsWPM = {}
        for font,values in fonts.items():
            fontsWPM[i] = values
            i += 1
        if len(fonts) == 5:
            stat, p = kruskal(fontsWPM[0],fontsWPM[1],fontsWPM[2],fontsWPM[3],fontsWPM[4])
        elif len(fonts) == 4:
            stat, p = kruskal(fontsWPM[0],fontsWPM[1],fontsWPM[2],fontsWPM[3])
        elif len(fonts) == 3:
            stat, p = kruskal(fontsWPM[0],fontsWPM[1],fontsWPM[2])
        elif len(fonts) == 2:
            stat, p = kruskal(fontsWPM[0],fontsWPM[1])

        #print(id_user,stat,p)

        writer.writerow([id_user,d,statM,pM,stat,p])


"""

1.
compute cohen's d for fastest vs slowest
do histogram for cohen's d


2.
do mann whitney u
just fastest vs slowest


3. 
compute kruskal wallis
across all fonts per person

does font alone lead to differences in reading speeds?
if p < 0.05 there are pairs of fonts that 


-- per person results
results[id_user]:
cohensd
mannwhitneyu
kruskal

"""