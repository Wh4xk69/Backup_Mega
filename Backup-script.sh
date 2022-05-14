#!/usr/bin/bash

hoje=$(date +'%d-%m-%Y')
name="Backup_$hoje.tar.bz2"
path_1="/Root/Backup"
path_backup_old="${HOME}/.BACKUP"
path_cipher="${HOME}/.BACKUP/cipher"
path_encipher="$HOME/.BACKUP/encipher"


# Entre com a pasta dos seus codigos
path_backup="${HOME}"

# Entre com suas crediciais server MEGA
username=''
password=''

function Logo()
{
cat << EOF
#-----------------------------------------------------------------
# Data:		18-03-2022
# Script:	Backup mega
# Descricao:	Permite fazer de backup automatico para servidores Mega
# Criado por:   Wh4xk69
# IRC:          server:slackjeff.com.br nick:Wh4xk69
#-----------------------------------------------------------------
EOF
}

function check_path(){
	if [ -z $(megals $path_1 | head -n 1) ];then
		megamkdir $path_1
	fi
	if [ -d $path_cipher ];then
		echo "$(cor 32 0)A pasta $path_cipher ja existe!$(cor 0 1)"
	else
		mkdir $path_backup_old
		mkdir $path_cipher
	fi
	if [ -d $path_encipher ];then
		echo "$(cor 32 0)A pasta $path_encipher ja existe!$(cor 0 1)"
	else
		mkdir $path_encipher
	fi
	delete_arq_old
}

function cor(){
	[[ "$2" -eq 0 ]] && echo -e "\e[${1};1m" || echo -e "\e[m"
}

function msg(){
	case $1 in
		1) echo -e "$(cor 32 0)[1]----Processo de Backup iniciado...$(cor 0 1)";;
		2) echo -e "$(cor 32 0)[2]----Processo de Backup concluido...$(cor 0 1)";;
		3) echo -e "$(cor 32 0)[3]----Processo de Checksum concluido...$(cor 0 1)";;
		4) echo -e "$(cor 32 0)[4]----Processo de assinatura concluida...$(cor 0 1)";;
		5) echo -e "$(cor 32 0)[5]----Preparando arquivos pra ser encriptados...$(cor 0 1)";;
		6) echo -e "$(cor 32 0)[6]----Preparando para fazer upload...$(cor 0 1)";;
		6.1) echo -e "$(cor 31 0)[!] Ja existe o arquivo $(cor 33 0)$arq$(cor 31 0) no servidor!$(cor 0 1)";;
		7) echo -e "$(cor 32 0)[7]----Iniciando o processo de limpeza...$(cor 0 1)";;
		7.1) echo -e "$(cor 31 0)[X] $i - Arquivo $(cor 33 0)$(echo $shred | sed 's/.*er\///')$(cor 31 0) foram deletados [!]$(cor 0 1)";;
		7.2) echo -e "$(cor 31 0) [X] $i - Pasta $shred estar vazia [!]$(cor 0 1)";;
		8) echo -e "$(cor 32 0)[9]----TODOS PROCESSOS CONCLUIDOS COM SUCESSO!";;
	esac

}


function backup_mega(){
# Processo de compactacao
#-------------------------------------------
	msg 1
	tar -jcf  $path_backup/* 2>/dev/null | pv > $name
	mv $name $path_encipher/.
	msg 2

# Criando Checksum dos arquivos que foram compactados
#--------------------------------------------
	for n in $(find $path_backup/* -type f -print);do sha256sum $n 2>/dev/null>>$name.asc;done
	mv "$name.asc" $path_cipher/.
	msg 3

# Processo de uma assinatura gpg na lista checksum {Obs.: Caso tenha chave RSA}
#--------------------------------------------
#	gpg -b $path_cipher/*.asc
#	msg 4
#
# Processo de encriptacao simetricas
#--------------------------------------------
	msg 5
	gpg -c $path_encipher/$name 2>/dev/null
	mv "$path_encipher/$name.gpg" $path_cipher/.

# Processo de upload os arquivos .gpg .sig .asc
#--------------------------------------------
	msg 6
	for arq in $(ls $path_cipher/* | sed 's/.*er\///');do
		if megals $path_1 | grep '\.' | sed 's/.*er\///' | grep -q $arq
		then
			msg 6.1
		else
			megaput $path_cipher/$arq --path $path_1/
		fi
	done

# Processo de delete os arquivos das pastas encipher e cipher
#--------------------------------------------
	msg 7
	i=0
	for shred in $(find $path_backup_old/ -type f -print);do
		if [ -f $shred ];then
			i=$[$i+1]
			shred -uzn5 $shred
			msg 7.1
		else
			i=$[$i+1]
			msg 7.2
		fi
	done
	msg 8
}

# Essa funcao vai check no sistema possuem os
# programas Megatools e PV se estao instalados.

function check_app(){
	local which_megacopy=$(which megacopy) 
	local which_pv=$(which pv) 
	local which_gpg=$(which gpg) 
	if [ -x $which_megacopy ];then
		if [ -x $which_pv ];then
			if [ -x $which_gpg ];then
				check_path
			else
				sudo apt install -y gnupg
				check_app
			fi
		else
			sudo apt install -y pv
			check_app
		fi
	else
	       	sudo apt install -y megatools
		check_app
	fi
}

# Funcao vai apagar a partir de 2 backup mais antigos
# assim ficando somente os os dois mais recente.
# Verifique antes de fazer Backup, assim vai consisti
# somente dois backup antes de fazer o backup atual.

function delete_arq_old(){
	var1=$(megals $path_1 | sort | grep $(date +'%m') | wc -l)
	if [ $var1 -gt 6 ];then

		for del in $(megals $path_1 | sort |grep $(date +'%m') |  head -n -6)
		do
			megarm $del
			backup_mega
		done

	else
		backup_mega
	fi
}

# Verificacao de conta de usuario dos servidores mega
# e caso criando um arquivo megarc pra login rapido.

function megarc(){
	if [ -e "${HOME}/.megarc" ]; then
		check_app
	else
		if [ -z $username ];then
			printf "\e[32;1mDigite o nome de usuario:> \e[m"
                        read username
                        echo -e "[Login]\n\nUsername=$username" > ${HOME}/.megarc
		else
			echo -e "[Login]\n\nUsername=$username" > ${HOME}/.megarc
		fi
		if [ -z $password ]; then
			printf "\e[32;1mDigite a sua senha:> \e[m"
			read -s password
			echo -e "Password=$password" >> ${HOME}/.megarc
		else
			echo -e "Password=$password" >> ${HOME}/.megarc
		fi
		check_app
	fi
}

logo
megarc
