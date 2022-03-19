#!/usr/bin/bash

hoje=$(date +'%d-%m-%Y')
green="\033[1;32m"
nor="\033[m"
red="\033[1;31m"
yellou="\033[1;33m"
name="Backup_$hoje.tar.bz2"
path_1="/Root/Backup"
path_cipher='$HOME/BACKUP/.CIPHER'
path_encipher='$HOME/BACKUP/.ENCIPHER'


# Entre com a pasta dos seus codigos
path_backup=''

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

function check_path()
{
	if [ -z $(megals $path_1) ];then
		megamkdir $path_1
	fi
	[ -d $path_cipher ] || mkdir $path_cipher
	[ -d $path_encipher ] || mkdir $path_encipher
	check_app
}


function backup_mega()
{
	echo -e "$green[1]------Processo de Backup iniciado...$nor"
	tar -jcf - $path_backup | pv > $name
	mv $name $path_encipher/.
	echo -e "$green[2]------Processo de Backup concluido...$nor"
	for n in $(find $path_backup -type f -print);do sha256sum $n 2>/dev/null>>$name.asc;done
	mv *.asc $path_cipher.
	echo -e "$green[3]------Processo de Checksum concluido...$nor"
	gpg -b $path_cipher/*.asc
	echo -e "$green[4]------Processo de assinatura concluida...$nor"
	echo -e "$green[5]------Preparando arquivos pra ser encriptados...$nor"
	gpg -c $path_encipher/$name 2>/dev/null
	mv $path_encipher/*.gpg $path_cipher/.
	echo -e "$green[6]------Preparando para fazer upload...$nor"
	for arq in $(ls $path_cipher/* | sed 's/.*er\///')
	do
		if megals $path_1 | grep '\.' | sed 's/.*os\///' | grep -q $arq
		then
			echo -e "$red[!] Ja existe o arquivo $yellou$arq$red no servidor!$nor"
		else
			megaput $path_cipher/$arq --path $path_1/
		fi
	done
	echo -e "$green[7]------Iniciando o processo de limpeza...$nor"
	i=0
	for file in $(find $HOME/BACKUP/ -type f -print);do
		if [ -f $file ];then
			i=$[$i+1]
			shred -uzn5 $file
			echo -e "$red[X] $i - Arquivo $yellou$(echo $file | sed 's/.*er\///')$red foram deletados [!]$nor"
		else
			i=$[$i+1]
			echo -e "$red [X] $i - Pasta $file estar vazia [!]$nor"
		fi
	done
	echo -e "$green[8]------Todos os backup foram salvos!!!$nor"
	echo -e "$green[9]------TODOS PROCESSOS CONCLUIDOS COM SUCESSO!"

}

# Essa funcao vai check no sistema possuem os
# programas Megatools e PV se estao instalados.

function check_app()
{
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

function delete_arq_old()
{
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

function megarc()
{
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
