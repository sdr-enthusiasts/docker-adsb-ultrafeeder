#!/bin/bash

# shellcheck shell=bash disable=SC2015,SC2162
#
# Registration and query utility for aussieadsb,
# Meant for those who want to feed AussieADSB with Ultrafeeder
#
# AussieADSB is an Australian aggregator focused on feeders in Australia/Oceania.
# If you are in this region and are interested in feeding to them, please see:
# http://aussieadsb.com/
#
# You can run this script from any modern Debian Linux machine with this command:
# bash <(wget -qO - https://raw.githubusercontent.com/sdr-enthusiasts/docker-adsb-ultrafeeder/main/aussieadsb.sh)
#
#---------------------------------------------------------------------------------------------
# Copyright (C) 2024 Ramon F. Kolb (kx1t) and contributors
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.
#---------------------------------------------------------------------------------------------
#

AAClientVersion="1.1.0-ultrafeeder"
argv="${1,,}"
if [[ "${argv:0:1}" != "-" ]]; then argv="-$argv"; fi

while [[ "$argv" == "-" ]]; do
    echo "AussieADSB registration utility"
    echo "Visit http://aussieadsb.com for info"
    echo
    echo "Select an option:"
    echo "(r)egister      -- register a new receiver"
    echo "(d)e-register    -- deregister a receiver"
    echo "(u)pdateinfo    -- update your registration info"
    echo "(s)tatus        -- show the feeding status"
    read -n 1 argv
    echo
    argv="${argv,,}"
    case "$argv" in
        r) argv="-register" ;;
        d) argv="-deregister" ;;
        u) argv="-updateinfo" ;;
        s) argv="-status" ;;
        *) echo "invalid selection, try again" ;;
    esac
done

if [[ "$argv" == "-help" ]]; then
    echo "Usage: $0 <option> [key]"
    echo "Where <option> is one of the following:"
    echo "-register      -- register a new receiver"
    echo "-deregister    -- deregister a receiver"
    echo "-updateinfo    -- update your registration info"
    echo "-status        -- show the feeding status"
    echo "-help          -- show this help text"
    echo
    echo "The AussieADSB registration key is optional (and cannot be used  with the -register option)"
    echo "If you omit it, we'll ask you for it when doing -deregister, -updateinfo, or -status"
    echo "You can also pass in the key using the AUSSIEADSB_KEY environment variable"
    exit 0
fi

AUSSIEADSB_KEY="${AUSSIEADSB_KEY:-$2}"

if ! which jq >/dev/null 2>&1 || ! which netcat >/dev/null 2>&1 || ! which ifconfig >/dev/null 2>&1; then
    echo "For registration to work, we need to do a one-time installation of JQ, NetCat, and ifconfig to your system"
    echo "Please be patient..."

    if (( UID == 0 )); then
        apt-get update -qq
        apt-get install -o Dpkg::Options::="--force-confnew" -y --no-install-recommends -qq jq netcat-traditional net-tools
    else
        sudo apt-get update -qq
        sudo apt-get install -o Dpkg::Options::="--force-confnew" -y --no-install-recommends -qq jq netcat-traditional net-tools
    fi
    echo ""
    echo ""
fi

case "$argv" in
    "-register")
        if [[ -n "$AUSSIEADSB_KEY" ]]; then
            echo "Error - your station is already registered. Try \"$0 -status\""
            exit 1
        fi
        echo ""
        echo "AussieADSB Registration"
        echo ""
        echo "Which suburb is this receiver located in?"
        echo "This will be used by the admins to set the receiver name on the site"
        read suburb
        while ! [[ $postcode =~ ^[0-9][0-9]{3}$ ]]; do
            read -p "Please enter a valid 4-digit Australian postcode for the suburb: " postcode
        done
        read -p "Please enter your email address: " email
        read -p "Please enter your first and last name: " name

        echo ""
        echo "We will attempt to register your receiver with this information:"
        echo "Name:     $name"
        echo "Email:    $email"
        echo "Location: $suburb $postcode"
        read -n 1 -p "Is this correct? (Y/n) " yesno
        echo ""
        if [[ "${yesno,,}" == "n" ]]; then
            echo "Please run the command \"$0 $1\" again with the correct information!"
            exit 1
        fi
        echo ""
        echo "Registering receiver..."
        response="$(printf '{"ReceiverToken":null,"ClientVersion":"%s","MessageType":"register","Data":{"LocalSourcePort":30005,"OSDescription":"%s","MacAddress":"%s","Suburb":"%s","Email":"%s","Name":"%s"}}' \
            "$AAClientVersion" \
            "$(uname -s -r -v)" \
            "$(ifconfig -a | sed -n 's/^\s*ether \([0-9a-f:]\+\) .*$/\1/p' | head -1)" \
            "$suburb $postcode" \
            "$email" \
            "$name" \
            | nc aussieadsb.com 5000)"
        rcvr_token="$(jq -r .Data.ReceiverToken <<< "$response" 2>/dev/null)"
        rcvr_name="$(jq -r .Data.ReceiverName <<< "$response" 2>/dev/null)"
        port="$(jq -r .Data.Port <<< "$response" 2>/dev/null)"
        if [[ "$rcvr_token" == "null" ]] || [[ "$rcvr_name" == "null" ]] || [[ "$port" == "null" ]]; then
            echo "Something went wrong. The registration engine returned this:"
            jq -r . <<< "$response"
            echo ""
            echo "Try again later!"
            exit 1
        fi
        echo "Your receiver is registered! Please add the following to your Ultrafeeder environment parameters in docker-compose.yml:"
        echo 
        echo "In ULTRAFEEDER_CONFIG, please add these lines:"
        echo "   adsb,aussieadsb.com,$port,beast_reduce_plus_out;"
        echo "   mlat,aussieadsb.com,30000,name=$rcvr_token;"
        echo
        echo "Add the following parameter as well:"
        echo "- AUSSIEADSB_KEY='$rcvr_token'"
        echo
        echo "After adding these, please recreate your Ultrafeeder container to start feeding AussieADSB!"
        echo
        echo "Visit http://aussieadsb.com/status to check feeding status"
        echo "Currently, your receiver name is \"$rcvr_name\", but it will soon be renamed by the admins to your location."
        echo
        echo "Please keep your AUSSIEADSB_KEY value ($rcvr_token) and Port Number ($port) in a safe place - you will need it to reinstate your station if you ever update your system"
        echo
    ;;

    "-deregister")
        echo ""
        echo "AussieADSB De-registration"
        echo ""
        
        while [[ -z "$AUSSIEADSB_KEY" ]]; do
            read -rp "Please enter your AussieADSB Registration Key: " AUSSIEADSB_KEY
        done

        response="$(printf '{"ReceiverToken":"%s","ClientVersion":"%s","MessageType":"status","Data":null}' "$AUSSIEADSB_KEY" "$AAClientVersion" | nc aussieadsb.com 5000)"
        msg_type="$(jq -r .MessageType <<< "$response")"
        rcvr_name="$(jq -r .Data.Name <<< "$response")"

        if [[ "$msg_type" != "statusresponse" ]] || [[ "$rcvr_name" == "null" ]]; then
            echo "Cannot find a receiver with Registration Key \"$AUSSIEADSB_KEY\"!"
            echo "Please check the key and try again!"
            exit 1
        fi

        read -n 1 -p "Are you sure you want to deregister station \"$rcvr_name\"? (y/N) " yesno
        echo  ""
        if [[ "$yesno" != "y" ]]; then
            echo "Aborting de-registration!"
            exit 0
        fi

        echo "De-registering station $rcvr_name with key $AUSSIEADSB_KEY..."
        response="$(printf '{"ReceiverToken":"%s","ClientVersion":"%s","MessageType":"deregister","Data":"User"}' "$AUSSIEADSB_KEY" "$AAClientVersion" | nc aussieadsb.com 5000)"
        if [[ "$(jq -r .MessageType <<< "$response" 2>/dev/null)" == "deregisterresponse" ]]; then
            echo "De-registration complete!"
            exit 0
        else
            echo "Something went wrong. The registration engine returned this:"
            jq -r . <<< "$response"
            echo ""
            echo "Try again later!"
            exit 1
        fi
    ;;

    "-status")
        echo ""
        echo "AussieADSB Feeder Status"
        echo ""
        
        while [[ -z "$AUSSIEADSB_KEY" ]]; do
            read -rp "Please enter your AussieADSB Registration Key: " AUSSIEADSB_KEY
        done

        response="$(printf '{"ReceiverToken":"%s","ClientVersion":"%s","MessageType":"status","Data":null}' "$AUSSIEADSB_KEY" "$AAClientVersion" | nc aussieadsb.com 5000)"
        msg_type="$(jq -r .MessageType <<< "$response" 2>/dev/null)"
        rcvr_name="$(jq -r .Data.Name <<< "$response" 2>/dev/null)"
        connected="$(jq -r .Data.Connected <<< "$response" 2>/dev/null)"
        rcvr_ip="$(jq -r .Data.ConnectedIP <<< "$response" 2>/dev/null)"
        port="$(jq -r .Data.Port <<< "$response" 2>/dev/null)"
        
        if [[ "$msg_type" != "statusresponse" ]] || [[ "$rcvr_name" == "null" ]]; then
            echo "Cannot find a receiver with Registration Key \"$AUSSIEADSB_KEY\"!"
            echo "Please check the key and try again!"
            exit 1
        fi

        if [[ "$connected" == true ]]; then connected="connected"; else connected="not connected"; fi
        echo "Status for AUSSIEADSB_KEY \"$AUSSIEADSB_KEY\":"
        echo "Registered Receiver Name: $rcvr_name"
        echo "Connection status: $connected"
        echo "Public IP address: $rcvr_ip"
        echo "Server Port to send Beast data to: $port"
        echo ""
        echo "In ULTRAFEEDER_CONFIG, please add these lines:"
        echo "   adsb,aussieadsb.com,$port,beast_reduce_plus_out;"
        echo "   mlat,aussieadsb.com,30000,name=$AUSSIEADSB_KEY;"
        echo
        echo "Add the following parameter as well:"
        echo "- AUSSIEADSB_KEY='$AUSSIEADSB_KEY'"
        echo
        exit 0
    ;;

    "-updateinfo")
        echo ""
        echo "AussieADSB Registration Update"
        echo ""
        
        while [[ -z "$AUSSIEADSB_KEY" ]]; do
            read -rp "Please enter your AussieADSB Registration Key: " AUSSIEADSB_KEY
        done

        echo "Enter all information again. Your registration will be updated with the info you entered below."
        echo "Please do not leave any fields empty."
        echo ""

        echo "In which suburb is this receiver located?"
        echo "This will be used by the admins to set the receiver name on the site"
        read suburb
        while ! [[ $postcode =~ ^[0-9][0-9]{3}$ ]]; do
            read -p "Please enter a valid 4-digit Australian postcode for the suburb: " postcode
        done
        read -p "Please enter your email address: " email
        read -p "Please enter your first and last name: " name

        echo ""
        echo "We will attempt to register your receiver with this information:"
        echo "Name:     $name"
        echo "Email:    $email"
        echo "Location: $suburb $postcode"
        read -n 1 -p "Is this correct? (Y/n) " yesno
        echo ""
        if [[ "${yesno,,}" == "n" ]]; then
            echo "Please run the command \"$0 $1\" again with the correct information!"
            exit 1
        fi
        echo ""
        echo "Updating receiver..."
        response="$(printf '{"ReceiverToken":"%s","ClientVersion":"%s","MessageType":"update","Data":{"LocalSourcePort":30005,"OSDescription":"%s","MacAddress":"%s","Suburb":"%s","Email":"%s","Name":"%s"}}' \
            "$AUSSIEADSB_KEY" \
            "$AAClientVersion" \
            "$(uname -s -r -v)" \
            "$(ifconfig -a | sed -n 's/^\s*ether \([0-9a-f:]\+\) .*$/\1/p' | head -1)" \
            "$suburb $postcode" \
            "$email" \
            "$name" \
            | nc aussieadsb.com 5000)"
        status="$(jq -r .MessageType <<< "$response" 2>/dev/null)"
        if [[ "$status" != "updateresponse" ]]; then
            echo "Something went wrong. The registration engine returned this:"
            jq -r . <<< "$response"
            echo ""
            echo "Try again later!"
            exit 1
        fi
    ;;

    *)
        echo "Unknown option \"$1\". Please check and try again"
        exit 1
    ;;
    
esac
