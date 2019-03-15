#!/bin/bash
#
#
#VARIABLE
rm /tmp/echanges/fax.sh
rm /tmp/echanges/flag.flag
cp /tmp/echanges/fax.sh2 /tmp/echanges/fax.sh

IFS='%%' #Permet de mettre à la ligne
#readonly permet de ne pas modifier les variables
readonly PATH_SCP_FAX='/tmp/echanges/fax.sh'
#STATUS_TRANSFERT=$(bash $PATH_SCP_FAX | grep -Ec "^KO - Transfert module number")
#STATUS_ROUTEUR=$(bash $PATH_SCP_FAX | grep -Ec "^KO - Routeur module")
#STATUS_FLAG=$(bash $PATH_SCP_FAX | grep -Ec "^KO - :*")
CMD_STATUS_TEST="bash $PATH_SCP_FAX | grep \"test\""
#Redirige la sortie erreur vers la sortie std
STATUS_TEST=$(eval $CMD_STATUS_TEST)

#__________________________________________
#              FONCTION
#__________________________________________


function Check_KO () {
	STR_KO=$1
	CMD="bash $PATH_SCP_FAX | grep -Ec \"$STR_KO\" "
	eval $CMD
}

Check_KO "^KO - Transfert module number"

exit
function Transfert_module_error(){

	bash $1 | while read LINE ; do
        	if (echo $LINE | grep -qE '^KO - Transfert') ; then
                	module=$(echo "$LINE" | awk '{print $6}')
		        echo "Stop $module"
		        echo "Start $module"
		fi
	done
	return 0
}

function Transfert_restart_all () {
	echo "Stop tous les modules"
	echo "Start tous les modules"
	echo "echo \"test\" " > /tmp/echanges/fax.sh
	return 0
}

function Routeur () {
	echo -e "Stop routeur"
	echo -e "Start routeur"
	echo -e "/app/echanges/outils/bin/fax.sh status | grep -E Routeur"
	return 0
}

function Flag () {
	echo -e "Un flag a été rencontrée"
	echo -e "\n"
	return 0
}

function Alerte () {
	#Soit créé un fichier flag
	echo > /tmp/echanges/KO.flag
	#Soit envoyer un email
}


Check_KO "^KO - Transfert module number"
Check_KO "^KO - Routeur module"
Check_KO "^KO - :*"
Check_KO "test"

#Force l utilisation avec luser root (echanges dans le futur"
if (( $EUID != 0 ));
  then
	echo "Mauvais utilisateur ! Exécuter l'utilisateur echanges"
	exit
fi


#AIDE/VERSION
case "$1" in
        -h | --h | --help | --aide ) echo -e "Aide : \nLe script va voir le status du fax.sh" ; exit 0 ;;
        -v | --v | --version ) echo -e "Version 0.1 \nCréé par T.SOURISSEAU" ; exit 0 ;;
esac


if [ (Check_KO "^KO - Routeur module") -ne 0 ];
then
	Routeur
fi

if [ (Check_KO "^KO - Transfert module number") -gt 2 ];
then
	Transfert_restart_all
	#Verifier l'état du service, si KO générer alerte
#		if [ bash $PATH_SCP_FAX | grep "test" -gt 0 ];
		if [ $STATUS_TEST -gt 0 ];
		then
			Alerte
		fi
elif [ (Check_KO "^KO - Transfert module number") -gt 0 ];
then
	Transfert_module_error $PATH_SCP_FAX
	#Verifier l'état du service, si KO générer alerte
fi



exit 0
