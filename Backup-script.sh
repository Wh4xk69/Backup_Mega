#!/usr/bin/bash

hoje=$(date +'%d-%m-%Y')
green="\033[1;32m"
nor="\033[m"
red="\033[1;31m"
yellou="\033[1;33m"
name="Backup_$hoje.tar.bz2"

# Entre com suas crediciais server MEGA
username='123'
password='hdhdhd'

cat << EOF
#!/bin/bash
#-----------------------------------------------------------------
# Data:		18-03-2022
# Script:	Backup mega
# Descricao:	Permite fazer de backup automati para servidores Mega
# Criado por:	Weverson Furtado
# Twitter:	@weversonfurtado
#-----------------------------------------------------------------
EOF


function backup_mega()
{
	echo -e "$green[1]------Processo de Backup iniciado...$nor"
	tar -jcf - * .* | pv > $name
	mv $name /storage/internal/encipher/.
	sleep 2
	echo -e "$green[2]------Processo de Backup concluido...$nor"
	sleep 1
	for n in $(find . -type f -print);do sha256sum $n 2>/dev/null>>$name.asc;done
	mv *.asc /storage/internal/cipher/.
	sleep 2
	echo -e "$green[3]------Processo de Checksum concluido...$nor"
	sleep 1
	gpg -b /storage/internal/cipher/*.asc
	sleep 2
	echo -e "$green[4]------Processo de assinatura concluida...$nor"
	sleep 1
	echo -e "$green[5]------Preparando arquivos pra ser encriptados...$nor"
	sleep 2
	gpg -c /storage/internal/encipher/$name 2>/dev/null
	mv /storage/internal/encipher/*.gpg /storage/internal/cipher/.
	echo -e "$green[6]------Preparando para fazer upload...$nor"
	for arq in $(ls /storage/internal/cipher/* | sed 's/.*er\///')
	do
		if megals /Root/Codigos/ | grep '\.' | sed 's/.*os\///' | grep -q $arq
		then
			echo -e "$red[!] Ja existe o arquivo $yellou$arq$red no servidor!$nor"
		else
			megaput /storage/internal/cipher/$arq --path /Root/Codigos/
		fi
	done
	sleep 3
	echo -e "$green[7]------Iniciando o processo de limpeza...$nor"
	sleep 2
	i=0
	for file in $(find /storage/internal/ -type f -print);do
		if [ -f $file ];then
			i=$[$i+1]
			shred -uzn5 $file
			echo -e "$red[X] $i - Arquivo $yellou$(echo $file | sed 's/.*er\///')$red foram deletados [!]$nor"
		else
			i=$[$i+1]
			echo -e "$red [X] $i - Pasta $file estar vazia [!]$nor"
		fi
	done
	sleep 2
	echo -e "$green[8]------Todos os backup foram salvos!!!$nor"
	sleep 1
	echo -e "$green[9]------TODOS PROCESSOS CONCLUIDOS COM SUCESSO!"
	sleep 3
}

# Essa funcao vai check no sistema possuem os programas Megatools e PV se estao instalados.

function check_app()
{
	if [ -x /usr/bin/megacopy ]; then
		if [ -x /usr/bin/pv ]; then
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

# Funcao vai apagar a partir de 2 backup mais antigos assim ficando somente os os dois mais recente.
# Verifique antes de fazer Backup, assim vai consistir somente dois backup antes de fazer o backup atual.

function delete_arq_antigo()
{
	var1=$(megals /Root/Codigos/ | sort | grep $(date +'%m') | wc -l)
	if [ $var1 -gt 6 ];then

		for del in $(megals /Root/Codigos/ | sort |grep $(date +'%m') |  head -n -6)
		do
			megarm $del
			backup_mega
		done

	else
		backup_mega
	fi
}

# Verificacao de conta de usuario dos servidores mega e criando
# um arquivo megarc pra login rapido.
function megarc()
{
	if [ -e "${HOME}/.megarc" ]; then
		delete_arq_antigo
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
	fi
}

check_app
