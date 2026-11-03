# Changelog

Toutes les modifications notables de **Blackjack Royale** sont documentées dans ce fichier.

## [v1.0.0] - 2026-11-03

### Ajouté
- Moteur complet de Blackjack Casino (Sabot 1/2/6/8 paquets, Blackjack 3:2, S17/H17, Tirer, Rester, Doubler ×2, Séparer les paires en 2 mains indépendantes, Assurance 2:1, Abandon ½ mise).
- Mises latérales optionnelles (**Perfect Pairs** jusqu'à `25:1` et **21+3 Poker** jusqu'à `100:1`).
- **Coach Stratégie de Base** en temps réel et **Compteur de cartes Hi-Lo** (`Running Count` & `True Count`).
- Rendu vectoriel sur mesure (`CustomPainter`) pour le tapis de feutre émeraude, les cartes à jouer illustrées et les jetons de casino (`5 $`, `25 $`, `100 $`, `500 $`, `1 000 $`).
- Panneaux modaux **Statistiques & Courbe de Bankroll** et **Matrice de Stratégie de Base & Réglages du Sabot**.
- Pipeline CI/CD GitHub Actions (`build-apk.yml`) compilant et publiant l'APK Android Release sur GitHub Releases.
