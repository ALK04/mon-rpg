# CLAUDE.md — mon-rpg



## Présentation du projet



RPG tour par tour à système de cartes, développé en **Godot 4** (GDScript).

Inspiré de *The Seven Deadly Sins: Grand Cross*, *Honkai Star Rail* et *Undertale*.



**Mécanique centrale** : le joueur gère une main de 5 cartes et sélectionne 3 actions par tour. Des cartes adjacentes identiques au même rang **fusionnent automatiquement** pour former une carte de rang supérieur, forçant des choix stratégiques sur l'ordre de jeu.



Le document de référence complet est dans `docs/GAME DESIGN DOCUMENT.md`.



---



## Architecture du projet



### Séparation stricte Data / Logique / UI



```

data/       → Resources Godot (définitions immuables, sérialisables)

logic/      → Scripts GDScript purs (état de jeu, règles, calculs)

ui/         → Scènes .tscn + contrôleurs UI

docs/       → Documentation (GDD, notes de design)

```



### Couche Data (`data/`)



| Fichier | Classe | Rôle |

|---|---|---|

| `card_data.gd` | `CardData` (Resource) | Définition d'une carte (id, effets, coût, cible, rareté) |

| `entity_stats.gd` | `EntityStats` (Resource) | Stats d'un héros ou ennemi (hp, attaque, énergie, portrait) |

| `encounter_data.gd` | `EncounterData` (Resource) | Configuration d'un combat (équipes, deck de départ, taille de main) |



Les ressources `.tres` dans `data/cards/`, `data/entities/` et `data/test/` sont des instances de ces classes.



### Couche Logique (`logic/`)



| Fichier | Classe | Rôle |

|---|---|---|

| `card_effect.gd` | `CardEffect` (Resource) | Définition d'un effet de carte (type, valeurs par rang, durée) |

| `card_instance.gd` | `CardInstance` (RefCounted) | Wrapper runtime d'une `CardData` avec un rang mutable (1–3) |

| `damage_service.gd` | `DamageService` (static) | Calcul des dégâts via `CardEffect.DAMAGE`, fallback sur `damage_by_rank` |

| `hand_fusion_service.gd` | `HandFusionService` (static) | Fusion automatique des cartes adjacentes identiques au même rang |

| `battle_service.gd` | `BattleService` (RefCounted) | Source de vérité unique de l'état de combat, résolution des tours |



`BattleService` émet trois signaux :

- `state_updated` — déclenche un `_refresh_ui()` dans la scène

- `battle_finished(result_text)` — fin de combat

- `battle_event(text)` — événement journal (attaque, soin, buff, debuff, poison, etc.)



### Couche UI (`ui/`)



| Fichier | Rôle |

|---|---|

| `battle_scene.tscn` | Scène principale de combat |

| `battle_scene.gd` | Contrôleur MVC : écoute `BattleService`, reconstruit l'UI à chaque `state_updated` |

| `battle_view.gd` | Composant de vue simple (labels noms héros/ennemi) |



---



## Règles du système de combat (MVP)



1. **Initialisation** : `BattleService.start_battle()` lit un `EncounterData` et initialise l'état.

2. **Tour joueur** :

   - La main contient jusqu'à 5 `CardInstance`.

   - Le joueur sélectionne jusqu'à 3 cartes → elles entrent dans `action_slots[]`.

   - `execute_turn()` résout les actions séquentiellement, puis déclenche le tour ennemi.

3. **Fusion** : `HandFusionService.fuse_adjacent_until_stable()` tourne après chaque modification de la main. Deux cartes fusionnent si elles sont adjacentes, ont le même `id`, le même rang, et ne sont pas déjà au `max_rank`.

4. **Dégâts** : `DamageService.compute_damage(card_instance, attacker_stats)` → `damage_by_rank[rank-1] + attack_stat`.

5. **Buffs** : attaque et défense avec durée en tours, décrémentés à chaque fin de tour.

6. **Fin** : victoire si tous les ennemis tombent à 0 PV, défaite si tous les héros tombent à 0 PV.



### Système d'effets data-driven (`CardEffect`)

`CardData` expose `effects: Array[CardEffect]`. Chaque `CardEffect` déclare :
- `effect_type: EffectType` (DAMAGE, HEAL, POISON, WEAKEN, ATK_BUFF, DEF_BUFF)
- `value_by_rank: PackedInt32Array` — valeurs aux rangs 1/2/3
- `duration: int` — nombre de tours (0 = instantané)

`BattleService._execute_player_action()` boucle sur `card.data.effects` et appelle `_apply_effect()` pour chaque entrée — **plus de hardcoding par `card_id`**.

### Ciblage manuel (`pending_target_slot_index`)

Les cartes `SINGLE_ENEMY` et `ALLY_SINGLE` déclenchent un état d'attente :
- `is_waiting_for_target() -> bool`
- `get_pending_target_type() -> CardData.TargetType`
- `confirm_target(index: int) -> bool` — retourne `true` quand plus aucune cible n'est en attente
- L'UI surligne les cibles valides et bloque "Fin de tour" tant que la confirmation est manquante.



---



## Conventions de code



- **GDScript uniquement** — pas de C#, pas de modules natifs.

- **Resources pour les données** : toute donnée de jeu (carte, héros, ennemi, rencontre) est une `Resource` sérialisée en `.tres`.

- **Services statiques** pour la logique sans état (`DamageService`, `HandFusionService`).

- **`BattleService` est la seule source de vérité** pour l'état du combat — l'UI ne stocke aucune donnée de jeu, elle lit uniquement depuis `BattleService`.

- **Signaux pour la communication UI ↔ Logique** — jamais d'appel direct de l'UI vers la logique en dehors de `BattleService`.

- Les noms de fichiers et de classes suivent le **snake_case** pour les fichiers, **PascalCase** pour les classes.



---



## 📋 État des Travaux (Active Tasks)

### ✅ Terminé récemment
- [x] **Système de Debuff Ennemi** : `card_weaken.tres` — réduit les dégâts ennemis de 30% pendant 2 tours. Statut affiché sur la barre HP ennemi (`⬇ affaibli`). Remplace un Slash du Knight dans le deck.
- [x] **Système de DOT (Damage Over Time)** : `card_poison.tres` — poison croissant 2%/4%/6% HP max sur 3 tours, réapplicable. Statut affiché (`☠ poison`). Remplace Holy Burst (carte test) dans le deck.
- [x] **Journal de Combat** : signal `battle_event` dans `BattleService`, overlay scrollable avec bouton "Journal" (top-left), reset au replay. Tous les événements (attaques, soins, buffs, debuffs, poison) sont tracés.
- [x] **Refactoring des effets spéciaux** : nouveau `CardEffect` Resource (`logic/card_effect.gd`), `CardData.effects: Array[CardEffect]`, `BattleService` boucle sur les effets via `_apply_effect()` — plus de hardcoding par `card_id`. Toutes les cartes existantes migrées vers le nouveau système.
- [x] **Ciblage manuel unifié** : `pending_target_slot_index` + `confirm_target()` gèrent SINGLE_ENEMY et ALLY_SINGLE. L'UI surligne les cibles valides, bloque "Fin de tour" et l'auto-exécution tant qu'une confirmation est manquante.

### 🟡 Prochaines étapes (Backlog court terme)
- [ ] Ajout des barres de progression visuelles pour les buffs/debuffs sur l'UI.

### 🔴 Bugs connus / Points bloquants
- Aucun bug connu à ce jour.

---


## Roadmap (phases du GDD)



| Phase | Contenu |

|---|---|

| **Phase 1 (MVP)** | Combat de base — **terminé** |

| **Phase 2** | Ultimates, progression, plus de types de cartes |

| **Phase 3** | Gacha/collection, système narratif, hub monde |



---



## Points d'attention pour les futures modifications



- **Ajouter un nouveau type de carte** : créer un `.tres` dans `data/cards/`, y ajouter un ou plusieurs `SubResource` de type `CardEffect`, et si nécessaire étendre l'enum `EffectType` dans `card_effect.gd` + ajouter un cas dans `BattleService._apply_effect()`.

- **Ajouter un héros/ennemi** : créer un `.tres` dans `data/entities/`, l'associer dans un `EncounterData`.

- **Tests** : utiliser les ressources dans `data/test/` pour les combats de développement.