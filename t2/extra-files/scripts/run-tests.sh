#!/bin/bash

# Bash script to run client's tests x11, variating number of requests and client version
# Author: Marcelo Costalonga

# Parameters:
#   $1 - Version (1 or 2)
#         1 = close and reconnect at each request
#         2 = maintaining connection open
#   $2 - Number of clients (must be 1, 5 or 50)
#   $3 - port 1
#   $4 - port 2
#   $5 - path to interface file


# Run test, save results and wait 1.5 seconds to run test again (to dont mess up results)
# Note: `tee -a` to apend results in same file
# for i in {1..2}; do lua client.lua $3 $4 $5 | tee -a temp_results.txt; sleep 1.5; done
# for i in {1..5}; do bash bash-clients$2.sh $3 $4 $5 | tee -a temp_results.txt; sleep 5; done
# bash bash-clients$2.sh $3 $4 $5 | tee -a temp_results.txt

if (( $2 == 1 )); then
   # for i in {1..5}; do bash bash-clients$2.sh $3 $4 $5 | tee -a temp_results.txt; sleep 2; done
   bash bash-clients$2.sh $3 $4 $5 | tee -a temp_results.txt
fi

if (( $2 == 5 )); then
   # for i in {1..5}; do bash bash-clients$2.sh $3 $4 $5 | tee -a temp_results.txt; sleep 5; done
   bash bash-clients$2.sh $3 $4 $5 | tee -a temp_results.txt
fi

if (( $2 == 50 )); then
   # for i in {1..5}; do bash bash-clients$2.sh $3 $4 $5 | tee -a temp_results.txt; sleep 5; done
   bash bash-clients$2.sh $3 $4 $5 | tee -a temp_results.txt
fi

# Grep to filter only the lines with "Total time: " and whats after it save it in another file
cat temp_results.txt | grep -o 'Total time:.*' > "test-V$1-N$2-time-results.txt"

# Asceding sort using time
sort "test-V$1-N$2-time-results.txt" -o "test-V$1-N$2-time-results.txt"

# Get median
# Note: `sed -n 'Np' < temp.txt` to get the Nth line of file
#printf "\n\t" && echo $(cat "test-V$1-N$2-time-results.txt" | grep -o -P 'Area somada .* (?=\|)' | head -1)
printf "\n\tNumber of lines in file: %s (number of times test was repeated)\n" "$(wc -l test-V$1-N$2-time-results.txt)"
#printf "\n\tMediana: " && echo $(sed -n '3p' < "test-V$1-N$2-time-results.txt")s && printf "\n"

# mv "test-V$1-N$2-time-results.txt" ./"v$1/test-V$1-N$2-time-results.txt"
# delete temp files
rm temp_results.txt
