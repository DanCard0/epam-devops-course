#!/bin/bash

input_file=$1
output_file="accounts_new.csv"

if [ ! -f "$input_file" ]; then
  echo "Please specify the input file"
  exit 1
fi

declare -a persons=()
declare -a duplicated_usernames=()

while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4 rec_column5 rec_column6 
do
  first_char=${rec_column3:0:1}
  first_char_lower=${first_char,,}
  last_name=${rec_column3#* }
  last_name_lower=${last_name,,}
  username="${first_char_lower}${last_name_lower}"
  
  if [[ ${persons[@]} =~ $username ]]
  then
    duplicated_usernames=(${username} "${duplicated_usernames[@]}")
  else
    persons=(${username} "${persons[@]}")
  fi
  
done < <(tail -n +2 $input_file)

capitalize_name () {
    name=$1
    name=( $name )
    rec_column3="${name[@]^}"
}

generate_email () {
    name=$1
    first_char=${name:0:1}
    first_char_lower=${first_char,,}
    last_name=${name#* }
    last_name_lower=${last_name,,}
    username="${first_char_lower}${last_name_lower}"

    if [[ ${duplicated_usernames[@]} =~ $username ]]
    then
        rec_column5="${first_char_lower}${last_name_lower}${rec_column2}@abc.com"
    else
        rec_column5="${first_char_lower}${last_name_lower}@abc.com"
    fi
}

echo "id,location_id,name,title,email,department" > $output_file

while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4 rec_column5 rec_column6 
do
  if [[ "$rec_column4" =~ .*\".* ]]
  then
    rec_column4="\"${rec_column4:1},${rec_column5::-1}\""
  # else
  #   echo "$rec_column4 No contiene comillas"
  fi

  capitalize_name "$rec_column3"
  generate_email "$rec_column3"
  echo "$rec_column1,$rec_column2,$rec_column3,$rec_column4,$rec_column5,$rec_column6" >> $output_file
done < <(tail -n +2 $input_file)

echo "Processing complete. Output written to '$output_file'."