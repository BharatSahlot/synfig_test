#!/bin/bash

sscanf() {
  local str="$1"
  local format="$2"
  [[ "$str" =~ $format ]]
}

A=$1
B=$2
REPEATS=5

if [ "$#" -lt "4" ]; then
    W="1920"
else
    W=$4
fi

if [ "$#" -lt "5" ]; then
    H="1080"
else
    H=$5
fi

function RenderOneFile () {
    FILE=$1
    if [[ ! "${FILE##*.}" == "sif" ]]; then
        return 0
    fi

    echo "==================================="
    echo "Testing $FILE"
    echo "Rendering using A"
    RES_A=$($A $FILE --target null -b --repeats=$REPEATS --time=0 --width=$W --height=$H 2>/dev/null | grep Rendered)

    sscanf "$RES_A" "$FILE: Rendered $REPEATS times in (.*) ms. Average time per render: (.*) ms."
    TA=${BASH_REMATCH[2]}
    echo "Time taken by A: $TA"

    echo "Rendering using B"
    RES_B=$($B $FILE --target null -b --repeats=$REPEATS --time=0 --width=$W --height=$H 2>/dev/null | grep Rendered)
    sscanf "$RES_B" "$FILE: Rendered $REPEATS times in (.*) ms. Average time per render: (.*) ms."
    TB=${BASH_REMATCH[2]}

    echo "Time taken by B: $TB"

    IM=$(echo "scale=3; (($TB - $TA) * 100.0) / $TA" | bc -q)

    echo "Speed increase: $IM"

    # res=$(compare -metric AE temp1.png temp2.png /dev/null 2>&1);
    # if [ "${res}" != '0' ]; then
    #     FF=$(basename $FILE)
    #     cp temp1.png "temp/${FF%.*}-1.png"
    #     cp temp2.png "temp/${FF%.*}-2.png"
    #     echo "${res}: Different output for file: $FILE"
    # fi
    # echo "==================================="
    # echo ""
    # echo "$FILE,$TA,$TB,$res" >> res.csv
}

function RenderDir() {
    DIR=$1
    for file in $DIR/*; do
        if [ -d "$file" ]; then
            RenderDir "$file"
        else
            RenderOneFile "$file"
        fi
    done
}

echo "Rendering files in $3. Width: $W, Height: $H"
# echo "filename,time_a,time_b,diff" > res.csv
RenderDir $3
