#!/usr/bin/bash

hoje=$(date +'%d-%m-%Y')
name="Backup_$hoje.tar.bz2"
path_1="/Root/Backup"
path_cipher="${HOME}/BACKUP/.CIPHER"
path_encipher="$HOME/BACKUP/.ENCIPHER"


# Entre com a pasta dos seus codigos
path_backup="$home"

# Entre com suas crediciais server MEGA
username=''
password=''

cat << EOF
#!/bin/bash
#-----------------------------------------------------------------
# Data:		18-03-2022
# Script:	Backup mega
# Descricao:	Permite fazer de backup automatico para servidores Mega
# Criado por:	Weverson Furtado
# Twitter:	@weversonfurtado
#-----------------------------------------------------------------
EOF

function check_path(){
	if [ -z $(megals $path_1) ];then
		megamkdir $path_1
	fi
	[ -d $path_cipher ] || mkdir "${HOME}/BACKUP" & mkdir $path_cipher
	[ -d $path_encipher ] || mkdir "${HOME}/BACKUP" & mkdir $path_encipher
	check_app
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
		6.1) echo -e "$(cor 31 0)[!] Ja existe o arquivo $(cor 333 0)$arq$(cor 31 0) no servidor!$(cor 0 1)";;
		7) echo -e "$(cor 32 0)[7]----Iniciando o processo de limpeza...$(cor 0 1)";;
		7.1) echo -e "$(cor 31 0)[X] $i - Arquivo $(cor 333 0)$(echo $file | sed 's/.*er\///')$(cor 31 0) foram deletados [!]$(cor 0 1)";;
		7.2) echo -e "$(cor 31 0) [X] $i - Pasta $file estar vazia [!]$(cor 0 1)";;
		8) echo -e "$(cor 32 0)[9]----TODOS PROCESSOS CONCLUIDOS COM SUCESSO!";;
	esac

}


function backup_mega(){
	msg 1
	tar -jcf - $path_backup | pv > $name
	mv $name $path_encipher/.
	msg 2
#	--------------------------------------------
	for n in $(find $path_backup -type f -print);do sha256sum $n 2>/dev/null>>$name.asc;done
	mv *.asc $path_cipher.
	msg 3
#	--------------------------------------------
	gpg -b $path_cipher/*.asc
	msg 4
	msg 5
#	--------------------------------------------
	gpg -c $path_encipher/$name 2>/dev/null
	mv $path_encipher/*.gpg $path_cipher/.
	msg 6
#	--------------------------------------------
	for arq in $(ls $path_cipher/* | sed 's/.*er\///')
	do
		if megals $path_1 | grep '\.' | sed 's/.*os\///' | grep -q $arq
		then
		msg 6.1
		else
			megaput $path_cipher/$arq --path $path_1/
		fi
	done
	msg 7
#	--------------------------------------------
	i=0
	for file in $(find $HOME/BACKUP/ -type f -print);do
		if [ -f $file ];then
			i=$[$i+1]
			shred -uzn5 $file
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
	if [ -x /usr/bin/megacopy ];then
		if [ -x /usr/bin/pv ];then
			megarc
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
		delete_arq_old
	else
		if [ -z $username ];then
			printf "\e[32;1mDigite o nome de usuario:> \e[m"
                        read username
                        echo -e "[Login]\n\nUsername=$username" > .megarc
		else
			echo -e "[Login]\n\nUsername=$username" > .megarc
		fi
		if [ -z $password ]; then
			printf "\e[32;1mDigite a sua senha:> \e[m"
			read -s password
			echo -e "Password=$password" >> .megarc
		else
			echo -e "Password=$password" >> .megarc
		fi
		delete_arq_old
	fi
}

check_path
