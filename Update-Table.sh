#!/bin/bash

shopt -s extglob
LC_ALL=C

function Update-Table () {
    mapfile -t arrayMeta < data/$currentDB/meta-data/$currentTB.md
    mapfile -t tableData < data/$currentDB/tables/$currentTB

    for (( i=0; i<${#arrayMeta[@]}; i++ ))
    do 
       primaryKeyFieledNum=`awk -F: '{if ($3==1) print NR;}' data/$currentDB/meta-data/$currentTB.md` 
       primaryKeyFieledName=`awk -F: '{if ($3==1) print $1;}' data/$currentDB/meta-data/$currentTB.md`
       primaryKeyFieledType=`awk -F: '{if ($3==1) print $2;}' data/$currentDB/meta-data/$currentTB.md `
       primary=`awk -F: '{if ($3==1) print $3;}' data/$currentDB/meta-data/$currentTB.md` 
         
        echo "The PK is with the $primaryKeyFieledName"
        echo "Enter the $primaryKeyFieledName"
        found=""
        read pkValue
        found+=$(awk -v fieledNum=$primaryKeyFieledNum -v pkValue=$pkValue 'BEGIN {flag=0 ; FS= ":"}; {if($fieledNum == pkValue) flag=1} END {print flag}' data/$currentDB/tables/$currentTB)
        if [ $found == "1" ]
        then 
        rowNumToBeEdited=$(awk -F: -v fieledNum=$primaryKeyFieledNum -v pkValue=$pkValue '{if($fieledNum == pkValue) print NR;}' data/$currentDB/tables/$currentTB)
            for (( i=0; i<${#arrayMeta[@]}; i++ ))
            do 
                temp=$(echo ${arrayMeta[$i]} | cut -f1 -d :)
                echo $(($i+1)) ")" $temp
            done
            echo "Enter the column you want to modify, please!"
            read modify;
            if [[ $modify =~ [1-9]+ && $modify -gt 0 && $modify -le ${#arrayMeta[@]} ]]
            then 
                echo "Enter the new " $(echo ${arrayMeta[$(($modify-1))]} | cut -f1 -d :)
                read newCellValue
                isRepeated="0"
                if [ $modify == $primaryKeyFieledNum ]
                then 
                    isRepeated=$(awk -v fieledNum=$primaryKeyFieledNum -v newCellValue=$newCellValue 'BEGIN {flag=0 ; FS= ":"}; {if($fieledNum == newCellValue) flag=1} END {print flag}' data/$currentDB/tables/$currentTB)
                fi
                if [ $isRepeated -eq "0" ]
                then  
                    dataType=$(awk -F: -v colNum=$modify '{if (NR==colNum) print $2;}' data/$currentDB/meta-data/$currentTB.md)
                    echo "Data type: ${dataType}"
                    if [ ${dataType} == "Numbers" ]
                    then 
                        case $newCellValue in 
                        +([0-9]))
                            awk -v rowNumber="$rowNumToBeEdited" -v colNumber="$modify" -v newData="$newCellValue" -F: 'BEGIN{OFS = ":"}{if(NR == rowNumber){$colNumber = newData};print $0;}' data/$currentDB/tables/$currentTB >> data/$currentDB/tables/tempTable;
                            mv data/$currentDB/tables/tempTable data/$currentDB/tables/$currentTB
                            ;;
                        *)
                            echo "The id should be integer"
                            ;;
                        esac
                    elif [ ${dataType} == "string" ]
                    then 
                        case $newCellValue in 
                            +([a-zA-Z]))
                                awk -v rowNumber="$rowNumToBeEdited" -v colNumber="$modify" -v newData="$newCellValue" -F: 'BEGIN{OFS = ":"}{if(NR == rowNumber){$colNumber = newData};print $0;}' data/$currentDB/tables/$currentTB >> data/$currentDB/tables/tempTable;
                                mv data/$currentDB/tables/tempTable data/$currentDB/tables/$currentTB
                                ;;
                            *)
                                echo "The id should be String"
                                ;;
                            esac
                    else 
                        awk -v rowNumber="$rowNumToBeEdited" -v colNumber="$modify" -v newData="$newCellValue" -F: 'BEGIN{OFS = ":"}{if(NR == rowNumber){$colNumber = newData};print $0;}' data/$currentDB/tables/$currentTB >> data/$currentDB/tables/tempTable;
                        mv data/$currentDB/tables/tempTable data/$currentDB/tables/$currentTB
                    fi
                else
                    echo "Invalid selection"
                fi

            else
                echo "You entered a repeated PK"
            fi
        fi
        break
    done
}

Update-Table