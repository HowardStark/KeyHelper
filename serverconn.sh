#!/bin/bash

ADDRESS=""
PORT="22"
USER=""
KEYNAME=""
KEYPASS=""
EMAIL=""

#if [ ! -f "$HOME/.serverconn" ]; then
    echo "Welcome! This tool will help you generate the credentials"
    echo "to connect to a server. Once you've finished, the server's"
    echo "administrator will perform the final steps to give you access."
    echo "-----"
    echo "When you see \"[default ...]\" value, you can hit ENTER without"
    echo "typing anything to use it."
    echo "-----"
    # echo -n "Show this message again? (yes/NO) [default yes]: "
#fi
while [ "$ADDRESS" = "" ]; do
    echo -n "Enter the server name: "
    read ADDRESS
done

# Setup read variable for port
temp_port=""
echo -n "Enter the port [default $PORT]: "
read temp_port

if [ "$temp_port" != "" ]; then
    PORT=$temp_port
fi

temp_user=""
while [ "$USER" = "" ]; do
    if [ "$USER" != "" ]; then
        echo -n "Enter the username [default $USER]: "
        read temp_user
        break
    else
        echo -n "Enter the username: "
        read USER
    fi
done

temp_keyname=""
echo -n "Enter a keyname [default \"$USER-$ADDRESS\"]: "
read temp_keyname

if [ "$temp_keyname" != "" ]; then
    KEYNAME=$temp_keyname
else
    KEYNAME="$USER-$ADDRESS"
fi

# Confirm the above settings:
has_confirmed=false
increment=1
address_num=$increment
((increment++))
port_num=-1
if [ "$PORT" != "22" ]; then
    port_num=$increment
    ((increment++))
fi
user_num=$increment
((increment++))
keyname_num=$increment
((increment++))
confirm_num=9
cancel_num=0
while [[ "    $has_confirmed" != true ]]; do
    echo "Confirm: "
    echo "    $address_num) Edit Server Name: $ADDRESS"
    if [ "$port_num" != "-1" ]; then
        echo "    $port_num) Port: $PORT"
    fi
    echo "    $user_num) Edit Username: $USER"
    echo "    $keyname_num) Edit Keyname: $KEYNAME"
    echo "    9) Confirm"
    echo "    0) Cancel"
    echo -n "Select an option [default 9]: "
    read selected
    case "$selected" in
        $address_num)
            temp_address=""
            echo -n "Edit the server name [default $ADDRESS]: "
            read temp_address
            if [ "$temp_address" != "" ]; then
                ADDRESS=$temp_address
                KEYNAME="$USER-$ADDRESS"
                continue
            else
                continue
            fi
            ;;
        $port_num)
            if [ "$port_num" = "-1" ]; then
                echo "Invalid option \"$selected\"."
                continue
            else
                temp_port=""
                echo -n "Edit the port [default $PORT]: "
                read temp_port
                if [ $temp_port != "" ]; then
                    PORT=temp_port
                    continue
                else
                    continue
                fi
            fi
            ;;
        $user_num)
            temp_user=""
            echo -n "Edit the username [default $USER]: "
            read temp_user
            if [ $temp_user != "" ]; then
                USER=$temp_user
                KEYNAME="$USER-$ADDRESS"
                continue
            else
                continue
            fi
            ;;
        $keyname_num)
            temp_keyname=""
            echo -n "Edit the keyname [default \"$KEYNAME\"]: "
            read temp_keyname
            if [ $temp_keyname != "" ]; then
                KEYNAME=$temp_keyname
                continue
            else
                continue
            fi
            ;;
        $cancel_num)
            cancel_conf=false
            while [ "$cancel_conf" != true ]; do
                cancel_input=""
                echo -n "Are you sure you wish to discard your progress? [YES/no]: "
                read cancel_input
                if [ "$cancel_input" = "YES" ]; then
                    cancel_conf=true
                    exit 1
                elif [ "$cancel_input" = "no" ]; then
                    cancel_conf=true
                    break
                else
                    echo "Invalid option \"$cancel_input\"."
                    continue
                fi
            done
            ;;
        "")
            ;&
        $confirm_num)
            confirm_conf=false
            while [ "$confirm_conf" != true ]; do
                confirm_input=""
                echo -n "Are you sure the details are correct? [YES/no]: "
                read confirm_input
                if [ "$confirm_input" = "YES" ]; then
                    confirm_conf=true
                    has_confirmed=true
                    break
                elif [ "$confirm_input" = "no" ]; then
                    confirm_conf=true
                    break
                else
                    echo "Invalid option \"$confirm_input\"."
                    continue
                fi
            done
            if [ "$confirm_conf" = true ]; then
                break
            else
                continue
            fi
            ;;
        *)
            echo "Invalid option \"$selected\"."
            ;;
    esac
done
echo "-----"
echo "Generating keyfile..."
if [ ! -d "$HOME/.ssh/serverconn" ]; then
    mkdir -p "$HOME/.ssh/serverconn"
fi
ssh-keygen -t rsa -b 4096 -N "$KEYPASS" -f "$HOME/.ssh/serverconn/$KEYNAME.key" -C "Public key for `whoami`@`hostname`" -q
if [ $? != "0" ]; then
    echo "Uh-oh. There was an error generating your keyfile. Please try again"
    exit 1
fi
echo "Keyfile generated! Adding ssh entry..."
cat <<EOT >> "$HOME/.ssh/config"
Host $ADDRESS
    HostName $ADDRESS
    Port $PORT
    User $USER
    IdentityFile ~/.ssh/serverconn/$KEYNAME.key
EOT
echo "All done!"
echo "-----"
command_conf=false
while [ "$command_conf" != true ]; do
    command_input=""
    echo "To connect to your new ssh host, use the command: ssh $ADDRESS"
    echo -n "Confirm (enter the command): "
    read command_input
    if [ "$command_input" = "ssh $ADDRESS" ]; then
        echo "Great! You're all set!"
        break
    else
        echo "Invalid option \"$command_input\"."
        continue
    fi
done

if [[ -z "$EMAIL" ]]; then
    mail -s "`whoami`: New public key for $USER@$ADDRESS" "$EMAIL" -a "$HOME/.ssh/serverconn/$KEYNAME.key.pub"
fi
