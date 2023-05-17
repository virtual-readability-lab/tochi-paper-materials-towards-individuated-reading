# Code, Data, and Materials from TOCHI Paper
## Towards Individuated Reading Experiences: Different Fonts Increase Reading Speed for Different Individuals

SHAUN WALLACE, Brown University, Adobe Inc.

ZOYA BYLINSKII, Adobe Inc.

JONATHAN DOBRES, Virtual Readability Lab, University of Central Florida

BERNARD KERR, Adobe Inc.

SAM BERLOW, Typography for Good

RICK TREITMAN, Adobe Inc.

NIRMAL KUMAWAT, Adobe Inc.

KATHLEEN ARPIN, Riverdale Country School

DAVE B. MILLER, Virtual Readability Lab, University of Central Florida

JEFF HUANG, Brown University

BEN D. SAWYER, Virtual Readability Lab, University of Central Florida

# HOW TO RUN LOCALLY?

```
npm i
nodemon app.js
```

# DATABASE

This version of the code uses sqlite. When nodemon app.js is run it will automatically create the database and tables.
The database is located in the /db folder.

# FONTS

The paper features Avenir Next. However, we cannot provide the source font due to licensing terms. Instead the code has been changed to use someone's system font instead.

# Reading Passages and Source

The source files are located in:
```
passages_source/readability_reading_passages_TOCHI.zip
```

This source has been used within index.html for the readability test.
