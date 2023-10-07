#!/bin/bash

input_file=$1
output_file="output.json"

if [ ! -f "$input_file" ]; then
  echo "Please specify the input file"
  exit 1
fi

while read line || [ -n "$line" ]; do
    accumulated_lines+="$line"
done < $input_file

main_title=$(echo "$accumulated_lines" | awk -F'[][]' '{print $2}')
trimmed_main_title=$(echo "$main_title" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

success_percentage=$(echo "$accumulated_lines" | grep -oE '[0-9]+\.[0-9]+%')
success_percentage="${success_percentage%"%"}"

total_miliseconds=$(echo "$accumulated_lines" | awk '{print $NF}')

# Indicates if we are into the dotted lines
inside_separator=false
final_data='{"testName": "'${trimmed_main_title}'","tests": ['
counter_ok=0
counter_not_ok=0

while IFS= read -r line; do
  if [[ "$line" =~ ^-+$ ]]; then
    if [ "$inside_separator" = true ]; then
      # Removing unnecesary final semicolon
      final_data=${final_data::-1}
    else
      inside_separator=true
    fi
  
  elif [ "$inside_separator" = true ]; then
    # Removing final part (--ms) of the line
    test_name_without_ms=$(echo "$line" | sed 's/^ok [0-9]*  //; s/, [0-9]*ms$//')
    # Removing 'ok' or 'not ok' part
    test_name=$(echo "$test_name_without_ms" | sed 's/.*expecting/expecting/')

    test_duration=$(echo "$line" | awk '{print $NF}')
    
    # Validate status true or false
    test_status=$(echo "$line" | sed -n 's/\(not \)\?ok .*/\1ok/p')
    if [[ $test_status = "not ok" ]]; then
        test_status=false
        (( counter_not_ok += 1 ))
    else
        test_status=true
        (( counter_ok += 1 ))
    fi
    
    final_data+='{"name":"'${test_name}'", "status":'${test_status}', "duration":"'${test_duration}'"},'
  fi
done < "$input_file"

final_data=$final_data'], "summary": { "success": '${counter_ok}', "failed": '${counter_not_ok}', "rating": '${success_percentage}', "duration": "'${total_miliseconds}'" }}'

echo "$final_data" | ./jq '.' > $output_file

echo "Processing complete. Output written to '$output_file'."
