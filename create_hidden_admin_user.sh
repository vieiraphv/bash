#!/bin/sh

#  1 - criar usuario
#  2 - gerar senha aleatoria
#  3 - habilitar encriptacao fv2
#  4 - ocutar usuario
#  5 - enviar senha pro JAMF (provavelmente como extension attribute)

#  6 - gerar senha aleatoria a cada login
#  7 - enviar nova senha pro JAMF

#========================================#
#            LOG FUNCTION             #
#========================================#
function logresult()	{
    if [ $? = "0" ] ; then
        echo "$1"
    else
        echo "$2"
        exit 1
    fi
}

#========================================#
#               VARIABLES                #
#========================================#
LOCAL_ADMIN_FULLNAME="User TEST"             # The local admin user's full name
LOCAL_ADMIN_SHORTNAME="user.test"            # The local admin user's shortname
LOCAL_ADMIN_PASSWORD="$randpassword"               # Local admin user's password
randpassword=$( /usr/bin/openssl rand -base64 12 ) # Generates random password
fpdirectory="/private/var/.fp"                     # Hidden Directory


#========================================#
#       CREATE LOCAL USER ACCOUNT        #  1 - 2
#========================================#
sysadminctl -addUser $LOCAL_ADMIN_SHORTNAME -fullName "$LOCAL_ADMIN_FULLNAME" -password "$LOCAL_ADMIN_PASSWORD"  -admin
logresult "User $LOCAL_ADMIN_SHORTNAME created!" "Failed creating user"


#========================================#
#           ENABLE USER TO FV2           # 3
#========================================# 
fdesetup enable -user LOCAL_ADMIN_SHORTNAME


#========================================#
#              HIDE ACCOUNT              # 4
#========================================#
dscl . -create /Users/$LOCAL_ADMIN_SHORTNAME IsHidden 1

#========================================#
#       CREATE HIDDEN DIRECTORY          # 4 
#========================================#
/bin/mkdir -p "$fpdirectory"
logresult "Creating \"$fpdirectory\" directory" "Failed creating \"$fpdirectory\" directory"


#========================================#
#     MOVE ADMIN HOME FOLDER TO /VAR     # 4
#========================================#
mv /Users/$LOCAL_ADMIN_SHORTNAME /var/$LOCAL_ADMIN_SHORTNAME 


#========================================#
#     CREATE NEW HOME DIR ATTIBUTE       # 4 
#========================================#
dscl . -create /Users/$LOCAL_ADMIN_SHORTNAME NFSHomeDirectory /var/$LOCAL_ADMIN_SHORTNAME


#========================================#
#    REMOVE PUBLIC FOLDER SHAREPOINT     # 4
#          FOR THE LOCAL ADMIN           #
#========================================#
dscl . -delete "/SharePoints/$LOCAL_ADMIN_FULLNAME's Public Folder" 


#========================================#
#   WRITE RANDOM PASSWORD TO TEMP FILE   # 5
#========================================#
/usr/bin/touch "$fpdirectory/$randpassword"
logresult "Writing password to file \"$fpdirectory/$randpassword\"" "Failed writing password to file \"$fpdirectory/$randpassword\""



# update Jamf Pro computer record with firmware password and set only if inventory was updated
/usr/local/bin/jamf recon && /usr/local/bin/jamf setOFP -mode command -password "$randpassword"



# Disable user or lock user account
chsh -s /usr/bin/false username
pwpolicy -u username disableuser
# enable user or unlock account
chsh -s /bin/bash username
pwpolicy -u username enableuser



# get volumes list
diskutil apfs list

# Unlock the disk
diskutil apfs unlockVolume /dev/apfs_volume_id_goes_here

#decrypt using password (pegar o UID do usuario enquanto logado no usuario de admin)
diskutil apfs decryptVolume /dev/apfs_volume_id_goes_here -user uuid_goes_here

#Press the Down arrow on the keyboard to highlight any user (make sure the password entry box is NOT open.)
#Press Option + Return on the keyboard.
#This should bring up the username and password fields on the login screen.
