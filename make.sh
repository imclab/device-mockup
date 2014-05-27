#!/bin/bash

function process() {
NAME=$1
FILE=$2

HERE=$(dirname $0)
META=$HERE/mockups/$NAME/mockup.txt

if [ ! -f $META ];
then
	echo "unknown mockup $NAME"
	exit
fi

TARGET=$(cat $META | grep "target:" | cut -f 2 -d ':')

# input : 640 x 1136
# output : 1200 x 1268
#  178X191 210X137 670X601 438X677

# 0,0     640,0   640,1136   0,1136
# 178,191 210,137 670,601   438,677
#convert $FILE  -matte -virtual-pixel transparent  -distort Affine '0,0 178,191  640,0 210,137  640,1136 670,601 0,1136  438,677' -transform +repage out.png

convert  $FILE -virtual-pixel transparent -define distort:viewport=1200x1268+0+0 -distort Perspective '0,0 178,191  640,0 410,137  640,1136 670,601   0,1136 438,677 '  \
	out.png


composite   ./out.png ./mockups/iphone-mockup-white/iphone-mockup-white-1.png out2.png

open out2.png

}

########################################################################
##        help                                                        ##
########################################################################

function help() {
	echo "Usage : "
	echo "    $0 --help                                              : this help"
	echo "    $0 --list                                              : list all available mocks"
	echo "    $0 <mock name> <input screenshot path> <output file>   : make a mock image"
	exit 1
}

########################################################################
##  list available mockups                                            ##
########################################################################

function list() {
	echo "available mockups : "
	MOCKS=$(dirname $0)/mockups/
	ALL=$(ls $MOCKS)
	for MOCK in $ALL;
	do
		MOCK=$(basename $MOCK)
		DESCR=$(cat $MOCKS/$MOCK/mockup.txt | grep description: | cut -f 2 -d ':')
		echo "    $MOCK : $DESCR" 
	done
	exit 1
}

########################################################################
##  process                                                           ##
########################################################################

function process() {
	MOCKS=$(dirname $0)/mockups/

	NAME=$1
	INPUT=$2
	OUTPUT=$3

	if [ ! -d "$MOCKS/$NAME" ];
	then
		echo "ERROR : unknown mockup name $NAME"
		exit
    fi

	INPUTSIZE=$(identify $INPUT | cut -f 3 -d ' ')
	X=$(echo $INPUTSIZE | cut -f 1 -d 'x')
	Y=$(echo $INPUTSIZE | cut -f 2 -d 'x')

	TARGETSIZE=$(cat $MOCKS/$NAME/mockup.txt | grep "size:" | cut -f 2 -d ':' |  sed -e 's/^ *//' -e 's/ *$//')

	TARGETPOINTS=$(cat $MOCKS/$NAME/mockup.txt | grep "target:" | cut -f 2 -d ':' |  sed -e 's/^ *//' -e 's/ *$//' -e "s/ +/ /" )

	BACKGROUND=$(cat $MOCKS/$NAME/mockup.txt | grep "background:" | cut -f 2 -d ':' |  sed -e 's/^ *//' -e 's/ *$//')

	P1=$(echo $TARGETPOINTS | cut -f 1 -d ' ' | sed -e "s/[xX]/,/g")
	P2=$(echo $TARGETPOINTS | cut -f 2 -d ' ' | sed -e "s/[xX]/,/g")
	P3=$(echo $TARGETPOINTS | cut -f 3 -d ' ' | sed -e "s/[xX]/,/g")
	P4=$(echo $TARGETPOINTS | cut -f 4 -d ' ' | sed -e "s/[xX]/,/g")

	echo "screenshot input size : $INPUTSIZE"
	echo "target size : $TARGETSIZE"
	echo "target points : $TARGET"

	echo "generating output image ..."
	convert \
		$INPUT \
		-virtual-pixel transparent \
		-define distort:viewport=${TARGETSIZE}+0+0 \
		-distort Perspective "0,0 $P1  $X,0 $P2  $X,$Y $P3  0,$Y $P4 " \
		/tmp/out.png

	composite /tmp/out.png $MOCKS/$NAME/$BACKGROUND $OUTPUT

	echo "done."

	# open $OUTPUT

}

if [ "$#" == "0" ];
then
	help
fi

if [ "$1" == "--list" ];
then
	list
fi

if [ "$1" == "--help" ];
then
	help
fi

process $1 $2 $3






