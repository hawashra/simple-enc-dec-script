#!/bin/bash
red='\e[31m' # color code of red in echo command
green='\e[32m' # color code of green in echo command
reset='\e[0m' # code of default color in echo command

set -euo pipefail

encrypt() {

        # read the name of plain text file from user
        read -p "Please input the name of the plain text file: " plain

        # print error and exit if file doesn't exist
        [ ! -f "$plain" ] && echo -ne $red"\nFile \"$plain\" doesn't exist\n"$reset && return 1

        # check if the file contains non-alphabet charactes, and ask the user if he/she wants to continue anyways if so.

        #if [[ "`cat "$plain" | tr -d ' \n'`" =~ [^A-Za-z] ]]; then echo -ne $red"\nfile contains non-alphabet chars, continue? (y/n):\n"$reset
        #read -r ans; [ "$ans" == y ] || [ "$ans"  == Y ] ||  ;fi


        # get each alphabetic word in the file in a line and and convert to small letter and insert a '+' sign between each two                         characters in the word
        grep -Eo '\w+' "$plain" | tr A-Z a-z | grep -v "[^[:alpha:]]" | sed 's/./&+/g;s/+$//' | sed 's/+/ + /g' > "temp.txt"


        # array of all small alphabetic characters
        chars=("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z")

        i=1
        # convert a to 1 and b to 2 ... and z to 26.
        for char in "${chars[@]}"; do sed -i "s/${char}/${i}/g" "temp.txt" ; i=$((i+1)); done

        cat temp.txt > debug


        # calculate the sum of index for each word (mod 256) and get the max
        key=$(echo "`cat temp.txt | bc` % 256" | bc | sort -n| tail -1)

        echo "key in decimal is: $key"

        # convert key from decimal to binary
        key_binary=$(echo ";ibase=10;obase=2;$key" | bc)

        # loop to extend the binary key to 8 bits
        while [ ${#key_binary} -lt 8 ]; do

        key_binary=$(echo "0$key_binary")
        done


        echo "key in binary is: $key_binary"

        # read the cipher (encryption output) file name
        read -p "please enter cipher file name: " cipher
>"$cipher"

        sp="/-\|"
        echo -n 'encrypting file...'

        # each line contains 8 bit binary ascii for a character.
        for line in `cat "$plain" | xxd -b | cut -d' ' -f2-8 | tr ' ' '\12' | grep -v ^$`; do
                printf "\b${sp:i++%${#sp}:1}"

                # take the xor with the key and convert result to binary
                after_xor=$(echo ";obase=2;$((2#$line^2#$key_binary))" | bc)

                # extend the xor result to 8 bit
                while [ "${#after_xor}" -lt 8 ]; do after_xor=$(echo "0$after_xor"); done

                # swap last 4 bits with first 4 bits
                swapped="${after_xor#????}${after_xor%????}"
                # append the encoded 8 bits (character) to the file without adding a new line
                echo -n "$swapped" >> "$cipher"

                #decimal=$(echo ";obase=10;ibase=2;$swapped" | bc)

                #echo -n "`echo "$decimal" | awk '{printf("%c",$1)}'`" >> "$cipher"

        done
        # swap last 4 bits with first 4 bits of the key and append them to the output file
        echo -n "${key_binary#????}${key_binary%????}" >> "$cipher"
}




decrypt() {
>temp.txt

        # read the cipher text file name
        read -p "please enter the name of the cipher text file: " cipher

        # raise an error and exit if file doesn't exist
        [ ! -f "$cipher" ] && echo -ne $red"\nFile \"$cipher\" doesn't exist\n"$reset && return 1

        # get the last 8 characters in the cipher file (the key but last 4 bits swapped with first 4 bits)
        revKey=$(cat "$cipher" | grep -v ^$  | tail -1 | grep -o '........$')

        # swap last 4 bits with first 4 bits to get the key
        key_binary="${revKey#????}${revKey%????}"

        echo "the key is $key_binary"

        # delete last 4 bits (key swapped) as we
        sed 's/........$//' "$cipher" > "temp.txt"
        read -p "Please enter the name of plain text file: " plain

>"$plain"


        sp="/-\|"
        echo -n 'deryprting the file..'

        for line in `sed 's/......../&\n/g' "temp.txt"`; do

                #printf "\b${sp:i++%${#sp}:1}"


                bitsRev="$line"
                bits="${bitsRev#????}${bitsRev%????}"
                after_xor=$((2#$bits^2#$key_binary))



                if [ "$after_xor" -eq 10 ]; then echo>>"$plain"; else character=$(echo "$after_xor" | awk '{printf("%c",$1)}') && echo -n "$character" >> "$plain"; fi

        done

}

while true; do
        echo -ne $green"
        1. enctyption.
        2. decryption.
        0. Exit.
        "$reset

        echo -ne "\nchoice: "
        read choice
        case "$choice" in

                1) encrypt ;;
                2) decrypt ;;
                0) exit "$?" ;;
                *) echo invalid choice ;;

        esac
done
