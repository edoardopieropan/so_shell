#!/usr/bin/env bash

#GenerateMac: crea un indirizzo mac e controlla che non sia presente nel vbox e db
function GenerateMac {
    local flag=0 #per emulare il do-while
    while [ "$flag" -ne 1 ]
    do
        #tr caratteri permessi, fold lunghezza, head n°stringhe
        newMac=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'A-F0-9' | fold -w 12 | head -n 1)
        for mac in $(grep -o "MACAddress=".*"" $fileVbox | cut -c13-24 | sort -u); do #controllo se il mac è presente nel vbox
            if [ ! "$mac" == "$newMac" ]; then
                flag=1 #il mac c'è nel vbox
            fi
        done

        for mac in $(grep -o ".*" $fileDatabase | sort -u); do #controllo se il mac è presente nel database
            if [ "$mac" == "$newMac" ]; then
                flag=0 #il mac c'è nel database
            fi
        done
    done
}

#ChooseOldMac: permette di scegliere il mac address da sostituire
function ChooseOldMac {
    local flag=0 #per emulare il do-while
    while [ "$flag" -ne 1 ]
    do
        printf "Inserisci il MAC da sostituire: "
        read oldMac;
        if [ ${#oldMac} -eq 12 ]; then #${#variabile} permette di calcolare il numero di byte, posso usare anche | wc -c
            for mac in $(grep -o -i "MACAddress=".*"" $fileVbox | cut -c13-24 | sort -u); do #controllo se il mac è presente nella lista
                if [ "$mac" == "$oldMac" ]; then
                    printf "L' indirizzo inserito è corretto\n"
                    flag=1 #posso uscire dal while
                fi
            done

            if [ "$flag" -eq 0 ]; then
                printf "\nERRORE: l'indirizzo inserito non è presente, inserisci un indirizzo tra quelli elencati sopra\n\n"
            fi

        else
            printf "\nERRORE: il numero di caratteri non è sufficiente, inserisci un indirizzo corretto\n\n"
        fi
    done
}

#ChooseNewMac: permette di scegliere il mac sostituto
function ChooseNewMac {
    local flag=0 #per emulare il do-while
    while [ "$flag" -ne 1 ]
    do
        printf "Inserire l'indirizzo sostitutivo: "
        read newMac;
        flag=0 #azzero la variabile
        if [[ "$newMac" =~ ^[a-fA-F0-9]{12}$ ]] && [ ${#oldMac} -eq 12 ]; then #controllo che sia nel formato di un mac e se lungo 12
            printf "\nformato corretto...ok\n"

            for mac in $(grep -o "MACAddress=".*"" $fileVbox | cut -c13-24 | sort -u); do #controllo se il mac è presente nel vbox
                if [ "$mac" == "$newMac" ]; then
                    printf "ERRORE: l'indirizzo inserito è già presente nel file .vbox\n\n"
                    flag=2 #il mac c'è nel vbox
                fi
            done

            for mac in $(grep -o ".*" $fileDatabase | sort -u); do #controllo se il mac è presente nel database
                if [ "$mac" == "$newMac" ]; then
                    printf "ERRORE: l'indirizzo inserito è già presente nel database\n\n"
                    flag=2 #il mac c'è nel database
                fi
            done

            if [ "$flag" -ne 2 ]; then
                printf "non presente nel .vbox, non presente nel database...ok"
                flag=1; #posso uscire dal while
            fi
        else
            printf "\nERRORE: formato non corretto\n\n"
        fi
    done
}

#ReplaceMAC: sostituisce il mac scelto con uno nuovo
function ReplaceMAC {
    printf "\nIl mac $oldMac verrà sostituito con $newMac.\nConfermare il cambiamento? [S/n]\nScelta: "
    read  conferma;
    if [[ "$conferma" =~ ^[sS]$ ]]; then
        printf "CAMBIAMENTO CONFERMATO\n"
        grep "$oldMac" $fileVbox | sed -i -e "s/$oldMac/$newMac/g" $fileVbox
        echo $newMac>>$fileDatabase
    else
        printf "\nSCELTA ANNULLATA\n"
    fi
}

#Change: terzo comando, modifica un mac con uno nuovo
function Change {
    local oldMac
    local newMac

    ShowVBOX
    ChooseOldMac
    ChooseNewMac
    ReplaceMAC
}

#AutoChange: quarto comando, modifica un mac automaticamente
function AutoChange {
    local oldMac
    local newMac

    ShowVBOX
    ChooseOldMac
    GenerateMac
    ReplaceMAC
}

#ShowDB: secondo comando, visualizza i file presenti all'interno del database
function ShowDB {
    if [ -s $fileDatabase ]; then
        printf "\nElenco dei MAC address nel database\n\n"
        grep -o ".*" $fileDatabase | sort -u
        Pause
    else
        printf "\nIL FILE E' VUOTO\n\n"
        Pause
    fi
}

#ShowVBOX: primo comando, visualizza i file presenti all'interno del file .vbox
function ShowVBOX {
    printf "\nElenco dei MAC address nel file .vbox\n\n"
    grep -o "MACAddress=".*"" $fileVbox | cut -c13-24 | sort -u
    printf "\n"
}

#Exit: quinto comando, termina l'applicazione
function Exit {
    printf "\nL'applicazione è stata chiusa...\n\n"
}

#HelpMainMenu: informa di come va scelta la funzione
function HelpMainMenu {
    choice=0 #evito così l'errore se l'utente preme INVIO senza scrivere niente (per il ciclo while)
    printf "\nERRORE: il comando selezionato non è disponibile.\nPer scegliere un comando inserire il numero corrispondente\n\n"
}

#ChoiceAddressing: indirizza la scelta nei casi scelti
function ChoiceAddressing {
    case $choice in
    1) ShowVBOX; Pause;;
    2) ShowDB;;
    3) Change;;
    4) AutoChange;;
    5) Exit;;
    *) HelpMainMenu $choice;;
    esac
}

#ReadChoice: stampa il menù per l'utente e legge la scelta effettuata
function ReadChoice {
   printf "\nSono disponibili i seguenti comandi:\n"
   printf "1.Visualizza MAC ADDRESS presenti nel file vbox\n"
   printf "2.Visualizza MAC ADDRESS già utilizzati\n"
   printf "3.Modifica MAC ADDRESS manualmente\n"
   printf "4.Modifica MAC ADDRESS automaticamente\n"
   printf "5.Esci\n\n"
   printf "\nInserisci scelta: "
   read choice
   ChoiceAddressing $choice
}

#Pause: permette di "bloccare" l'esecuzione chiedendo di premere un tasto per continuare
function Pause {
    printf "\n"
    read -n1 -rsp $"Premi un tasto qualisasi per continuare o CRTL+C per terminare..."
    printf "\n"
}

#MAIN
fileVbox=$1 #salvo in una variabile il primo paramentro ( il file .vbox )
fileDatabase=$2 #salvo in una variabile il secondo paramentro ( il file database )
choice=0 #per entrare nel while, verrà modificata dall'utente

#Se il numero di argomenti è 0
if [ $# -eq 0 ]; then
    printf "\nERRORE: il numero di argomenti è nullo.\nIl comando va chiamato nel seguente modo:\nscript.sh <fileVBOX> <fileDatabase>\n\n"
    exit
fi
#Se file vbox non esiste
if [[ ! -e "$fileVbox" ]]; then
    printf "\nERRORE: il file .vbox inserito non esiste\n\n"
    printf "L'applicazione è stata chiusa...\n\n"
    exit
else
    if [ ! ${fileVbox##*.} == "vbox" ]; then #permette di verificare l'estensione del file
        printf "\nERRORE: l'estensione del file inserito non è corretta\n\n"
        printf "L'applicazione è stata chiusa...\n\n"
        exit
    fi
fi


#Se non è stato inserito il file database
if [ -z "$fileDatabase" ]; then
    printf "\nATTENZIONE: non è stato inserito alcun file database, si desidera crearlo? [S/n]\nScelta: "
    read  conferma;
    if [[ "$conferma" =~ ^[sS]$ ]]; then
        printf "\nInserisci il nome del file senza estensione: "
        read name
        touch "$name.txt"
        fileDatabase="$name.txt"
        printf "\nE' stato creato il file $fileDatabase\n"
        Pause
    else
        printf "\nL'applicazione è stata terminata...\n\n"
        exit
    fi

#Se inserito ma non esistente
else
    if [[ ! -e "$fileDatabase" ]]; then
        printf "\nATTENZIONE: il file .vbox inserito non esiste, si desidera crearlo? [S/n]\nScelta: "
        read  conferma;
        if [[ "$conferma" =~ ^[sS]$ ]]; then
            touch "$fileDatabase"
            printf "\nE' stato creato il file $fileDatabase\n"
            Pause
        else
            printf "\nL'applicazione è stata chiusa...\n\n"
            exit
        fi
    fi
fi

while [ "$choice" -ne 5 ]
do
    ReadChoice
done