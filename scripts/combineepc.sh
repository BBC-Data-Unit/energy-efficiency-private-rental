#!/bin/bash

echo "changing into the all-domestic-certificates folder"
cd all-domestic-certificates
echo "looking for EPC CSV files in folders beginning ‘domestic’"
find domestic* -name "certificates.csv"
echo "copying, moving and renaming those files into the current directory"
num=0; for i in `find domestic* -name "certificates.csv"`; do cp "$i" "$(printf '%03d' $num).${i#*.}"; ((num++)); done
echo "combining all the files into one"
cat *.csv > certificatescombined.csv
