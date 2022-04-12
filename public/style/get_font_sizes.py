fonts = {'system':{'n':0,'x':0,'w':0,'h':0}, 'arial':{'n':0,'x':0,'w':0,'h':0}, 'avantgarde':{'n':0,'x':0,'w':0,'h':0}, 'calibri':{'n':0,'x':0,'w':0,'h':0}, 'franklin_gothic':{'n':0,'x':0,'w':0,'h':0}, 'garamond':{'n':0,'x':0,'w':0,'h':0}, 'helvetica':{'n':0,'x':0,'w':0,'h':0}, 'lato':{'n':0,'x':0,'w':0,'h':0}, 'montserrat':{'n':0,'x':0,'w':0,'h':0},'noto_sans':{'n':0,'x':0,'w':0,'h':0}, 'open_sans':{'n':0,'x':0,'w':0,'h':0}, 'oswald':{'n':0,'x':0,'w':0,'h':0}, 'poynter_gothic_text':{'n':0,'x':0,'w':0,'h':0}, 'roboto':{'n':0,'x':0,'w':0,'h':0}, 'times':{'n':0,'x':0,'w':0,'h':0}, 'utopia':{'n':0,'x':0,'w':0,'h':0}, 'source_sans':{'n':0,'x':0,'w':0,'h':0}, 'comic_sans':{'n':0,'x':0,'w':0,'h':0}, 'georgia':{'n':0,'x':0,'w':0,'h':0}, 'raleway':{'n':0,'x':0,'w':0,'h':0}, 'verdana':{'n':0,'x':0,'w':0,'h':0},}

f = open('font_choices_normalized.css','r')
lines = f.readlines()
for l in lines:
    size = ''
    if 'p.' in l:
        choice = l.split('p.')[1].split(' {')[0]
        if '_x' in choice:
            font = choice.split('_x')[0]
            normalization = 'x'
        elif '_w' in choice:
            font = choice.split('_w')[0]
            normalization = 'w'
        elif '_h' in choice:
            font = choice.split('_h')[0]
            normalization = 'h'
        else:
            font = choice
            normalization = 'n'
    if 'font-size: ' in l:
        size = l.split('font-size: ')[1].split('px;')[0]
        fonts[font][normalization] = size
        font = ''
        normalization = ''

for f,n in fonts.items():
    print(f + ',' + n['n'] + ',' + n['x'] + ',' + n['w'] + ',' + n['h'])
    