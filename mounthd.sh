#!/usr/bin/env sh

#set -ex

# Retries a command on failure.
# $1 - the max number of attempts
# $2... - the command to run

retrycmd() {
    local -r -i max_attempts="$1"; shift
    local -i attempt_num=1
    until "$@"
    do
        if ((attempt_num==max_attempts))
        then
            echo "Attempt $attempt_num failed and there are no more attempts left!"
            return 1
        else
            echo "Attempt $attempt_num failed! Trying again in $attempt_num seconds..."
            sleep $((attempt_num++))
        fi
    done
}

unmountvol() {
    local -r volname="$1"
    local -r fulldevname="/dev/${volname}"
    mounted=$(diskutil info $fulldevname | sed -n '/Mounted/s/.*\: *//p')
    if [ "$mounted" = 'Yes' ]
    then
        retrycmd 5 diskutil unmount $fulldevname && diskutil eject $fulldevname
    else
        return 0
    fi
}

mountvol() {
    local -r volname="$1"
    local -r fulldevname="/dev/${volname}"
    mounted=$(diskutil info $fulldevname | sed -n '/Mounted/s/.*\: *//p')
    if [ "$mounted" = 'Yes' ]
    then
        return 0
    else
        voluuid=$(diskutil info $fulldevname | sed -n '/Volume UUID/s/.*\: *//p')
        mounter apfs $voluuid
    fi
}

main() {
    local -r mode="$1"
    local -r diskname="$2"
    local -r volnames=$(diskutil list external | sed -n "/${diskname}s[1-9]/s/.*B *//p")

    if [ "$volnames" ]
    then
        echo "$volnames" | while read line ; do
            if [ x"$mode" = x'mount' ]
            then
                mountvol $line
            else
                unmountvol $line
            fi
        done
    else
        echo "No external disks to act on"
    fi
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        mount|eject) mode="$1" ;;
        *) diskname="$1" ;;
    esac
    shift
done

main $mode $diskname
