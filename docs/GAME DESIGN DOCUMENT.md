# **GAME DESIGN DOCUMENT** {#game-design-document}

## **RPG Tour par Tour à Système de Cartes** {#rpg-tour-par-tour-à-système-de-cartes}

# **SOMMAIRE** {#sommaire}

**[GAME DESIGN DOCUMENT	1](#game-design-document)**

[RPG Tour par Tour à Système de Cartes	1](#rpg-tour-par-tour-à-système-de-cartes)

[**SOMMAIRE	2**](#sommaire)

[**1\. Présentation générale	6**](#1.-présentation-générale)

[1.1 Concept du jeu	6](#1.1-concept-du-jeu)

[1.2 Inspirations	6](#1.2-inspirations)

[1.3 Objectifs du projet	7](#1.3-objectifs-du-projet)

[Objectif principal	7](#objectif-principal)

[Objectifs techniques	7](#objectifs-techniques)

[Objectifs de gameplay (MVP)	7](#objectifs-de-gameplay-\(mvp\))

[Objectifs long terme	7](#objectifs-long-terme)

[**2\. Vision du gameplay	7**](#2.-vision-du-gameplay)

[2.1 Boucle de gameplay principale	7](#2.1-boucle-de-gameplay-principale)

[2.2 Expérience joueur recherchée	8](#2.2-expérience-joueur-recherchée)

[2.3 Piliers du gameplay	9](#2.3-piliers-du-gameplay)

[1\. Gestion de la main	9](#1.-gestion-de-la-main)

[2\. Fusion de cartes	9](#2.-fusion-de-cartes)

[3\. Limitation des actions	9](#3.-limitation-des-actions)

[**3\. Système de combat	9**](#3.-système-de-combat)

[3.1 Structure d’un combat	9](#3.1-structure-d’un-combat)

[3.2 Système de tour par tour	10](#3.2-système-de-tour-par-tour)

[3.3 Gestion des actions	10](#3.3-gestion-des-actions)

[Sélection	10](#sélection)

[File d’actions	11](#file-d’actions)

[Résolution	11](#résolution)

[Calcul des dégâts (MVP)	11](#calcul-des-dégâts-\(mvp\))

[Contraintes	11](#contraintes)

[3.4 Conditions de victoire et défaite	11](#3.4-conditions-de-victoire-et-défaite)

[Victoire	11](#victoire)

[Défaite	11](#défaite)

[Priorité	11](#priorité)

[Fin de combat	11](#fin-de-combat)

[3.5 Système d’ultime (hors MVP)	12](#3.5-système-d’ultime-\(hors-mvp\))

[Fonctionnement	12](#fonctionnement)

[Utilisation	12](#utilisation)

[Objectifs gameplay	12](#objectifs-gameplay)

[Contraintes techniques	12](#contraintes-techniques)

[**4\. Système de cartes	12**](#4.-système-de-cartes)

[4.1 Définition d’une carte	12](#4.1-définition-d’une-carte)

[Attributs (MVP)	13](#attributs-\(mvp\))

[4.2 Types de cartes	13](#4.2-types-de-cartes)

[MVP	13](#mvp)

[Évolutions futures (hors MVP)	13](#évolutions-futures-\(hors-mvp\))

[4.3 Système de pioche	13](#4.3-système-de-pioche)

[Fonctionnement (MVP simplifié)	13](#fonctionnement-\(mvp-simplifié\))

[Gestion de la main	14](#gestion-de-la-main)

[Évolutions futures (hors MVP)	14](#évolutions-futures-\(hors-mvp\)-1)

[4.4 Limite de cartes jouables	14](#4.4-limite-de-cartes-jouables)

[Règle principale	14](#règle-principale)

[Conséquences gameplay	14](#conséquences-gameplay)

[Ordre d’exécution	14](#ordre-d’exécution)

[4.5 Interaction avec les autres systèmes	14](#4.5-interaction-avec-les-autres-systèmes)

[4.6 Contraintes de conception	15](#4.6-contraintes-de-conception)

[**5\. Système de fusion	15**](#5.-système-de-fusion)

[5.1 Règles de fusion	15](#5.1-règles-de-fusion)

[Conditions de fusion	15](#conditions-de-fusion)

[Résultat	15](#résultat)

[5.2 Gestion des rangs	15](#5.2-gestion-des-rangs)

[Règles	15](#règles)

[Évolution	16](#évolution)

[5.3 Moment de la fusion	16](#5.3-moment-de-la-fusion)

[MVP	16](#mvp-1)

[Recommandation	16](#recommandation)

[5.4 Gestion des chaînes de fusion	16](#5.4-gestion-des-chaînes-de-fusion)

[Règle	16](#règle)

[5.5 Impact sur la main	16](#5.5-impact-sur-la-main)

[5.6 Impact gameplay	17](#5.6-impact-gameplay)

[5.7 Contraintes techniques	17](#5.7-contraintes-techniques)

[5.8 Cas particuliers	17](#5.8-cas-particuliers)

[**6\. Entités du jeu	17**](#6.-entités-du-jeu)

[6.1 Héros	17](#6.1-héros)

[Attributs	18](#attributs)

[Fonctionnalités	18](#fonctionnalités)

[Contraintes techniques	18](#contraintes-techniques-1)

[6.2 Ennemis	18](#6.2-ennemis)

[Attributs	18](#attributs-1)

[Fonctionnalités	18](#fonctionnalités-1)

[Contraintes techniques	19](#contraintes-techniques-2)

[6.3 Statistiques de base	19](#6.3-statistiques-de-base)

[6.4 Relation entre entités et systèmes	19](#6.4-relation-entre-entités-et-systèmes)

[**7\. Architecture technique (Godot 4\)	20**](#7.-architecture-technique-\(godot-4\))

[7.1 Organisation du projet	20](#7.1-organisation-du-projet)

[Dossiers principaux	20](#dossiers-principaux)

[7.2 Séparation Data / Logique / UI	20](#7.2-séparation-data-/-logique-/-ui)

[Data (Resources)	20](#data-\(resources\))

[Logique (Scripts)	20](#logique-\(scripts\))

[UI / Scenes	21](#ui-/-scenes)

[7.3 Resources (Data)	21](#7.3-resources-\(data\))

[Héros	21](#héros)

[Ennemis	21](#ennemis)

[Cartes	21](#cartes)

[7.4 Scripts (Logique)	21](#7.4-scripts-\(logique\))

[CombatManager.gd	21](#combatmanager.gd)

[CardManager.gd	21](#cardmanager.gd)

[EnemyAI.gd	22](#enemyai.gd)

[7.5 Scènes (Affichage)	22](#7.5-scènes-\(affichage\))

[combat.tscn	22](#combat.tscn)

[Avantages	22](#avantages)

[7.6 Bonnes pratiques techniques	22](#7.6-bonnes-pratiques-techniques)

[**8\. Interface utilisateur (UI)	22**](#8.-interface-utilisateur-\(ui\))

[8.1 Interface de combat	23](#8.1-interface-de-combat)

[8.2 Affichage des cartes	23](#8.2-affichage-des-cartes)

[Main du joueur	23](#main-du-joueur)

[Sélection	23](#sélection-1)

[Recommandations	24](#recommandations)

[8.3 Feedback joueur	24](#8.3-feedback-joueur)

[Types de feedback	24](#types-de-feedback)

[Recommandations	24](#recommandations-1)

[**9\. Système de progression (hors MVP)	24**](#9.-système-de-progression-\(hors-mvp\))

[9.1 Amélioration des personnages	24](#9.1-amélioration-des-personnages)

[Mécaniques prévues	24](#mécaniques-prévues)

[Contraintes	25](#contraintes-1)

[9.2 Déblocage de cartes	25](#9.2-déblocage-de-cartes)

[Mécaniques prévues	25](#mécaniques-prévues-1)

[Conséquences gameplay	25](#conséquences-gameplay-1)

[9.3 Difficulté	25](#9.3-difficulté)

[Mécaniques prévues	25](#mécaniques-prévues-2)

[Objectifs	26](#objectifs)

[**10\. Système narratif (inspiration Undertale)	26**](#10.-système-narratif-\(inspiration-undertale\))

[10.1 Système de choix	26](#10.1-système-de-choix)

[Exemples de choix	26](#exemples-de-choix)

[Fonctionnement	26](#fonctionnement-1)

[10.2 Flags persistants	26](#10.2-flags-persistants)

[Exemples de flags	26](#exemples-de-flags)

[Gestion	27](#gestion)

[10.3 Impact sur le jeu	27](#10.3-impact-sur-le-jeu)

[Objectifs	27](#objectifs-1)

[**11\. Système de collection / Gacha (hors MVP)	27**](#11.-système-de-collection-/-gacha-\(hors-mvp\))

[11.1 Invocation de personnages	27](#11.1-invocation-de-personnages)

[Fonctionnement	28](#fonctionnement-2)

[Étapes	28](#étapes)

[11.2 Rareté	28](#11.2-rareté)

[Correspondance étoiles → grade	28](#correspondance-étoiles-→-grade)

[Impacts	28](#impacts)

[Recommandation	29](#recommandation-1)

[11.3 Gestion de collection	29](#11.3-gestion-de-collection)

[Fonctionnalités prévues	29](#fonctionnalités-prévues)

[Contraintes techniques	29](#contraintes-techniques-3)

[**12\. Scope du MVP	29**](#12.-scope-du-mvp)

[12.1 Fonctionnalités incluses	29](#12.1-fonctionnalités-incluses)

[12.2 Fonctionnalités exclues (hors MVP)	30](#12.2-fonctionnalités-exclues-\(hors-mvp\))

[12.3 Critères de validation	30](#12.3-critères-de-validation)

[**13\. Roadmap de développement	31**](#13.-roadmap-de-développement)

[13.1 Phase 1 : Combat de base (MVP)	31](#13.1-phase-1-:-combat-de-base-\(mvp\))

[Tâches principales	31](#tâches-principales)

[13.2 Phase 2 : Améliorations (post-MVP)	31](#13.2-phase-2-:-améliorations-\(post-mvp\))

[Tâches principales	31](#tâches-principales-1)

[13.3 Phase 3 : Extensions (hors MVP / long terme)	32](#13.3-phase-3-:-extensions-\(hors-mvp-/-long-terme\))

[Tâches principales	32](#tâches-principales-2)

[**14\. Contraintes et bonnes pratiques	32**](#14.-contraintes-et-bonnes-pratiques)

[14.1 Clean Code	32](#14.1-clean-code)

[Recommandations	32](#recommandations-2)

[Objectif	33](#objectif)

[14.2 Modularité	33](#14.2-modularité)

[Principes	33](#principes)

[Avantages	33](#avantages-1)

[14.3 Scalabilité	33](#14.3-scalabilité)

[Recommandations	33](#recommandations-3)

[Objectif	33](#objectif-1)

### 

# **1\. Présentation générale** {#1.-présentation-générale}

## **1.1 Concept du jeu** {#1.1-concept-du-jeu}

Le projet consiste en un RPG tour par tour basé sur un système de cartes.  
Le joueur contrôle une équipe de héros et affronte des ennemis dans des combats structurés en tours.

La particularité principale du gameplay repose sur :

* l’utilisation de cartes de compétences tirées aléatoirement,  
* un système de fusion automatique de cartes identiques,  
* une limitation du nombre d’actions par tour.

Chaque combat demande donc une prise de décision stratégique basée sur la gestion de la main, le positionnement des cartes et l’optimisation des fusions.

À terme, le jeu intégrera :

* un système de progression des personnages  
* une collection de héros  
* un système de choix narratifs influençant le déroulement du jeu  
* un Gacha pour l’obtention de héros

Cependant, dans sa première version (MVP), le projet se concentre uniquement sur un système de combat simple, fonctionnel et extensible.

## **1.2 Inspirations** {#1.2-inspirations}

Le projet s’inspire de plusieurs jeux existants, chacun apportant une mécanique clé :

* Combat :  
  *  Système inspiré de jeux comme *The Seven Deadly Sins: Grand Cross*, avec des cartes de compétences et une mécanique de fusion (montée en rang des cartes).  
  * Le système de combat de dyslite également.   
* Structure et progression :  
   Inspiration des jeux type *Honkai Star Rail*, notamment pour la gestion des personnages et l’extensibilité via des données séparées.  
* Narration :  
   Inspiration de *Undertale*, avec un système de choix ayant un impact réel sur le jeu (non implémenté dans le MVP).

Ces inspirations servent de base, mais le but est de créer un système cohérent et original, adapté aux contraintes techniques du projet.

## **1.3 Objectifs du projet** {#1.3-objectifs-du-projet}

### Objectif principal {#objectif-principal}

Créer un système de combat tour par tour basé sur des cartes, robuste, modulaire et facilement extensible.

### Objectifs techniques {#objectifs-techniques}

* Utiliser Godot 4 comme moteur de jeu  
* Mettre en place une architecture claire :  
  * séparation des données (Resources),  
  * séparation de la logique (Scripts),  
  * séparation de l’affichage (Scenes/UI)  
* Assurer un code maintenable et évolutif

### Objectifs de gameplay (MVP) {#objectifs-de-gameplay-(mvp)}

* Permettre un combat simple entre un héros et un ennemi  
* Implémenter un système de cartes de dégâts  
* Implémenter la fusion de cartes  
* Gérer un tour par tour basique  
* Détecter victoire et défaite

### Objectifs long terme {#objectifs-long-terme}

* Ajouter des effets de cartes variés (soins, buffs, debuffs)  
* Introduire plusieurs personnages jouables  
* Implémenter un système de progression  
* Ajouter un système narratif à choix  
* Intégrer un système de collection (type gacha)

# **2\. Vision du gameplay** {#2.-vision-du-gameplay}

## **2.1 Boucle de gameplay principale** {#2.1-boucle-de-gameplay-principale}

La boucle de gameplay repose sur une succession de combats structurés en tours.  
Dans le cadre du MVP, cette boucle est volontairement simplifiée afin de valider les mécaniques principales.

Déroulement :

1. Entrée en combat  
    Le joueur affronte un ennemi avec une équipe de héros.  
2. Génération de la main  
    Le joueur reçoit un ensemble de cartes (main).  
3. Phase joueur  
   * Le joueur sélectionne jusqu’à 3 cartes  
   * Les cartes peuvent fusionner automatiquement si elles sont adjacentes  
   * Les cartes sélectionnées sont jouées dans l’ordre  
4. Résolution des actions  
   * Les effets des cartes sont appliqués (dégâts pour le MVP)  
5. Phase ennemi  
   * L’ennemi exécute son action (attaque simple dans le MVP)  
6. Vérification des conditions  
   * Si l’ennemi est vaincu → victoire  
   * Si le héros est vaincu → défaite  
   * Sinon → nouveau tour

Cette boucle se répète jusqu’à la fin du combat.

## **2.2 Expérience joueur recherchée** {#2.2-expérience-joueur-recherchée}

Le jeu vise une expérience basée sur :

* la prise de décision rapide mais réfléchie,  
* l’optimisation des ressources disponibles (cartes),  
* la satisfaction liée aux combinaisons efficaces (fusion de cartes).

Le joueur doit constamment arbitrer entre :

* utiliser ses cartes immédiatement,  
* ou attendre une meilleure combinaison via la fusion.

L’objectif est de créer une tension légère à chaque tour, sans complexité excessive dans le MVP.

À terme, l’expérience évoluera vers :

* des choix stratégiques plus profonds,  
* une gestion d’équipe,  
* un impact narratif des décisions. 

## **2.3 Piliers du gameplay** {#2.3-piliers-du-gameplay}

Le jeu repose sur trois piliers principaux :

### 1\. Gestion de la main {#1.-gestion-de-la-main}

Le joueur doit gérer un ensemble limité de cartes à chaque tour.  
Chaque carte représente une action potentielle, et leur ordre a une importance.

### 2\. Fusion de cartes {#2.-fusion-de-cartes}

La mécanique entrale du jeu.  
Deux cartes identiques adjacentes fusionnent automatiquement pour former une version plus puissante.

Ce système introduit :

* une dimension de positionnement,  
* une anticipation des tours suivants,  
* une récompense pour la planification.

### 3\. Limitation des actions {#3.-limitation-des-actions}

Le joueur ne peut jouer qu’un nombre limité de cartes par tour (3 dans le MVP).

Cela impose :

* des choix stratégiques,  
* une priorisation des actions,  
* une gestion du timing. 

# **3\. Système de combat** {#3.-système-de-combat}

## **3.1 Structure d’un combat** {#3.1-structure-d’un-combat}

Un combat oppose un héros contrôlé par le joueur à un ennemi.

Le combat est instancié dans une scène dédiée et géré par un contrôleur central (Combat Manager).  
Il se déroule selon une séquence fixe et déterministe.

Structure globale :

1. Initialisation  
   * Chargement des données du héros et de l’ennemi  
   * Initialisation des points de vie  
   * Génération de la première main de cartes  
2. Boucle de combat  
   * Phase joueur  
   * Phase ennemi  
   * Vérification des conditions de fin  
3. Fin de combat  
   * Victoire ou défaite  
   * Arrêt du combat

Chaque combat est indépendant et ne conserve que les informations nécessaires au système global (progression future, non MVP).

## **3.2 Système de tour par tour** {#3.2-système-de-tour-par-tour}

Le système est basé sur des tours alternées entre le joueur et l’ennemi.

Ordre d’un tour :

1. Début du tour joueur  
   * Rafraîchissement ou mise à jour de la main (selon implémentation)  
   * Application éventuelle de règles automatiques (ex : fusion)  
2. Phase d’action du joueur  
   * Le joueur choisit jusqu’à 3 cartes  
   * Les cartes sont placées dans une file d’actions  
3. Résolution des actions du joueur  
   * Les cartes sont exécutées dans l’ordre choisi  
   * Les effets sont appliqués immédiatement  
4. Phase ennemi  
   * L’ennemi exécute une action simple (attaque dans le MVP)  
5. Fin de tour  
   * Mise à jour des états  
   * Retour au tour suivant si aucune condition de fin n’est atteinte

Ce système garantit une lisibilité claire et une exécution prévisible des actions.

## **3.3 Gestion des actions** {#3.3-gestion-des-actions}

Les actions sont entièrement pilotées par les cartes.

### Sélection {#sélection}

* Le joueur peut sélectionner jusqu’à 3 cartes par tour  
* L’ordre de sélection définit l’ordre d’exécution

### File d’actions {#file-d’actions}

* Les cartes sélectionnées sont placées dans une liste ordonnée  
* Cette liste est traitée séquentiellement

### Résolution {#résolution}

Pour chaque carte :

1. Lecture de ses données (damage, rank, etc.)  
2. Application de l’effet sur la cible (ennemi)  
3. Mise à jour de l’état (points de vie)

### Calcul des dégâts (MVP) {#calcul-des-dégâts-(mvp)}

Dégâts \= valeur de la carte \+ statistique d’attaque du héros

### Contraintes {#contraintes}

* Une carte ne peut être jouée qu’une seule fois par tour  
* Les cartes utilisées sont retirées de la main (ou consommées selon design futur)

## **3.4 Conditions de victoire et défaite** {#3.4-conditions-de-victoire-et-défaite}

Le combat se termine immédiatement dès qu’une condition est remplie.

### Victoire {#victoire}

* Les points de vie de l’ennemi atteignent 0 ou moins

### Défaite {#défaite}

* Les points de vie des héros atteignent 0 ou moins

### Priorité {#priorité}

* Après chaque action, une vérification est effectuée  
* Si les deux entités tombent à 0 simultanément :  
  * règle à définir (par défaut : défaite joueur ou match nul)

### Fin de combat {#fin-de-combat}

* Blocage de toute nouvelle action  
* Retour d’un état (victoire / défaite)  
* Transition vers une autre scène (hors MVP) 

## **3.5 Système d’ultime (hors MVP)** {#3.5-système-d’ultime-(hors-mvp)}

Un système d’ultime sera ajouté pour enrichir la profondeur stratégique des combats.

Chaque héros possède une capacité spéciale appelée "ultime", plus puissante que les cartes classiques.

#### Fonctionnement {#fonctionnement}

* Chaque action effectuée par le héros (ex : jouer une carte) génère une certaine quantité de charge  
* Une jauge d’ultime est associée à chaque héros  
* Lorsque cette jauge atteint un seuil défini, l’ultime devient utilisable

#### Utilisation {#utilisation}

* L’ultime est considéré comme une action  
* Il peut remplacer une carte dans la limite des actions par tour  
* Il applique un effet puissant (dégâts élevés, buff, debuff, etc.)

#### Objectifs gameplay {#objectifs-gameplay}

* Récompenser l’utilisation active des cartes  
* Ajouter un timing stratégique  
* Créer des moments forts en combat

#### Contraintes techniques {#contraintes-techniques}

* Nécessite un système de ressource supplémentaire (jauge)  
* Nécessite une gestion d’état par héros  
* Nécessite une intégration dans le système d’actions 

# **4\. Système de cartes** {#4.-système-de-cartes}

## **4.1 Définition d’une carte** {#4.1-définition-d’une-carte}

Une carte représente une action que le joueur peut effectuer durant son tour.

Dans le MVP, une carte est une entité simple contenant des données statiques et un effet unique.

Chaque carte est définie par une structure de données (Resource dans Godot) et utilisée par le système de combat pour exécuter des actions.

### Attributs (MVP) {#attributs-(mvp)}

* name : nom de la carte  
* damage : valeur de dégâts (null si la carte a juste pour but d’etre un buff/debuff)  
* rank : niveau de puissance de la carte (1 à 3\)

Une carte ne contient pas directement de logique complexe :  
 elle sert principalement de support de données pour le système de combat.

## **4.2 Types de cartes** {#4.2-types-de-cartes}

### MVP {#mvp}

Un seul type de carte est implémenté :

* Carte de dégâts  
   Inflige des dégâts directs à l’ennemi

### Évolutions futures (hors MVP) {#évolutions-futures-(hors-mvp)}

Le système est conçu pour être extensible avec d’autres types :

* Cartes de soin  
* Cartes de buff (augmentation de stats)  
* Cartes de debuff (réduction des stats ennemies)  
* Cartes à effets spéciaux (multi-hit, altérations d’état, etc.)

Ces types devront rester compatibles avec le système existant.

## **4.3 Système de pioche** {#4.3-système-de-pioche}

Le joueur dispose d’une main de cartes générée automatiquement.

### Fonctionnement (MVP simplifié) {#fonctionnement-(mvp-simplifié)}

* Au début du combat, une main est générée  
* La main contient un nombre fixe de cartes  
* Les cartes sont générées aléatoirement à partir d’un pool simple

### Gestion de la main {#gestion-de-la-main}

* Les cartes sont affichées dans un ordre précis  
* Cet ordre est important pour la mécanique de fusion  
* Après utilisation, les cartes peuvent être :  
  * soit supprimées  
  * soit remplacées (selon implémentation choisie)

### Évolutions futures (hors MVP) {#évolutions-futures-(hors-mvp)-1}

* Pioche dynamique à chaque tour  
* Défausse  
* Cartes rares

## **4.4 Limite de cartes jouables** {#4.4-limite-de-cartes-jouables}

Le joueur est limité dans le nombre d’actions par tour.

### Règle principale {#règle-principale}

* Maximum : 3 cartes jouables par tour

### Conséquences gameplay {#conséquences-gameplay}

* Oblige à faire des choix  
* Empêche le spam d’actions  
* Encourage la planification

### Ordre d’exécution {#ordre-d’exécution}

* L’ordre dans lequel les cartes sont sélectionnées détermine leur ordre d’exécution

## **4.5 Interaction avec les autres systèmes** {#4.5-interaction-avec-les-autres-systèmes}

Le système de cartes est au centre du gameplay et interagit avec :

* Le système de combat  
   → pour appliquer les effets  
* Le système de fusion  
   → pour modifier les cartes avant utilisation  
* Le système d’ultime (futur)  
   → pour générer de la charge

## **4.6 Contraintes de conception** {#4.6-contraintes-de-conception}

Pour garantir la maintenabilité :

* Les cartes doivent être définies uniquement via des données (Resources)  
* Aucune logique complexe ne doit être directement codée dans les cartes  
* Les effets doivent être exécutés par des systèmes externes (ex : CombatManager) 

# **5\. Système de fusion** {#5.-système-de-fusion}

## **5.1 Règles de fusion** {#5.1-règles-de-fusion}

Le système de fusion est une mécanique centrale du gameplay.

Deux cartes identiques fusionnent automatiquement si elles sont **adjacentes dans la main**.

### Conditions de fusion {#conditions-de-fusion}

* Les cartes doivent avoir :  
  * le même identifiant (même type de carte)  
  * le même rang  
* Les cartes doivent être côte à côte dans la main

### Résultat {#résultat}

* Les deux cartes sont remplacées par une seule carte  
* La nouvelle carte a un rang supérieur

Exemple :

* Carte A (rang 1\) \+ Carte A (rang 1\) → Carte A (rang 2\)

## **5.2 Gestion des rangs** {#5.2-gestion-des-rangs}

Chaque carte possède un rang de puissance.

### Règles {#règles}

* Rang minimum : 1  
* Rang maximum : 3

### Évolution {#évolution}

* Rang 1 → Rang 2 (fusion de deux cartes rang 1\)  
* Rang 2 → Rang 3 (fusion de deux cartes rang 2\)

Une carte de rang 3 ne peut plus évoluer.

## **5.3 Moment de la fusion** {#5.3-moment-de-la-fusion}

La fusion est **automatique** et se déclenche à un moment précis.

### MVP {#mvp-1}

* La fusion s’effectue :  
  * soit au début du tour joueur  
  * soit immédiatement après une modification de la main (option à choisir)

### Recommandation {#recommandation}

Pour garder un comportement clair et contrôlable :

* effectuer la fusion **au début du tour joueur**

## **5.4 Gestion des chaînes de fusion** {#5.4-gestion-des-chaînes-de-fusion}

Une fusion peut entraîner d’autres fusions.

Exemple :

* A1 \+ A1 → A2  
* Si un autre A2 est adjacent → A2 \+ A2 → A3

### Règle {#règle}

* Le système doit gérer les fusions en cascade  
* Tant que des conditions de fusion sont présentes, elles doivent être résolues

## **5.5 Impact sur la main** {#5.5-impact-sur-la-main}

Après fusion :

* Le nombre total de cartes diminue  
* Les cartes restantes se réorganisent (compactage)  
* L’ordre des cartes est mis à jour

Ce comportement doit être cohérent pour éviter toute confusion côté joueur.

## **5.6 Impact gameplay** {#5.6-impact-gameplay}

Le système de fusion introduit :

* Une dimension de positionnement (ordre des cartes)  
* Une planification à court terme  
* Une récompense pour l’optimisation

Le joueur doit décider :

* utiliser une carte immédiatement  
* ou attendre une fusion plus puissante

## **5.7 Contraintes techniques** {#5.7-contraintes-techniques}

* Le système doit être indépendant de l’UI  
* La fusion doit être gérée dans une logique dédiée (ex : CardManager)  
* Les cartes doivent être modifiées via leurs données, sans duplication de logique

## **5.8 Cas particuliers** {#5.8-cas-particuliers}

* Aucune fusion si les cartes ne sont pas adjacentes  
* Aucune fusion si les rangs sont différents  
* Aucune fusion au-delà du rang maximum  
* Le système doit éviter les boucles infinies 

# **6\. Entités du jeu** {#6.-entités-du-jeu}

Dans le MVP, les entités du jeu sont les objets principaux manipulés lors des combats : héros et ennemis. Elles contiennent les données et statistiques nécessaires pour interagir avec le système de cartes et de combat.

## **6.1 Héros** {#6.1-héros}

Le héros est le personnage contrôlé par le joueur. Il possède des attributs de base et peut évoluer dans le futur.

### Attributs {#attributs}

* **name** : Nom du héros (String)  
* **max\_hp** : Points de vie maximum (int)  
* **current\_hp** : Points de vie actuels (int)  
* **attack** : Statistique d’attaque de base (int)  
* **hand** : Liste des cartes actuellement disponibles (array de CardData)  
* **ultimate\_charge** : Valeur de la jauge d’ultime (int, futur)

### Fonctionnalités {#fonctionnalités}

* Subir et infliger des dégâts  
* Jouer des cartes  
* Fusionner des cartes dans la main (via CardManager)  
* (Futur) Débloquer et utiliser une capacité ultime

### Contraintes techniques {#contraintes-techniques-1}

* Toutes les données sont stockées dans une Resource HeroData  
* Aucun calcul ou logique complexe n’est directement intégré dans la Resource  
* Toutes les actions sont gérées par le CombatManager ou le CardManager

## **6.2 Ennemis** {#6.2-ennemis}

L’ennemi est l’opposant contrôlé par le système du jeu.

### Attributs {#attributs-1}

* **name** : Nom de l’ennemi (String)  
* **max\_hp** : Points de vie maximum (int)  
* **current\_hp** : Points de vie actuels (int)  
* **attack** : Statistique d’attaque (int)  
* **ai\_behavior** : Définition du comportement (ex: attaque simple, cible aléatoire, futur)

### Fonctionnalités {#fonctionnalités-1}

* Infliger des dégâts au héros  
* Réagir selon son comportement défini  
* Vérification de sa propre condition de victoire/défaite

### Contraintes techniques {#contraintes-techniques-2}

* Toutes les données sont stockées dans une Resource EnemyData  
* La logique de l’IA doit être séparée de la Resource  
* Les attaques et actions sont exécutées via le CombatManager

## **6.3 Statistiques de base** {#6.3-statistiques-de-base}

| Statistique | Description |
| :---- | :---- |
| max\_hp | Points de vie maximum de l’entité |
| current\_hp | Points de vie actuels |
| attack | Puissance d’attaque de base |
| hand | Cartes actuellement disponibles (héros uniquement) |
| ultimate\_charge | Valeur de la jauge d’ultime (héros uniquement, futur) |

## **6.4 Relation entre entités et systèmes** {#6.4-relation-entre-entités-et-systèmes}

* **Cartes** : Les entités utilisent des cartes pour agir  
* **Fusion** : Les cartes des héros peuvent fusionner en fonction de la main  
* **CombatManager** : Contrôle l’ordre des tours et applique les actions des entités  
* **Jauge d’ultime (futur)** : Chargée par les actions des héros et utilisée pour déclencher des capacités puissantes

# **7\. Architecture technique (Godot 4\)** {#7.-architecture-technique-(godot-4)}

L’architecture du projet est pensée pour être **modulaire, claire et évolutive**, en respectant la séparation stricte des responsabilités : données, logique et affichage.

## **7.1 Organisation du projet** {#7.1-organisation-du-projet}

### **Dossiers principaux** {#dossiers-principaux}

/project\_root/

/data/           \# Resources (données des héros, ennemis, cartes)

/scripts/        \# Scripts de logique (combat, cartes, IA, fusion)

/scenes/         \# Scenes et UI

/assets/         \# Images, sons, animations

/tests/          \# Tests unitaires et scènes de test

Cette organisation permet de trouver rapidement chaque type de fichier et de limiter les dépendances.

## **7.2 Séparation Data / Logique / UI** {#7.2-séparation-data-/-logique-/-ui}

### Data (Resources) {#data-(resources)}

* Contient uniquement les **données statiques** : héros, ennemis, cartes  
* Aucun calcul ou logique complexe  
* Exemple : HeroData.gd, CardData.gd, EnemyData.gd

### Logique (Scripts) {#logique-(scripts)}

* Contient toute la logique du jeu :  
  * CombatManager (gestion du tour par tour)  
  * CardManager (gestion des cartes et fusion)  
  * EnemyAI (logique de l’ennemi)  
* Les scripts accèdent aux Resources pour lire les données et appliquer les effets  
* Aucun affichage ou rendu graphique n’est géré ici

### UI / Scenes {#ui-/-scenes}

* Contient uniquement l’affichage :  
  * Interface de combat  
  * Affichage des cartes et mains  
  * Barre de vie, feedback joueur  
* Les scènes reçoivent les informations de la logique et affichent l’état actuel  
* La logique ne doit jamais dépendre de l’UI pour fonctionner

## **7.3 Resources (Data)** {#7.3-resources-(data)}

### Héros {#héros}

* HeroData.gd : contient les stats et l’inventaire de cartes

### Ennemis {#ennemis}

* EnemyData.gd : contient les stats et le comportement AI

### Cartes {#cartes}

* CardData.gd : contient le nom, dégâts, rang, et type de carte

**Avantages :**

* Extensible facilement  
* Les données peuvent être modifiées sans toucher à la logique  
* Compatible avec des systèmes avancés (scénario, gacha) plus tard

## **7.4 Scripts (Logique)** {#7.4-scripts-(logique)}

### CombatManager.gd {#combatmanager.gd}

* Contrôle le déroulement du combat  
* Gère l’alternance des tours (joueur / ennemi)  
* Applique les actions des cartes et des ennemis  
* Vérifie les conditions de victoire et défaite

### CardManager.gd {#cardmanager.gd}

* Gère la main du joueur  
* Gère la fusion automatique des cartes  
* Fournit les actions prêtes à exécuter au CombatManager

### EnemyAI.gd {#enemyai.gd}

* Définit le comportement des ennemis  
* Calcule les actions de l’ennemi pour chaque tour

## **7.5 Scènes (Affichage)** {#7.5-scènes-(affichage)}

### combat.tscn {#combat.tscn}

* Affiche la scène de combat  
* Contient les nodes pour :  
  * Héros  
  * Ennemi  
  * Main de cartes  
  * Feedback joueur (dégâts, effets)  
* Reçoit les informations de CombatManager pour mettre à jour l’affichage

### Avantages {#avantages}

* Séparation totale entre données, logique et affichage  
* Permet de tester la logique indépendamment de l’UI  
* Facilite l’ajout de nouveaux types de cartes, héros ou ennemis

## **7.6 Bonnes pratiques techniques** {#7.6-bonnes-pratiques-techniques}

1. **Pas de logique dans les scènes**  
   * Les scènes ne font que représenter l’état actuel  
2. **Pas de données en dur dans les scripts**  
   * Tous les stats et valeurs doivent venir des Resources  
3. **Scripts modulaires**  
   * Chaque script gère une seule responsabilité  
4. **Extensible**  
   * Ajouter un nouveau héros ou une nouvelle carte ne nécessite pas de modifier la logique existante  
5. **Testable**  
   * La logique peut être testée via des scènes de test ou des scripts de test unitaires 

# **8\. Interface utilisateur (UI)** {#8.-interface-utilisateur-(ui)}

L’UI est strictement séparée de la logique et des données. Elle sert uniquement à **représenter l’état du jeu** et à permettre les interactions du joueur.

## **8.1 Interface de combat** {#8.1-interface-de-combat}

La scène de combat (combat.tscn) contient les éléments suivants :

1. **Zone du héros**  
   * Affiche le héros principal et ses points de vie (current\_hp / max\_hp)  
   * Affiche la jauge d’ultime (futur)  
2. **Zone de l’ennemi**  
   * Affiche l’ennemi avec ses points de vie  
3. **Zone de la main**  
   * Affiche les cartes disponibles pour le tour  
   * Les cartes sont cliquables et déplaçables (pour la sélection et la fusion)  
4. **Zone de feedback**  
   * Affiche les dégâts infligés  
   * Affiche les effets appliqués (buff, debuff, ultimes, futur)

**Recommandations :**

* Utiliser des Control Nodes (HBoxContainer / VBoxContainer) pour organiser les éléments  
* Éviter toute logique de calcul dans l’UI  
* L’UI reçoit uniquement les informations depuis CombatManager et CardManager

## **8.2 Affichage des cartes** {#8.2-affichage-des-cartes}

### Main du joueur {#main-du-joueur}

* La main est un container horizontal qui affiche les cartes disponibles  
* Chaque carte est un node individuel (CardUI)  
* Les cartes contiennent :  
  * Nom  
  * Rang  
  * Icône (future extension)

### Sélection {#sélection-1}

* Le joueur peut cliquer sur une carte pour la jouer  
* Les cartes sélectionnées apparaissent dans un ordre d’exécution visible  
* Les cartes adjacentes peuvent fusionner automatiquement, et l’UI doit refléter la nouvelle carte fusionnée

### Recommandations {#recommandations}

* Utiliser des Button ou TextureButton pour chaque carte  
* Éviter la logique de fusion dans l’UI : afficher seulement le résultat calculé par CardManager

## **8.3 Feedback joueur** {#8.3-feedback-joueur}

Le feedback permet au joueur de comprendre immédiatement les conséquences de ses actions.

### Types de feedback {#types-de-feedback}

* Dégâts infligés (chiffre flottant ou animation simple)  
* Dégâts reçus  
* Fusion de cartes (animation simple \+ mise à jour de la carte)  
* Ultime disponible (futur)  
* Statut des personnages (points de vie, buffs, debuffs)

### Recommandations {#recommandations-1}

* Feedback visuel simple et lisible  
* Éviter la surcharge graphique dans le MVP  
* Tout feedback doit être déclenché par la logique (CombatManager / CardManager), pas par l’UI elle-même

# **9\. Système de progression (hors MVP)** {#9.-système-de-progression-(hors-mvp)}

Le système de progression est prévu pour enrichir la profondeur du jeu après le MVP. Il permet de donner au joueur une **sensation de progression**, d’amélioration et de stratégie sur le long terme.

## **9.1 Amélioration des personnages** {#9.1-amélioration-des-personnages}

Chaque héros peut évoluer et devenir plus puissant au fil du temps.

### Mécaniques prévues {#mécaniques-prévues}

* **Points d’expérience (XP)**  
  * Gagnés après chaque combat  
  * Débloque des niveaux supérieurs pour le héros  
* **Augmentation de statistiques**  
  * PV maximum (max\_hp)  
  * Attaque (attack)  
  * (Futur) Défense, vitesse, autres stats  
* **Déblocage de nouvelles capacités**  
  * Cartes spéciales ou ultimes  
* **Personnalisation**  
  * Changement d’équipement (futur)  
  * Apparence des héros (skins ou évolution visuelle)

### Contraintes {#contraintes-1}

* Les améliorations doivent être persistantes entre les combats  
* Doivent rester simples pour ne pas surcharger le MVP  
* Les calculs sont effectués côté logique, pas dans l’UI

## **9.2 Déblocage de cartes** {#9.2-déblocage-de-cartes}

Les cartes ne sont pas toutes disponibles dès le début. Le joueur peut **débloquer de nouvelles cartes** selon différents critères.

### Mécaniques prévues {#mécaniques-prévues-1}

* Déblocage via **progression du héros** (niveau atteint)  
* Déblocage via **événements narratifs** ou quêtes (futur)  
* Cartes rares ou spéciales pour enrichir la stratégie

### Conséquences gameplay {#conséquences-gameplay-1}

* Encourage l’adaptation de la main selon les cartes disponibles  
* Permet d’introduire de nouvelles mécaniques sans complexifier le système de base  
* Prépare le terrain pour les systèmes de deck plus avancés

## **9.3 Difficulté** {#9.3-difficulté}

La difficulté doit évoluer avec la progression du joueur pour maintenir un **défi constant**.

### Mécaniques prévues {#mécaniques-prévues-2}

* Augmentation des statistiques des ennemis  
* Introduction de cartes ennemies plus puissantes  
* Introduction d’ennemis avec IA plus complexe  
* (Futur) Modificateurs de combat ou événements aléatoires

### Objectifs {#objectifs}

* Garder les combats intéressants même pour des joueurs avancés  
* Encourager l’utilisation stratégique des cartes et de la fusion  
* Préparer la progression narrative et la montée en puissance des héros 

# **10\. Système narratif (inspiration Undertale)** {#10.-système-narratif-(inspiration-undertale)}

Le système narratif est prévu pour enrichir l’expérience de jeu et donner **du poids aux choix du joueur**, mais il est hors MVP. Il s’inspire de *Undertale* et repose sur des flags persistants pour suivre les décisions du joueur.

## **10.1 Système de choix** {#10.1-système-de-choix}

Le joueur peut être confronté à des choix qui affectent l’histoire ou le déroulement des combats.

### Exemples de choix {#exemples-de-choix}

* Épargner ou attaquer un ennemi  
* Accepter ou refuser une quête / événemen  
* Décider de fusionner ou non des cartes dans certains contextes (futur)

### Fonctionnement {#fonctionnement-1}

* Les choix sont présentés via l’UI (boutons ou dialogue)  
* Le choix sélectionné est enregistré dans un **système de gestion des flags**  
* La logique du jeu peut ensuite lire ces flags pour adapter les dialogues, les combats ou les récompenses

## **10.2 Flags persistants** {#10.2-flags-persistants}

Les flags sont des variables booléennes ou numériques qui suivent les actions du joueur.

### Exemples de flags {#exemples-de-flags}

* enemy\_spared : vrai si un ennemi a été épargné  
* quest\_completed : nombre de quêtes accomplies  
* hero\_level : niveau du héros (impactant sur le scénario futur)  
* card\_used\_count : compteur d’actions pour débloquer l’ultime (futur)

### Gestion {#gestion}

* Les flags sont stockés dans un **DataManager** ou dans des fichiers de sauvegarde  
* Ils sont persistants entre les scènes et les sessions de jeu  
* Le système doit pouvoir les lire et les modifier à tout moment

## **10.3 Impact sur le jeu** {#10.3-impact-sur-le-jeu}

Les choix du joueur influencent :

1. **Les dialogues et événements**  
   * Différents dialogues selon les flags  
   * Réactions des personnages en fonction des actions précédentes  
2. **Les combats (futur)**  
   * Des ennemis peuvent apparaître ou disparaître selon les choix  
   * Les récompenses ou la difficulté peuvent varier  
3. **La fin du jeu**  
   * Les choix cumulés déterminent la fin narrative  
   * Possibilité d’avoir plusieurs fins

### Objectifs {#objectifs-1}

* Renforcer l’immersion narrative  
* Offrir des conséquences visibles aux actions du joueur  
* Préparer l’ajout de mécaniques plus complexes (quêtes, multiple héros, scénarios alternatifs) 

# **11\. Système de collection / Gacha (hors MVP)** {#11.-système-de-collection-/-gacha-(hors-mvp)}

Le système de collection et de type **gacha** est prévu pour enrichir l’expérience sur le long terme. Il permet au joueur de débloquer et collectionner de nouveaux héros, influençant la stratégie et la rejouabilité. Ce système est **hors MVP**.

## **11.1 Invocation de personnages** {#11.1-invocation-de-personnages}

L’invocation est le mécanisme principal pour obtenir de nouveaux héros.

### Fonctionnement {#fonctionnement-2}

* Le joueur dépense une ressource (ex : cristaux, tickets, futur monnaie premium) pour invoquer un héros  
* Chaque invocation est aléatoire mais pondérée selon la rareté des héros  
* Les héros obtenus sont automatiquement ajoutés à la collection du joueur

### Étapes {#étapes}

1. Déclenchement de l’invocation via l’UI  
2. Sélection aléatoire d’un héros dans le pool disponible  
3. Ajout du héros à la collection  
4. Notification au joueur et mise à jour de la base de données interne

## **11.2 Rareté** {#11.2-rareté}

Chaque héros est défini par un **nombre d’étoiles** de 2 à 6, représentant sa puissance et son rang initial.

### **Correspondance étoiles → grade** {#correspondance-étoiles-→-grade}

| étoiles | grades |
| :---- | :---- |
| 2 | C |
| 3 | B |
| 4 | A |
| 5 | S |
| 6 | SS |

### Impacts {#impacts}

* Probabilité d’obtention dans l’invocation (2★ plus fréquents que (5★) (les personnages 6 étoiles ne peuvent pas etre obtenue en gacha)  
* Statistiques initiales plus ou moins élevées selon le grade  
* Les héros avec plus d’étoiles peuvent disposer d’ultimes plus puissants


### Recommandation {#recommandation-1}

* Stocker la rareté dans la Resource HeroData  
* Gérer la pondération dans un script séparé GachaManager.gd  
* Ne pas affecter le MVP, mais préparer l’architecture pour l’ajout futur

## **11.3 Gestion de collection** {#11.3-gestion-de-collection}

La collection permet au joueur de voir et gérer tous les héros acquis.

### Fonctionnalités prévues {#fonctionnalités-prévues}

* **Visualisation** : liste des héros avec stats et rareté  
* **Tri / filtre** : par rareté, niveau, type  
* **Sélection pour le combat** : choisir quels héros intégrer dans l’équipe  
* **Évolution / amélioration** : possibilité de renforcer les héros existants

### Contraintes techniques {#contraintes-techniques-3}

* La collection est persistante et sauvegardée entre les sessions  
* La logique doit être séparée de l’UI  
* L’UI se contente de **représenter la collection et permettre les interactions**

# **12\. Scope du MVP** {#12.-scope-du-mvp}

Le MVP définit ce qui **doit être implémenté et jouable** pour valider les mécaniques de base, et ce qui peut être repoussé pour les extensions futures.

## **12.1 Fonctionnalités incluses** {#12.1-fonctionnalités-incluses}

Ces fonctionnalités seront implémentées et testables dans le MVP :

* **Système de combat**  
  * Tour par tour  
  * Gestion des actions limitées par tour  
  * Conditions de victoire/défaite  
* **Système de cartes**  
  * Cartes de dégâts (rang 1 à 3\)  
  * Fusion automatique de cartes adjacentes  
  * Limite de cartes jouables par tour  
* **Entités du jeu**  
  * Héros et ennemis avec statistiques de base (HP, attaque)  
  * Gestion de la main et cartes jouées  
* **Interface utilisateur (UI)**  
  * Affichage des héros, ennemis et main de cartes  
  * Feedback simple pour dégâts et fusion  
* **Architecture technique**  
  * Séparation claire entre Data (Resources), logique (Scripts) et UI (Scenes)  
  * Logiciel extensible pour intégrer ultérieurement ultimes, progression, gacha et système narratif

## **12.2 Fonctionnalités exclues (hors MVP)** {#12.2-fonctionnalités-exclues-(hors-mvp)}

Ces fonctionnalités seront planifiées pour plus tard et **ne seront pas implémentées dans le MVP** :

* Système d’ultime / jauge d’énergie  
* Cartes de soin, buffs, debuffs ou effets spéciaux  
* Progression des héros (XP, niveau, amélioration)  
* Déblocage de cartes avancées  
* Difficulté évolutive complète  
* Système narratif basé sur flags et choix  
* Gacha complet :  
  * Les personnages 6★ ne sont pas obtenables en gacha  
  * Système d’éveil  
* Extensions UI avancées (animations complexes, effets visuels spéciaux)  
* Gestion de collection complète et tri par grade/étoiles

## **12.3 Critères de validation** {#12.3-critères-de-validation}

Le MVP sera considéré comme **valide** lorsque les conditions suivantes sont remplies :

1. Le joueur peut lancer un combat et jouer des cartes de manière fluide  
2. Les cartes peuvent fusionner automatiquement selon les règles définies  
3. Les actions du joueur sont limitées par tour et exécutées correctement  
4. Les points de vie des héros et ennemis sont correctement mis à jour  
5. L’UI reflète l’état du combat et les changements des cartes  
6. La logique reste stable et séparée des données et de l’UI 

# **13\. Roadmap de développement** {#13.-roadmap-de-développement}

La roadmap définit les **phases de développement** pour structurer le projet, du MVP jusqu’aux extensions futures.

## **13.1 Phase 1 : Combat de base (MVP)** {#13.1-phase-1-:-combat-de-base-(mvp)}

Objectif : Créer un prototype jouable avec les mécaniques essentielles.

### Tâches principales {#tâches-principales}

* Implémentation des entités : héros et ennemis avec stats de base  
* Mise en place du système de cartes :  
  * Cartes de dégâts (rang 1 à 3\)  
  * Limite de cartes jouables par tour  
  * Fusion automatique des cartes adjacentes  
* Développement du système de combat tour par tour  
* Création de l’UI de combat simple :  
  * Affichage des héros et ennemis  
  * Affichage de la main de cartes  
  * Feedback simple pour dégâts et fusion  
* Tests unitaires basiques pour vérifier les mécaniques

**Livrable** : Prototype jouable où le joueur peut combattre et fusionner des cartes, avec feedback visuel et logique stable.

## **13.2 Phase 2 : Améliorations (post-MVP)** {#13.2-phase-2-:-améliorations-(post-mvp)}

Objectif : Ajouter des fonctionnalités de progression et enrichir le gameplay.

### **Tâches principales** {#tâches-principales-1}

* Implémentation du système d’ultime / jauge de charge  
* Ajout de cartes de soin, buffs, debuffs, et effets spéciaux  
* Déblocage de cartes via progression des héros  
* Amélioration de l’UI : animations de cartes et effets visuels  
* Gestion des statistiques évolutives des héros (XP, niveaux, amélioration)  
* Difficulté dynamique selon la progression

**Livrable** : Combat plus riche et stratégique, avec progression des héros et cartes variées.

## **13.3 Phase 3 : Extensions (hors MVP / long terme)** {#13.3-phase-3-:-extensions-(hors-mvp-/-long-terme)}

Objectif : Ajouter les fonctionnalités narratives et de collection qui augmentent la rejouabilité.

### **Tâches principales** {#tâches-principales-2}

* Intégration du système narratif :  
  * Flags persistants  
  * Choix du joueur influençant le scénario et la fin  
* Implémentation du système de collection / gacha :  
  * Invocation de héros  
  * Système d’étoiles (2★ à 6★, avec correspondance C → SS)  
  * Gestion de la collection et tri  
* Mise en place des extensions avancées :  
  * Éveil des personnages  
  * Scénarios alternatifs et événements aléatoires  
* Optimisation de l’UI et ajout d’animations complexes

**Livrable** : Jeu complet avec progression narrative et collection, rejouable et évolutif.

# **14\. Contraintes et bonnes pratiques** {#14.-contraintes-et-bonnes-pratiques}

Cette section définit les **principes de développement et les contraintes techniques** pour garantir que le projet reste maintenable, modulable et évolutif.

## **14.1 Clean Code** {#14.1-clean-code}

Le code doit être **lisible, compréhensible et maintenable**.

### Recommandations {#recommandations-2}

* **Nommer clairement** les variables, fonctions et classes  
* **Éviter les fonctions trop longues** : chaque fonction doit avoir une seule responsabilité  
* **Commenter uniquement lorsque nécessaire** : expliquer le *pourquoi*, pas le *quoi*  
* **Respecter la séparation logique** :  
  * Logiciel de combat et gestion de cartes → Scripts de logique  
  * Données statiques → Resources  
  * Affichage et interactions → Scenes / UI

### Objectif {#objectif}

* Faciliter la maintenance et la collaboration  
* Prévenir les bugs liés à la complexité et aux dépendances

## **14.2 Modularité** {#14.2-modularité}

Le projet doit être conçu pour que chaque composant soit **autonome et réutilisable**.

### Principes {#principes}

* Chaque système gère une seule responsabilité :  
  * CombatManager → gestion des tours et actions  
  * CardManager → gestion de la main et des fusions  
  * EnemyAI → comportement des ennemis  
* Les scripts ne dépendent pas de l’UI ni des autres scripts  
* Les Resources contiennent uniquement les données et restent indépendantes de la logique

### Avantages {#avantages-1}

* Facilite l’ajout ou la modification d’un système sans affecter les autres  
* Permet d’évoluer vers des extensions complexes sans casser le MVP

## **14.3 Scalabilité** {#14.3-scalabilité}

Le jeu doit pouvoir **grandir et s’enrichir** facilement sans refondre l’architecture.

### Recommandations {#recommandations-3}

* Utiliser des **Resources pour les données** afin d’ajouter de nouveaux héros, cartes ou ennemis facilement  
* Concevoir la logique pour **accepter de nouvelles mécaniques** (ultimes, buffs, effets spéciaux)  
* Prévoir des **interfaces et points d’extension** pour ajouter :  
  * Nouveaux types de cartes  
  * Nouvelles entités  
  * Nouveaux événements narratifs  
  * Système de collection et Gacha

### Objectif {#objectif-1}

* Permettre au MVP de rester stable  
* Faciliter l’évolution vers le jeu complet avec progression, collection et scénario sans réécrire toute la logique

