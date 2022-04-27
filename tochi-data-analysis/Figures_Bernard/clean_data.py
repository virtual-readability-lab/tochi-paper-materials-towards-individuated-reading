import csv, copy
import pandas as pd


df = pd.read_excel('bernard_data_by_user.xlsx')

def getKeyname(name):
    pass

fonts = ['arial','avantgarde','avenir_next','calibri','franklin_gothic','garamond','helvetica','lato','montserrat','open_sans','oswald','poynter_gothic_text','roboto','utopia']

with open('bernard_data_by_user.csv', mode='w') as file:
    writer = csv.writer(file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(df.columns) # write_header

    for k,row in df.iterrows():
        
        fonts_check = copy.deepcopy(fonts)
        if row['most_preferred'] in fonts_check:
            fonts_check.remove(row['most_preferred'])

        row['random1'] = 0
        row['random2'] = 0
        row['random3'] = 0

        i = 1
        for font in fonts_check:
            if row[font] > 0.0:
                rndKey = 'random' + str(i)
                row[rndKey] = row[font]
                i += 1
        writer.writerow(row) # takes array
