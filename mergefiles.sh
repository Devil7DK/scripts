#!/bin/bash
#==============================================================================
# title           :  mergefiles.sh                                            #
# description     :  Script to merge text files from one folder to another. I #
#                    wrote this to merge sepolicies from other trees to mine. #
#                    (Very useful for kanging sepolicies xD)                  #
# author          :  Devil7DK                                                 #
# date            :  22/04/2019                                               #
# usage           :  bash mergefiles.sh <directory 1> <directory 2>           #
# notes           :  Requires bash v4.3+                                      #
#==============================================================================

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Arguements
CMD=$0
DIR1=$1
DIR2=$2

usage() {
	echo "usage: $CMD <dir1> <dir2>"
	echo ""
	echo "        All files from <dir2> will be merged to files in <dir1>. If a"
	echo "        file is only exists in <dir2>, it will be copied to <dir1>."
	echo "        While merging only unique lines will be kept."
}

function trim() {
	echo ${1//[$' \t\n\r']/}
}

function trimEnds() {
	echo "$1" | sed -e 's/^[ \t]*//'
}

function contains() {
	local value="$1"
	shift
	local array=("$@")
	if [[ $(trim $(indexOf "$value" "${array[@]}")) == "-1" ]];then
		return 1
	else
		return 0
	fi
}

function indexOf() {
	local value="$1"
	shift
	local array=("$@")
	for i in "${!array[@]}"; do
		if [[ "$(trim "${array[$i]}")" == "$(trim "$value")" ]]; then
			echo "$i"
			return;
		fi
	done
	echo -1
}

function indexOfEmpty() {
	local -n array=$1
	for i in "${!array[@]}"; do
		val="$(trim "${array[$i]}")"
		if [ -z "$val" ]; then
			echo "$i"
			return;
		fi
	done
	echo -1
}

function append() {
	local value=$1
	local -n array=$2
	
	if [ -z "$(trim "$value")" ] && [ -z "$(trim "${array[-1]}")" ]; then
		return;
	fi

	array=( "${array[@]}" "$value" )
}

function insert() {
	local index=$1
	local value=$2
	local -n array=$3
	array=( "${array[@]:0:$index}" "$value" "${array[@]:$index}" )
}

function printarray() {
	local array=("$@")
	echo "count ${#array[@]}"
	while read -r e; do
		echo $e
	done <<< "$@"
}

function writearray() {
	local filename="$1"
	shift
	array=("$@")
	rm -rf "$filename"
	maxIndex=$((${#array[@]}-1))
	for index in "${!array[@]}"; do
		line="${array[$index]}"
		if [ "$index" == "$maxIndex" ] && [ -z "$(trimEnds "$line")" ]; then
			echo "" > /dev/null
		else
			echo "$(trimEnds "$line")" >> $filename
		fi
	done
}

function merge() {
	local -n FILE1=$1
	local -n FILE2=$2
	
	#echo "BEFORE:"
	#printArray "${FILE1[@]}"
	
	HEADING="";
	EMPTYLINE=$(echo -e "\r\n")
	for i in "${!FILE2[@]}"; do
		line="${FILE2[$i]}"
		
		if [[ "$(trim "$line")" == \#* ]]; then
			HEADING=$(trim "$line")
			if ! contains "$line" "${FILE1[@]}"; then
				append "$line" FILE1
				continue
			fi
		elif [ -z $(trim "$line") ] && [ ! -z "$HEADING" ]; then
			HEADING=""
		fi
		
		if [ -z "$(trim "$line")" ]; then
			append "$line" FILE1
		else
			if [[ $(trim $(indexOf  "$(trim "$line")" "${FILE1[@]}")) == "-1" ]]; then
				if [ -z "$HEADING" ]; then
					append "$line" FILE1
				else
					local index=$(trim $(indexOf  "$(trim "$HEADING")" "${FILE1[@]}"))
					local tmpArray=("${FILE1[@]:${index}}")
					local nextIndex=$(indexOfEmpty tmpArray)
					if [ $nextIndex == "-1" ]; then
						nextIndex=1
					fi
					insert $(($index+$nextIndex)) "$line" FILE1
				fi
			fi
		fi
	done

	#echo "AFTER:"
	#printArray "${FILE1[@]}"
}

if ((BASH_VERSINFO[0] < 4)) || ((((BASH_VERSINFO[0] == 4)) && ((BASH_VERSINFO[1] < 3)))); then 
  echo -e "${BLUE}Sorry, you need at least bash-4.3 to run this script! :-/${NC}"
  exit 1
fi

if [ -z "$DIR1" ]; then
	usage
	exit 0
fi

if [[ ! -d "$DIR1" ]]; then
	echo "\"$DIR1\" doesn't exist or is not a directory!"
	exit 1
fi

if [[ ! -d "$DIR2" ]]; then
	echo "\"$DIR2\" doesn't exist or is not a directory!"
	exit 1
fi

FILES=$(ls $DIR1 $DIR2 | sort | uniq)
MERGED=0
COPIED=0
SKIPED=0
while read -r FILE; do
	if [ ! -z "$FILE" ]; then
		FILE1=${DIR1%%/}/$FILE
		FILE2=${DIR2%%/}/$FILE
		if [ -f "$FILE1" ] && [ -f "$FILE2" ]; then
			echo -e "${GREEN}MERGING:${NC}$FILE"
			readarray LINES1 < "$FILE1"
			readarray LINES2 < "$FILE2"
			merge LINES1 LINES2
			writearray "$FILE1" "${LINES1[@]}"
			((MERGED++))
		elif [ ! -f "$FILE1" ] && [ -f "$FILE2" ]; then
			echo -e "${BLUE}COPYING:${NC}$FILE"
			cp "$FILE2" "$FILE1"
			((COPIED++))
		elif [ -f "$FILE1" ] && [ ! -f "$FILE2" ]; then
			echo -e "${YELLOW}SKIPING:${NC}$FILE"
			((SKIPED++))
		fi
	fi
done <<< "$FILES"

echo ""
echo -e "        ${ORANGE}==================${NC}"
printf "        ${GREEN}%s %04d$NC\n" "Files Merged:" $MERGED
printf "        ${BLUE}%s %04d$NC\n" "Files Copied:" $COPIED
printf "        ${YELLOW}%s %04d$NC\n" "Files Skiped:" $SKIPED
echo -e "        ${ORANGE}==================${NC}"
echo ""