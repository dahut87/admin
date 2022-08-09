# Commande ADMIN

![proxmox](https://www.proxmox.com/images/proxmox/Proxmox_logo_standard_hex_400px.png)

La commande ADMIN permet de simplifier certaines tâches d'administration sur Proxmox, en particulier la gestion du chiffrement des volumes ZFS et le provisionnement dynamique de conteneurs non privilégiés.

## Fonctionnalités

 - Tuer/Créer/détruire un conteneur
 - Convertir un conteneur privilégier vers un conteneur non privilégié
 - Automatiser l'installation de conteneur à partir de scripts hébergés sur git
 - Tuer une machine virtuelle
 - Monitorer la température des disques et leur santé (ZFS status)
 - Installer et mettre à jour la commande ADMIN
 - Produire un rapport sur l'état du serveur
 - Exécuter Rclone pour synchroniser/visualiser/Vérifier un stockage pCloud
 - Démarrer/Arrêter les service de proxmox
 - Voir la configuration des IOMMU (pour PCI passthrought)
 - Installer/Désinstaller un service de déchiffrage des volumes ZFS à partir d'un clé stocké dans un tag NFC
 - lire/copier/protéger/écrire/effacer un badge NFC
 - Déchiffer les volumes ZFS à partir d'un tag NFC
 - Monter/Démonter les clés de chiffrement depuis un tag NFC

## Présentation

Une aide est visible en lançant la commande :
```
admin help
```

La commande admin est une méta-commande qui multiplexe l'accès à plusieurs sous-commandes. Des arguments peuvent être communiqués à la sous-commande. Il existe 3 type de sous-commande :
 - NOARG, la sous-commande n'accepte aucun argument. Aucune aide n'est disponible.
 - 1ARG, la sous-commande n'accepte qu'un argument. Aucun commutateur n'est nécessaire (- ou --). Aucune aide n'est disponible.
 - COMPLEX, la sous-commande accepte plusieurs arguments avec des commutateurs court ou long et son aide est disponible par le commutateur -h ou --help.
Toute commande peut être suivi de "tosignal" & "tomail" qui provoque l'envoi du retour de la commande vers le système de messagerie instantané Signal ou votre messagerie. 
```
admin SOUSCOMMANDE [arguments] [tosignal] [tomail]
```

## Installation

Par la ligne de commande en superutilisateur (ROOT).

```
cd
git clone https://github.com/dahut87/admin.git
chmod 755 ./admin
admin
```

Lors du premier lancement de la commande admin, l'installation de paquet se produit afin de pourvoir à toutes les dépendances.

## Mise à jour

Par la ligne de commande en superutilisateur (ROOT).

```
admin upgrade
```

## Configuration

Le dossier /root/assets contient plusieurs fichiers essentiels au fonctionnement de la commande admin. Il contient aussi un fichier config qui permet de configurer la commande admin.

**Configuration des templates utilisés pour les 3 os supportés par la commande admin (dans **
debian=debian-2022.tgz
ubuntu=ubuntu-2022.tgz
alpine=alpine-2022.tgz

**Nom des réseaux supportés par la commande admin, la première lettre est le raccourci utilisé pour désigner un réseau dans la commande admin: il est donc important que chaque nom de réseau débute par un caractère différent.**
net_ALL=admin,local

**Pour chaque réseau il faudra rajouter six entrées qui définissent le réseau, son CIDR, le VLAN tag, la passerelle, le domaine de recherche et le pont utilisé.**
netL_prefix=192.168.1
netL_cidr=24
netL_tag=no
netL_gw=1
netL_br=vmbr1
netL_search=local.lan

**Le dns est défini de façon globale**
dns="192.168.1.1"

**Le nom du volume ZFS et le point de montage d'un volume ZFS supplémentaire pour héberger les données produites par les conteneurs doit être renseigné**
serverpool="datapool/serveur"
servermount="/srv/serveur"

**Si vous utilisez des duplicata de volume ZFS par la commande syncoid, vous pouvez surveiller leur réplication par la sous-commande "admin rapport". Il faut renseigner le nom de volume ici.**
dup1="volume/serveur_dup"
dup2="volume/donnees_dup"

**Pour la surveillance de votre volume de données par la sous-commande "admin rapport". Il faut renseigner le nom de volume ici.**
datapool="datapool/donnees"

**Pour la surveillance de votre onduleur par la sous-commande "admin rapport". Il faut renseigner la commande de surveillance ici. Il est impératif d'avoir configurer celle-ci préalablement**
load=$(upsc onduleur@localhost battery.charge > /dev/stdout 2> /dev/null)
status=$(upsc onduleur@localhost ups.status > /dev/stdout 2> /dev/null)

**Afin de configurer l'option d'envoi de courriel, il est impératif de configurer GPG et renseigner les courriels ici.**
src="email@expediteur.fr"
dst="email@destinataire.fr"

**Après la création de conteneurs ALPINE (UNIQUEMENT), il est possible d'exécuter des commandes pour personnaliser ceux-ci.**
customize="adduser utilisateur -D -s /bin/false -u 1002 niko \n\
groupmod utilisateur -g 1002 \n\
addgroup -g 1030 commun \n"

**Volumes à synchroniser/voir/vérifier par rclone sur pCloud.**
rclone_vols=/srv/local

**Chemin distant utilisé pour stocker les données pCloud.**
rclone_path=serveur

**Configuration du serveur REST qui communique avec signal et du numéro de téléphone à utiliser.**
signal_host="signal.lan"
signal_num="+33611111111"

## Utilisation

### Gestion des conteneurs

#### Exemples

Création d'un conteneur non privilégié plex d'id 210 en utilisant une template hébergée par git et exécutée avec Docker. Celle-ci comporte 2 coeurs, 2Go de ram, un démarrage automatique en 10ème position, le montage du chemin /srv/video de l'hôte vers le client, avec un volume root d'une taille de 8go en utilisant le réseau prédéfini "S" en utilisant de préférence l'adresse IP 192.168.1.22.
```
admin ctcreate -i 210 -n plex -c 2 -m 2048 -B -b 10 -M /srv/video -v 8 -I 192.168.1.22 -N s -d -g https://github.com/dahut87/lxcauto_plex.git
```

Destruction du conteneur précédemment créé en supprimant les données
```
admin ctdelete -i 210 -y -d
```

Créer un rapport du serveur et l'envoyer par signal et par courriel
```
admin rapport tosignal tomail
```

Envoyer la température des disques par signal
```
admin disktemp tosignal
```

#### Mapping des utilisateurs

Lors de l'usage de conteneurs non privilégier il est important de dresser une cartographie des UID et GID qui réalisent une correspondance entre ceux de l'hôte et ceux des conteneurs clients.

Une cartographie est imposée par la commande admin:

 uid:gid  ->  uid:gid
1002:1002 -> 1002:1002
1027:1027 -> 1027:1027
1028:1028 -> 1028:1028
1029:1029 -> 1029:1029
     1030 ->     :1030
XXXX:XXXX -> 10XXXX:10XXXX
0000:0000 -> 100000:100000

Les uids/guids 1002,1027,1028,1029 et le gid 1030 sont identiques sur l'hôte et sur les conteneurs clients. Les autres sont transformés en ajoutant 100000. Ainsi root possède l'ID 100000 sur l'hôte lorsque le client utilise 0.

### Chiffrement des volumes ZFS par tag NFC

Marche à suivre pour mettre en place le chiffrement ZFS.

 * créer un pool ZFS `zpool create monpool /dev/device ....autres arguments`
 * créer un dataset avec le chiffrement activé `zfs create monpool/mondataset -o encryption=aes-256-gcm -o keyformat=passphrase -o keylocation=file:///mnt/usb/key1 ...autres arguments` il est important d'utiliser le chemin file:///mnt/usb/key suivi d'un chiffre à incrémenté sur chaque dataset utilisant une clé de chiffrement différente.
 * Installer la gestion du NFC `admin nfcinstall`
 * Ajouter une clé sur un badge NFC `admin nfcwrite clédechiffrement1,clédechiffrement2`
 * Nettoyer votre fichier .bash_history qui contient les clés de chiffrements (ATTENTION AUX SNAPSHOTS)
 * Relire la clé depuis votre tag pour vérifier si tout est opérationnel `admin nfcread`
 * Lancer le déchiffrement et le montage des volumes chiffrés ZFS `admin nfczfs`

Normalement cette opération sera réalisée automatiquement au démarrage de votre serveur/nas.

### Utilisation de rclone vers pCloud avec un tag NFC

 * Souscrire un hébergement Cloud chez pCloud
 * Créer un token d'accès depuis l'API pCloud
 * Se connecter sur pCloud et créer un répertoire racine et renseigner celui-ci dans le fichier de configuration /root/assets/config
 * Ecrire un tag avec le token pCloud et les clés de chiffrements (x2) `admin nfcwrite tokenpcloud,clédechiffrement1,clédechiffrement2`
 * Visualiser votre volume pCloud distant `admin rclone view`
 * Configurer les chemins a synchroniser dans le fichier de configuration
 * Lancer une première synchronisation `admin rclone sync`
 * Lancer une vérification de la copie `admin rclone check`
 * Visualiser votre volume pCloud distant `admin rclone view`
