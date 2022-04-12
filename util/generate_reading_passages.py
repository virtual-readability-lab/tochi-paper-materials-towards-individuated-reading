import csv

with open('documents.tsv', 'r') as f:
    reader = csv.reader(f, dialect='excel-tab')
    head = next(reader)
    row_size = len(head)
    row_i = 0
    for row in reader:
        entry = row[0] + ':{'
        i = 1
        for v in row[i:]:
            entry = entry + head[i] +  ':\"' + v + '\"'
            if (i+1) < row_size:
                entry = entry + ','
            i = i + 1
        entry = entry + '},'
        print(entry)
        row_i = row_i + 1
