import csv

with open('study_design.csv', 'r') as f:
    reader = csv.reader(f, delimiter=',')
    next(reader)
    row_i = 1
    for row in reader:
        entry = str(row_i) + ":{"    
        entry = entry + "step:\'" + row[0] + '\','
        entry = entry + "part:\'" + row[1] + '\','
        entry = entry + "block:\'" + row[2] + '\','
        entry = entry + "round:" + row[3] + ','
        entry = entry + "iteration:" + row[4]
        entry = entry + "},"
        print(entry)
        row_i = row_i + 1
