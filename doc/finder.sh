#!/bin/bash

DIRNAME=$1

if [ $# != 1 ]; then
    echo
    echo "  USAGE: finder [dirname]"
    echo
    exit -1
else
  invalid="$(echo ${DIRNAME} | grep -c '/')"
  if [ ${invalid} == 1 ]; then
    echo
    echo "  ERROR: the dirname must not contain slashes"
    echo
    exit -1
  fi
fi

echo "-----------------------------------------------------"
echo "  $DIRNAME"
echo "-----------------------------------------------------"

echo "- List directories..."
ls -d $DIRNAME/* > ${DIRNAME}_dirs.txt

echo "- List files..."
find $DIRNAME -type f ! -name 'Thumbs.db' ! -name '.DS_Store' -print > ${DIRNAME}_files.txt

echo "- Get stats..."
echo "$DIRNAME" > ${DIRNAME}_stats.txt
echo "- Dirs count: $(ls -d $DIRNAME/* | wc -l)" >> ${DIRNAME}_stats.txt
echo "- Files count: $(find $DIRNAME -type f ! -name 'Thumbs.db' ! -name '.DS_Store' | wc -l)" >> ${DIRNAME}_stats.txt
echo "- Total size: $(du -sh $DIRNAME)" >> ${DIRNAME}_stats.txt

echo

#######################################################################
# Opzionali

# Immagini più pesanti di 200k
# find . -type f -size +200k | wc -l

#echo "- List PDF files..."
#find $DIRNAME/*/*.pdf -type f -print > ${DIRNAME}_pdf_files.txt

#echo "- TIFF size: ..."
#du -ch $DIRNAME/*/*/

#echo "- PDF size: ..."
#du -ch $DIRNAME/*/*.pdf

#echo
