#!/bin/bash

OUTPUTFILE="./shucg.vim"
PYFILE="./pcg.py"
VIMLFILE="./vcg.vim"
LICENSEFILE="./LICENSE"

rm $OUTPUTFILE
touch $OUTPUTFILE
cat $LICENSEFILE >> $OUTPUTFILE
echo "python << EndPy" >> $OUTPUTFILE
cat $PYFILE >> $OUTPUTFILE
echo "EndPy" >> $OUTPUTFILE
echo "\n\n\"=====VIML_BEGIN=====\n\n" >> $OUTPUTFILE
cat $VIMLFILE >> $OUTPUTFILE
echo "done"
