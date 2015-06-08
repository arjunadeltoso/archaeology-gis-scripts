# archaeology-gis-scripts
Some helper scripts for GIS in archaeology.

# fix-f.pl

Automatically distribute finds on each grid when granularity of data is too high.

If a grid is in an unknown format it will be skipped and reported in stderr.


Example:

```
$ cat example.csv
grid;stones;bones;coins
50;1;0;3
50a;0;1;0
50b;0;0;0
50c;1;2;0
50+51;0;0;5
51a;1;1;1
wrong;0;0;0
51c;0;1;2
52a;0;0;0
52b;4;3;0
52c;1;0;2
52a+b;1;2;3
$ ./fix.pl example.csv 3
>>>>> wrong
grid;stones;bones;coins
50a;0.333333333333333;1;1.83333333333333
50b;0.333333333333333;0;1.83333333333333
50c;1.33333333333333;2;1.83333333333333
51a;1;1;1.83333333333333
51b;0;0;0.833333333333333
51c;0;1;2.83333333333333
52a;0.5;1;1.5
52b;4.5;4;1.5
52c;1;0;2
```

# fix-r.pl

Same as fix-f.pl just for a different grid system.

# schema.pl

Create ArcGIS schema.ini file from csv header.

Automatically create ArcGIS schema.ini files from the header of a CSV[";"] file.
The first column is considered to be the grid (Text) and everything else the count 
of pieces (Double).

Example:
```
$ head -n 1 example.csv
grid;stones;bones;coins
$ ./schema.pl example.csv
[example.csv]
Col1=grid Text
Col2=stones Double
Col3=bones Double
Col4=coins Double
```
