#!/bin/bash

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

    # TODO : check 'convert' is installed

	INPUTSIZE=$(identify $INPUT | cut -f 3 -d ' ')
	X=$(echo $INPUTSIZE | cut -f 1 -d 'x')
	Y=$(echo $INPUTSIZE | cut -f 2 -d 'x')

	TARGETSIZE=$(cat $MOCKS/$NAME/mockup.txt | grep "size:" | cut -f 2 -d ':' |  sed -e 's/^ *//' -e 's/ *$//')

	TARGETPOINTS=$(cat $MOCKS/$NAME/mockup.txt | grep "target:" | cut -f 2 -d ':' |  sed -e 's/^ *//' -e 's/ *$//' -e "s/ +/ /" )

	BACKGROUND=$(cat $MOCKS/$NAME/mockup.txt | grep "background:" | cut -f 2 -d ':' |  sed -e 's/^ *//' -e 's/ *$//')
	FOREGROUND=$(cat $MOCKS/$NAME/mockup.txt | grep "foreground:" | cut -f 2 -d ':' |  sed -e 's/^ *//' -e 's/ *$//')

	P1=$(echo $TARGETPOINTS | cut -f 1 -d ' ' | sed -e "s/[xX]/,/g")
	P2=$(echo $TARGETPOINTS | cut -f 2 -d ' ' | sed -e "s/[xX]/,/g")
	P3=$(echo $TARGETPOINTS | cut -f 3 -d ' ' | sed -e "s/[xX]/,/g")
	P4=$(echo $TARGETPOINTS | cut -f 4 -d ' ' | sed -e "s/[xX]/,/g")

	echo "screenshot input size : $INPUTSIZE"
	echo "target size : $TARGETSIZE"
	echo "target points : $TARGETPOINTS"

	echo "generating output image ..."

	convert \
		\( \
			$MOCKS/$NAME/$BACKGROUND \
			\( \
				$INPUT \
				-virtual-pixel transparent \
				-define distort:viewport=${TARGETSIZE}+0+0 \
				-distort Perspective "0,0 $P1  $X,0 $P2  $X,$Y $P3  0,$Y $P4 "  \
				-matte \
			\) \
			-composite \
		\) \
		$MOCKS/$NAME/$FOREGROUND \
		-composite \
		$OUTPUT

#		 \


	echo "done."

	# open $OUTPUT

}

function tmp {


		convert \
		$INPUT \
		-virtual-pixel transparent \
		-define distort:viewport=${TARGETSIZE}+0+0 \
		-distort Perspective "0,0 $P1  $X,0 $P2  $X,$Y $P3  0,$Y $P4 " \
		/tmp/out.png

	composite /tmp/out.png $MOCKS/$NAME/$BACKGROUND $OUTPUT

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






