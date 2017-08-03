#!/bin/bash

con=400
th=200
dur=300s
url='http://127.0.0.1:8081'
#url='http://sh2.tarantool.org'

echo '[+] add users'
wrk -c $con -t $th --latency --duration $dur --script t/wrk_add_user.lua $url
echo '------'

echo '[+] add operations'
wrk -c $con -t $th --latency --duration $dur --script t/wrk_add_operation.lua \
  $url
echo '------'

echo '[+] get balance'
wrk -c $con -t $th --latency --duration $dur --script t/wrk_get_balance.lua \
  $url
echo '------'

echo '[+] list N'
wrk -c $con -t $th --latency --duration $dur --script t/wrk_list_n.lua \
  $url
echo '------'

echo '[+] list period'
wrk -c $con -t $th --latency --duration $dur --script t/wrk_list_period.lua \
  $url
echo '------'
