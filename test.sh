#!/bin/bash

A=$1
B=$2

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
    echo "Rendering using $A"
    RES_A=$($A $FILE --renderer="gl" -o temp1.png -b --time=0 --width=$W --height=$H 2>/dev/null | grep Rendered | grep -P -o "(\w+.\w+) ms")

    IFS=\; read -a TA <<<"$RES_A"
    echo "Time taken by A: $TA"

    sleep 1

    echo "Rendering using $B"
    RES_B=$($B $FILE -o temp2.png -b --time=0 --width=$W --height=$H 2>/dev/null | grep Rendered | grep -P -o "(\w+.\w+) ms")

    IFS=\; read -a TB <<<"$RES_B"
    echo "Time taken by B: $TB"

    res=$(compare -metric AE temp1.png temp2.png /dev/null 2>&1);
    if [ "${res}" != '0' ]; then
        FF=$(basename $FILE)
        cp temp1.png "temp/${FF%.*}-1.png"
        cp temp2.png "temp/${FF%.*}-2.png"
        echo "${res}: Different output for file: $FILE"
        echo "Difference stored in file: temp/${FF%.*}-diff.png"
        compare -metric AE temp1.png temp2.png "temp/${FF%.*}-diff.png"
        # composite temp1.png temp2.png -compose difference "temp/${FF%.*}-diff.png"
    fi
    echo "==================================="
    echo ""
    echo "$FILE,$TA,$TB,$res" >> res.csv
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

rm -rf temp && mkdir temp
echo "Rendering files in $3. Width: $W, Height: $H"
echo "filename,time_a,time_b,diff" > res.csv
RenderDir $3
