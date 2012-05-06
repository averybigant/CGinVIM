#

OUTPUTFILE="./shucg.vim"
PYFILE="./pcg.py"
VIMLFILE="./vcg.vim"

rm $OUTPUTFILE
touch $OUTPUTFILE
echo "python << EndPy" >> $OUTPUTFILE
cat $PYFILE >> $OUTPUTFILE
echo "EndPy" >> $OUTPUTFILE
echo "\n\n\"=====VIML_BEGIN=====\n\n" >> $OUTPUTFILE
cat $VIMLFILE >> $OUTPUTFILE
echo "done"
