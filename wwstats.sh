#!/bin/bash

# CREDIT TO WEBWORKER01

#Seconds in display loop, change to false if you don't want it to loop
sleepytime=600

#How many transactions back to scan for notarizations
txscanamount=10000

# Ignore these coins -> see file coinlist.ignore
source /home/$USER/nntools/coinlist.ignore

#Don't change below unless you know
IFS=
source /home/$USER/nntools/coinlist.nr
utxoamt=0.00010000
ntrzdamt=-0.00083600
btcntrzaddr=1P3rU1Nk1pmc2BiWC8dEy9bZa1ZbMp5jfg
kmdntrzaddr=RXL3YXG2ceaB6C5hfJcN4fvmLH2C34knhA

format="%-8s %7s %6s %7s %12s %8s %7s %7s\n"



timeSince()
{
    local currentimestamp=$(date +%s)
    local timecompare=$1

    if [ ! -z $timecompare ] && [[ $timecompare != "null" ]]
    then
        local t=$((currentimestamp-timecompare))

        local d=$((t/60/60/24))
        local h=$((t/60/60%24))
        local m=$((t/60%60))
        local s=$((t%60))

        if [[ $d > 0 ]]; then
            echo -n "${d}d"
        fi
        if [[ $h > 0 ]]; then
            echo -n "${h}h"
        fi
        if [[ $d = 0 && $m > 0 ]]; then
            echo -n "${m}m"
        fi
        if [[ $d = 0 && $h = 0 && $m = 0 ]]; then
            echo -n "${s}s"
        fi

    fi
}

outputstats ()
{
    count=0
    now=$(date +"%Y-%m-%d %T%z")

    printf "\n\n"
    printf "$format" "-ASSET-" "-NTRZd-" "-UTXO-" "-BLOX-" "-BALANCE-" "-LAST-" "-CNCT-";

    btctxinfo=$(bitcoin-cli listtransactions "" $txscanamount)
    btclastntrztime=$(echo $btctxinfo | jq -r --arg address "$btcntrzaddr" '[.[] | select(.address==$address)] | sort_by(.time) | last | "\(.time)"')
    printf "$format" "BTC" \
            "$(echo $btctxinfo | grep $btcntrzaddr | wc -l)" \
            "$(bitcoin-cli listunspent | grep $utxoamt | wc -l)" \
            "$(bitcoin-cli getblockchaininfo | awk ' /\"blocks\"/ {printf $2}' | sed 's/,//')" \
            "$(bitcoin-cli getbalance)" \
            "$(timeSince $btclastntrztime)" \
            "$(bitcoin-cli getnetworkinfo | awk ' /\"connections\"/ {printf $2}' | sed 's/,//')"

    kmdinfo=$(komodo-cli getinfo)
    kmdmininginfo=$(komodo-cli getmininginfo)
    kmdtxinfo=$(komodo-cli listtransactions "" $txscanamount)
    kmdlastntrztime=$(echo $kmdtxinfo | jq -r --arg address "$kmdntrzaddr" '[.[] | select(.address==$address)] | sort_by(.time) | last | "\(.time)"')
    printf "$format" "KMD" \
            "$(echo $kmdtxinfo | grep $kmdntrzaddr | wc -l)" \
            "$(komodo-cli listunspent | grep $utxoamt | wc -l)" \
            "$(echo $kmdinfo | awk ' /\"blocks\"/ {printf $2}' | sed 's/,//')" \
            "$(echo $kmdinfo | awk ' /\"balance\"/ {printf $2}' | sed 's/,//')" \
            "$(timeSince $kmdlastntrztime)" \
            "$(echo $kmdinfo | awk ' /\"connections\"/ {printf $2}' | sed 's/,//')" \
            "$(echo $kmdtxinfo | grep '\"generated\": true,' | wc -l) mined"

    chipsinfo=$(chips-cli getinfo)
    chipstxinfo=$(chips-cli listtransactions "" $txscanamount)
    chipslastntrztime=$(echo $chipstxinfo | jq -r --arg address "$kmdntrzaddr" '[.[] | select(.address==$address)] | sort_by(.time) | last | "\(.time)"')
    printf "$format" "CHIPS" \
            "$(echo $chipstxinfo | grep $kmdntrzaddr | wc -l)" \
            "$(chips-cli listunspent | grep $utxoamt | wc -l)" \
            "$(echo $chipsinfo | awk ' /\"blocks\"/ {printf $2}' | sed 's/,//')" \
            "$(echo $chipsinfo | awk ' /\"balance\"/ {printf $2}' | sed 's/,//')" \
            "$(timeSince $chipslastntrztime)" \
            "$(echo $chipsinfo | awk ' /\"connections\"/ {printf $2}' | sed 's/,//')"

    while [[ $count -le ${#coinlist[@]} ]]
    do
        all=${coinlist[count]}
        name=${all%% *}
        #if [ "$name" != "" ]
        #ignoreacs=('VOTE2018' 'PRLPAY')
        #ignoreacs=('VOTE2018')
        if [ "$name" != "" ] && [[ ! ${ignoreacs[*]} =~ $name ]]
        then
            info=$(komodo-cli -ac_name=$name getinfo)
            mininginfo=$(komodo-cli -ac_name=$name getmininginfo)
            txinfo=$(komodo-cli -ac_name=$name listtransactions "" $txscanamount)
            lastntrztime=$(echo $txinfo | jq -r --arg address "$kmdntrzaddr" '[.[] | select(.address==$address)] | sort_by(.time) | last | "\(.time)"')
            printf "$format" "$name" \
                    "$(echo $txinfo | grep $kmdntrzaddr | wc -l)" \
                    "$(komodo-cli -ac_name=$name listunspent | grep $utxoamt | wc -l)" \
                    "$(echo $info | awk ' /\"blocks\"/ {printf $2}' | sed 's/,//')" \
                    "$(echo $info | awk ' /\"balance\"/ {printf $2}' | sed 's/,//')" \
                    "$(timeSince $lastntrztime)" \
                    "$(echo $info | awk ' /\"connections\"/ {printf $2}' | sed 's/,//')"
        fi
        count=$(( $count +1 ))
    done
    printf "$now";
}

if [ "$sleepytime" != "false" ]
then
    while true
    do
        outputstats
        sleep $sleepytime
    done
else
    outputstats
    echo
fi
