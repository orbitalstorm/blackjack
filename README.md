# Blackjack Royale (`v1.0.0`)

Application Android **Flutter** de Blackjack Casino haute précision (**Portrait 1080×2400**, mode immersif plein écran).

## 📦 Téléchargement direct de l'APK Android (`v1.0.0`)

- **[Télécharger `blackjack-royale-v1.0.0.apk`](https://github.com/orbitalstorm/blackjack/releases/download/v1.0.0/blackjack-royale-v1.0.0.apk)**
- **[Télécharger `blackjack-v1.0.0.apk`](https://github.com/orbitalstorm/blackjack/releases/download/v1.0.0/blackjack-v1.0.0.apk)**
- **[Page GitHub Release `v1.0.0`](https://github.com/orbitalstorm/blackjack/releases/tag/v1.0.0)**

---

## ✨ Fonctionnalités Principales

1. **Moteur de Blackjack Casino Authentique**
   - **Sabot multi-paquets configurable** (`1`, `2`, `6` ou `8` paquets de 52 cartes) avec remélange automatique à la carte de coupe.
   - **Blackjack Naturel payé 3:2** (`1.5×` la mise).
   - **Règle du Croupier configurable** : **S17** (*Le croupier reste sur tous les 17*, par défaut) ou **H17** (*Le croupier tire sur 17 souple As-6*).
   - **Actions complètes du joueur** :
     - **TIRER (`HIT`)** : recevoir une carte supplémentaire.
     - **RESTER (`STAND`)** : conserver sa main.
     - **DOUBLER (`DOUBLE DOWN ×2`)** : doubler la mise sur 2 cartes et recevoir exactement 1 carte.
     - **SÉPARER (`SPLIT`)** : séparer une paire en **2 mains indépendantes** jouées séquentiellement avec halo doré sur la main active.
     - **ASSURANCE (`INSURANCE 2:1`)** : proposée lorsque la carte visible du croupier est un As.
     - **ABANDON (`SURRENDER ½`)** : récupérer la moitié de sa mise initiale sur une main défavorable.

2. **Mises Latérales Casino (`Side Bets`)**
   - **Perfect Pairs** : Paire Mixte (`5:1`), Paire Colorée (`12:1`), Paire Parfaite (`25:1`).
   - **21+3 Poker** (2 cartes du joueur + carte visible du croupier) : Couleur/Flush (`5:1`), Suite (`10:1`), Brelan (`30:1`), Quinte Flush (`40:1`), Brelan Parfait (`100:1`).

3. **Coach Stratégie de Base en Temps Réel & Compteur de Cartes Hi-Lo**
   - **Conseiller Mathématique Temps Réel** : recommande à chaque coup l'action optimale (`TIRER`, `RESTER`, `DOUBLER`, `SÉPARER`, `ABANDON`) selon la matrice probabiliste face à la carte visible du croupier.
   - **Compteur Hi-Lo intégré** : affiche en direct le **Running Count (`RC`)** et le **True Count (`TC`)** rapporté au nombre de paquets restants dans le sabot.
   - **Matrice Complète de Stratégie de Base** consultable à tout moment (Mains Dures, Mains Souples avec As, Paires).

4. **Suivi Statistique & Courbe de Bankroll**
   - Graphique vectoriel d'évolution de la Bankroll (`2 500 $` initiaux + recharge cave gratuite `+1 000 $`).
   - Statistiques détaillées (Taux de victoire, Blackjacks 3:2, Plus gros gain, Bilan net, Historique complet main par main).
