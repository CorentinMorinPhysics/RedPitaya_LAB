#!/bin/bash
source ./sub_test/common_func.sh

########## VARIABLES
LOCAL_SERVER_IP='192.168.1.1'
EXP_LINK_SPEED='1000'
EXP_DUPLEX='full'
N_PING_PKG=5
PKT_SIZE=16000
PING_IP=$LOCAL_SERVER_IP
MIN_QR_LENGTH=50             # Set to 50 when using QR scanner
RP_MAC_BEGINNING='00:26:32'
##########

echo
echo -e "\e[94m########################################################################\e[0m"
echo -e "\e[94m#            Ethernet network test                                     #\e[0m"
echo -e "\e[94m########################################################################\e[0m"

STATUS=0

# Verify that eth configuration MAC matches the EEPROM MAC
echo "Verify MAC address consistence with EEPROM..."
EEPROM_MAC=$($C_PRINTENV | grep ethaddr= | awk 'BEGIN {FS="="}{print $2}' | tr '[:lower:]' '[:upper:]') > /dev/null 2>&1
LINUX_MAC=$(cat '/sys/class/net/eth0/address' | tr '[:lower:]' '[:upper:]')

#Added, check if teh variable is empty > unsucsefull read will return empty variable. in this case set variable to "x".
if [ -z "$EEPROM_MAC" ]
then
    EEPROM_MAC="x"
    echo -n "Unsuccessful readout of EEPROM_MAC "
    print_fail
else 
    print_test_ok
fi

#Added for new OS
echo "EEPROM_MAC $EEPROM_MAC"
echo "LINUX_MAC $LINUX_MAC"
echo " "

if [[ "$EEPROM_MAC" != "$LINUX_MAC" ]]
then
    echo -n "    MAC address is not applied correctly to the network configuration"
    print_fail
    STATUS=-1
fi

# Check the link speed
echo 
echo "Verify link speed and ping to host $PING_IP..."

LINK_SPEED=$(cat /sys/class/net/eth0/speed 2> /dev/null)
DUPLEX=$(cat /sys/class/net/eth0/duplex 2> /dev/null)

if [[ "$LINK_SPEED" != "$EXP_LINK_SPEED" ]] || [[ "$DUPLEX" != "$EXP_DUPLEX" ]]
then
    echo "    Network link speed or duplex are unexpected."
    echo "    Link speed is \"$LINK_SPEED\" (\"$EXP_LINK_SPEED\" expected)."
    echo "    Duplex is \"$DUPLEX\" (\"$EXP_DUPLEX\" expected)."
    print_test_fail
    echo " "
    STATUS=-1
fi

# Ping the defined IP
echo "Ping to unit $PING_IP"
RES=$(ping "$PING_IP" -c "$N_PING_PKG" -s "$PKT_SIZE" | grep 'transmitted' | awk '{print $4}' ) > /dev/null

if [[ "$RES" != "$N_PING_PKG" ]]
then
    print_test_fail
    STATUS=-1
else
    print_test_ok
fi

if [[ $STATUS == 0 ]]
then
    $C_UART_TOOL 'LED:GRN 0 5' -s
fi

sleep 1

exit $STATUS
