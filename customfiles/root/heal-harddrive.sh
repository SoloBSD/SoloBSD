#!/bin/sh

if [ $# -eq 0 ]; then
	echo "Syntax: $0 hdd-device [ start-lba ]"
	exit 1
fi

GEOM_FLAGS=`sysctl -n kern.geom.debugflags`
if [ $GEOM_FLAGS -ne 16 ]; then
	echo "For security measures this script won't work without" >&2
	echo "you setting the sysctl kern.geom.debugflags to value 16" >&2
	echo "Consider it an 'are you sure' question!" >&2
	echo "It means, you have understood what this script does to" >&2
	echo "your hard disk." >&2
	exit 1
fi

HDD=$1

if [ ! -c ${HDD} ]; then
	echo "Error: ${HDD} must be a device." >&2
	exit 0
fi

SIZE=`diskinfo /dev/ada1 | cut -f 4`

START_LBA=$2
if [ -z $START_LBA ]; then
	START_LBA=0
fi

if [ $START_LBA -lt 0 ] || [ $START_LBA -ge $SIZE ]; then
	echo "Error: ${START_LBA} is out of spec for this device." >&2
	exit 1
fi

# 4k mode
CNT=8
ALIGN_TEST=`expr $START_LBA % ${CNT}`
if [ $ALIGN_TEST -ne 0 ]; then
	echo "Error: start-lba (${START_LBA}) needs to be divisible by ${CNT}." >&2
	exit 1
fi

REPAIRED=0
echo "Requested scan from $START_LBA on ${HDD} (size: $SIZE)"

fix_lba() {
	LBA=$1
	if [ -z $LBA ] || [ $LBA -lt 0 ] || [ $LBA -ge $SIZE ]; then
		echo "Illegal LBA!" >&2
		exit 1
	fi
	echo "Checking LBA $LBA for errors."
	dd if=${HDD} bs=512 count=${CNT} skip=${LBA} of=/dev/null

	if [ $? -ne 0 ]; then
		echo "Replacing LBA $LBA ..."
		dd if=/dev/zero bs=512 count=${CNT} seek=${LBA} of=${HDD}
		REPAIRED=`expr $REPAIRED + 1`
		return 0
	fi

	# malfunctioning (read was OK!)
	return 1
}

while [ $START_LBA -lt $SIZE ]; do

	LEFT=`expr $SIZE - $START_LBA`
	echo "Scanning starting from ${START_LBA} (left: $LEFT)"
	OUT=`dd if=${HDD} bs=512 of=/dev/null skip=${START_LBA} count=${LEFT} 2>&1`
	if [ $? -ne 0 ]; then
		echo "$OUT" | head -n 1 | grep -q 'Input/output error'
		if [ $? -eq 0 ]; then
			STOPPED_CNT=`echo "$OUT" | tail -n 2 | head -n 1 | sed 's/+.*$//'`
			FIX_LBA=`expr $START_LBA + $STOPPED_CNT`
			fix_lba ${FIX_LBA}
			if [ $? -ne 0 ]; then
				echo "Malfunction: read of single LBA was OK!" >&2
				exit 1
			fi
			START_LBA=$FIX_LBA
		fi
	else
		START_LBA=${SIZE}
	fi
done

echo "Finished. $REPAIRED LBAs have been repaired."
exit 0
