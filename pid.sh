#!/bin/bash

PROCESS=$1
GENERATION_LEVEL=$2


if [[ $# -eq 0 ]]
then
	echo "Please give exactly one argument"
	rm -f processes.log
	exit 1
fi


if [[ $GENERATION_LEVEL -eq "" ]]
then
	GENERATION_LEVEL=3

	NAME=`ps -p $PROCESS -o comm=` 
	PARENTS=`pstree -s -p $PROCESS|head -1|sed 's/-+-/|/g'|sed "s/$NAME.*$//"|sed 's/[-+|]/ /g'`
	
	if [[ -z $NAME ]]
	then
		echo "PID $PROCESS is not a real process or it is a LWP"
		rm -f processes.log
		exit 1
	fi

	if [[ ! -z "$PARENTS" ]]
	then
		echo -e Parents of process $NAME is/are $PARENTS"\n">out.tmp
	else
		echo -e Process $NAME is the root process"\n">out.tmp
	fi 



	sudo netstat -pant|grep ESTABLISHED >network.tmp
	echo -e Generation "\t      "PID "\t"Process_name"\t\t"Network>>out.tmp
	echo -n "Process	  	      $PROCESS		">>out.tmp
elif [[ $GENERATION_LEVEL -eq 6 ]]
then
	echo >>out.tmp
	exit 1 
else
	GENERATION_LEVEL=$2
fi






case $GENERATION_LEVEL in
	3)PREFIX="Child		    ";;
	4)PREFIX="Grandchild	    ";;
	5)PREFIX="Great Grandchild    ";;
esac








PROCESS_NAME=`ps -f -p $PROCESS -o comm=`

echo -en $PROCESS_NAME >>out.tmp
NETWORK=`grep "$PROCESS/$PROCESS_NAME" network.tmp`
if [[ -z NETWORK ]]
then
	echo "" >>out.tmp
else
	echo -e "\t\t\t ${NETWORK}">>out.tmp
fi
pstree -p $PROCESS |sed 's/{.*$//'|sed 's/-+-/|/g'|sed 's/---/|/g'|sed 's/`-/|/g'|sed 's/|-/|/g'>processes.tmp


awk -F"|" '{print $2}' processes.tmp|grep -v ^"   "|sed 's/[()]/ /g'|awk '{print $2}'>child_PID${GENERATION_LEVEL}.tmp


while read CHILD
do
	if [[ $CHILD -ne "" ]]
	then
		echo -en "$PREFIX  $CHILD \t" >>out.tmp
 		./pid.sh $CHILD $[GENERATION_LEVEL+1]


	fi
done<child_PID${GENERATION_LEVEL}.tmp
sed "s/\t$/___/g" out.tmp|grep -v ___ >processes.log
#rm child_*.tmp processes.tmp
