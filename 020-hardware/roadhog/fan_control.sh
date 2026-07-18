#!/usr/bin/env bash
set -euo pipefail

# Run in alpine container
# docker run -ti --rm -v $(pwd):/app -w /app --entrypoint=/bin/sh node:alpine

apk add ipmitool --no-cache

# IPMI IP address
: "${IPMIHOST:=192.168.1.1}"
# IPMI Username
: "${IPMIUSER:=XXXX}"
# IPMI Password
: "${IPMIPW:=XXXXXX}"
# Your IPMI Encryption Key
: "${IPMIEK:=0000000000000000000000000000000000000000}"

# Maximum ambient temperature in Celsius
MAXTEMP_AMBIENT=31
# Maximum processor temperature in Celsius
MAXTEMP_PROC=70

# Get the inlet temperature
INLET_TEMP=$(ipmitool -I lanplus -H ${IPMIHOST} -U ${IPMIUSER} -P ${IPMIPW} -y ${IPMIEK} sdr type temperature | grep "Inlet Temp" | grep degrees | grep -Eo '[0-9]{2}' | tail -1)

# Get the processor temperatures
PROC_TEMP1=$(ipmitool -I lanplus -H ${IPMIHOST} -U ${IPMIUSER} -P ${IPMIPW} -y ${IPMIEK} sdr type temperature | grep "0Eh" | grep degrees | grep -Eo '[0-9]{2}' | tail -1)
PROC_TEMP2=$(ipmitool -I lanplus -H ${IPMIHOST} -U ${IPMIUSER} -P ${IPMIPW} -y ${IPMIEK} sdr type temperature | grep "0Fh" | grep degrees | grep -Eo '[0-9]{2}' | tail -1)

# Determine fan speed based on ambient temperature
if [[ $INLET_TEMP -ge 0 && $INLET_TEMP -le 14 ]]; then
    FANSPEED=20
elif [[ $INLET_TEMP -ge 15 && $INLET_TEMP -le 19 ]]; then
    FANSPEED=40
elif [[ $INLET_TEMP -ge 20 && $INLET_TEMP -le 26 ]]; then
    FANSPEED=60
elif [[ $INLET_TEMP -ge 27 && $INLET_TEMP -le 30 ]]; then
    FANSPEED=80
fi

# Convert fan speed to hex
SPEEDHEX=$( printf "%x" $FANSPEED )

# Check if any processor temperature exceeds or equals the maximum temperature
if [[ $PROC_TEMP1 -ge $MAXTEMP_PROC || $PROC_TEMP2 -ge $MAXTEMP_PROC ]];
  then
    printf "Warning: Processor temperature is too high! Activating dynamic fan control! (Proc1: $PROC_TEMP1 C, Proc2: $PROC_TEMP2 C)" #| systemd-cat -t R730XD-IPMI-TEMP
    echo "Warning: Processor temperature is too high! Activating dynamic fan control! (Proc1: $PROC_TEMP1 C, Proc2: $PROC_TEMP2 C)"
    # This sets the fans to auto mode, so the motherboard will set it to a speed that it will need to cool the server down
    ipmitool -I lanplus -H ${IPMIHOST} -U ${IPMIUSER} -P ${IPMIPW} -y ${IPMIEK} raw 0x30 0x30 0x01 0x01
elif [[ $INLET_TEMP -ge $MAXTEMP_AMBIENT ]];
  then
    printf "Warning: Ambient temperature is too high! Activating dynamic fan control! (Inlet: $INLET_TEMP C)" #| systemd-cat -t R730XD-IPMI-TEMP
    echo "Warning: Ambient temperature is too high! Activating dynamic fan control! (Inlet: $INLET_TEMP C)"
    # This sets the fans to auto mode, so the motherboard will set it to a speed that it will need to cool the server down
    ipmitool -I lanplus -H ${IPMIHOST} -U ${IPMIUSER} -P ${IPMIPW} -y ${IPMIEK} raw 0x30 0x30 0x01 0x01
else
    printf "Temperature is OK (Inlet: $INLET_TEMP C, Proc1: $PROC_TEMP1 C, Proc2: $PROC_TEMP2 C)" #| systemd-cat -t R730XD-IPMI-TEMP
    echo "Activating manual fan speeds! ($FANSPEED%)"
    # This sets the fans to manual mode
    ipmitool -I lanplus -H ${IPMIHOST} -U ${IPMIUSER} -P ${IPMIPW} -y ${IPMIEK} raw 0x30 0x30 0x01 0x00
    # This is where we set the slower, quiet speed
    ipmitool -I lanplus -H ${IPMIHOST} -U ${IPMIUSER} -P ${IPMIPW} -y ${IPMIEK} raw 0x30 0x30 0x02 0xff 0x$SPEEDHEX
fi