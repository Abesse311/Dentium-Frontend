# Cabinet Dentaire — Application de Gestion de Cabinet (Flutter Desktop)

Application Flutter Desktop professionnelle pour la gestion complète d'un cabinet dentaire solo (mono-praticien, réseau local).

L'application communique directement avec le backend local FastAPI (`http://127.0.0.1:8000`) et base de données SQLite.

---

## 🚀 Démarrage Rapide

### 1. Prérequis
- **Flutter SDK** (version 3.19+ ou 3.24+)
- **Backend FastAPI** actif et démarré sur `http://127.0.0.1:8000`

> ⚠️ **Important** : Le backend FastAPI doit être démarré en premier. Si le backend est éteint, l'application Flutter affichera un témoin rouge *"🔴 Serveur déconnecté"* dans l'en-tête avec un bouton d'actualisation instantanée.

### 2. Démarrer le Backend (Rappel)
Dans le dossier du backend :
```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```
La documentation Swagger interactive sera accessible sur `http://127.0.0.1:8000/docs`.

### 3. Installer les dépendances & Lancer le Frontend Flutter Desktop

Dans le dossier `flutter_application_1` :
```bash
# Télécharger les packages
flutter pub get

# Lancer sous Windows Desktop
flutter run -d windows

# Ou sous macOS Desktop
flutter run -d macos

# Ou sous Linux Desktop
flutter run -d linux
```

---

## 🏛️ Architecture du Projet

Le frontend suit une architecture modulaire et découplée en couches :

```
lib/
├── main.dart                          # Point d'entrée, initialisation Locale fr_FR et GetMaterialApp
├── core/
│   ├── api/
│   │   └── api_client.dart            # Singleton Dio (127.0.0.1:8000), timeouts et gestion d'erreurs en français
│   ├── constants/
│   │   ├── app_colors.dart            # Tokens de design (Teal médical, Slate, Couleurs sémantiques)
│   │   ├── app_constants.dart         # Base URL, routes d'API, métadonnées
│   │   └── status_labels.dart         # Centralisation des traductions des statuts anglais -> français
│   ├── routes/
│   │   └── app_routes.dart            # Configuration des routes GetX
│   └── utils/
│       └── date_formatter.dart        # Formatage des dates et montants (DA / DZD) via intl (fr_FR)
├── data/                              # Services d'API isolés (aucun appel direct dans les widgets)
│   ├── appointments_api.dart
│   ├── dashboard_api.dart
│   ├── invoices_api.dart
│   ├── patients_api.dart
│   └── settings_api.dart
├── controllers/                       # Contrôleurs réactifs GetX (.obs)
│   ├── appointments_controller.dart
│   ├── connectivity_controller.dart   # Vérification de santé du backend en temps réel
│   ├── dashboard_controller.dart
│   ├── invoices_controller.dart
│   ├── navigation_controller.dart     # Gestion du menu latéral et onglets
│   ├── patients_controller.dart
│   ├── settings_controller.dart
│   └── treatments_controller.dart
├── models/                            # Classes de données typées avec sérialisation JSON
│   ├── appointment_model.dart
│   ├── clinic_settings_model.dart
│   ├── dashboard_metrics_model.dart
│   ├── day_capacity_model.dart
│   ├── invoice_item_model.dart
│   ├── invoice_model.dart
│   ├── patient_invoice_model.dart
│   ├── patient_model.dart
│   ├── patient_treatment_model.dart
│   ├── payment_model.dart
│   ├── treatment_model.dart
│   └── treatment_type_model.dart
├── screens/
│   ├── appointments/                  # Module Rendez-vous (Planning hebdo + capacité + actions rapides)
│   ├── dashboard/                     # Module Tableau de bord (KPIs du matin + agenda du jour)
│   ├── invoices/                      # Module Factures & Règlements (Création, encaissement, détail)
│   ├── patients/                      # Module Patients (Répertoire, alertes médicales, historiques)
│   ├── settings/                      # Module Paramètres (Infos cabinet, limite journalière, catalogue)
│   ├── shell_screen.dart              # Coquille principale Desktop (Sidebar + Header + Contenu)
│   └── treatments/                    # Module Odontogramme (Schéma dentaire 32 dents FDI 11-48)
├── theme/
│   └── app_theme.dart                 # Thème médical desktop, typographie Outfit/Inter, inputs & dialogs
└── widgets/
    ├── app_header.dart                # En-tête avec date française et voyant d'état du serveur
    ├── app_sidebar.dart               # Menu de navigation latéral rétractable
    ├── empty_state.dart               # Composant d'état vide réutilisable
    ├── search_input.dart              # Barre de recherche avec debounce
    └── status_badge.dart              # Badge de statut sémantique avec libellé français
```

---

## 🦷 Modules & Fonctionnalités

### 1. Tableau de bord (Dashboard)
- **Indicateurs clés du matin** : Patients prévus aujourd'hui, Taux de réalisation, Recettes encaissées du jour, Soins planifiés en attente de programmation.
- **Agenda du jour** : Liste des consultations de la journée avec actions rapides en 1 clic (*Terminé* / *Absent*).
- **Raccourcis rapides** : Boutons d'accès direct pour ajouter un patient, fixer un rendez-vous ou facturer.

### 2. Répertoire des Patients
- **Master-Detail Desktop** : Recherche en temps réel avec debounce par nom et numéro de téléphone.
- **Alerte Médicale & Antécédents** : Bannière d'avertissement proéminente en ambre/rouge pour les allergies (pénicilline, anesthésie) et pathologies critiques (diabète, hypertension).
- **Fiche patient complète** : Coordonnées, date de naissance, âge calculé automatiquement, historique complet des actes et factures.
- **Formulaire modal** : Création et modification de dossier patient avec validation en français.

### 3. Rendez-vous & Planning Journalier
- **Modèle simplifié par date** : Gestion directe des dates sans créneaux horaires rigides.
- **Bandeau de capacité hebdomadaire** : Visualisation du lundi au dimanche avec code couleur de taux de remplissage :
  - 🟢 **Vert** : Moins de 50% de la capacité journalière
  - 🟠 **Orange / Ambre** : 50% à 80%
  - 🔴 **Rouge** : Plus de 80%
- **Avertissement non-bloquant** : Dialogue de confirmation informatif si la limite conseillée est atteinte, permettant toujours au praticien de valider la réservation.
- **Actions rapides** : Boutons d'état *Terminé*, *Absent*, ou *Annuler*.

### 4. Schéma Dentaire Interactif (Odontogramme FDI 11–48)
- **Visualisation anatomique des 32 dents** : Rendu vectoriel précis (`CustomPainter`) pour molaires, prémolaires, canines et incisives, séparé par quadrants FDI (Maxillaire Q1/Q2 et Mandibule Q4/Q3).
- **Coloration réactive de chaque dent** :
  - ⚪ **Sain / Neutre** : Aucune intervention
  - 🔵 **Planifié** : Soin futur à programmer
  - 🟠 **En cours** : Traitement en cours de réalisation
  - 🟢 **Réalisé** : Acte complété et soigné
- **Inspecteur de dent** : Panneau latéral affichant l'anatomie exacte (ex: *"Dent 16 — 1ère Molaire Supérieure Droite"*), l'historique complet des interventions sur cette dent et un bouton direct *"Ajouter un acte"*.
- **Soins généraux** : Section dédiée pour les actes non rattachés à une dent (Consultations, Détartrage global).

### 5. Factures & Règlements
- **Génération depuis les actes** : Création de factures en cochant les actes réalisés du patient avec calcul automatique du total.
- **Enregistrement des encaissements** : Saisie de règlements partiels ou complets avec sélection du mode de paiement (*Espèces*, *Carte bancaire*, *Virement*, *Autre*).
- **Cycle de vie du statut** : Mise à jour automatique (*Non payée* → *Partiellement payée* → *Payée*).
- **Bouton d'export PDF** : Emplacement réservé et commenté pour la future phase d'impression.

### 6. Paramètres & Configuration
- **Informations de la structure** : Nom du cabinet, nom du praticien, téléphone, adresse.
- **Capacité journalière conseillée** : Seuil numérique indicatif (par défaut 30) paramétrable avec mention explicative.
- **Catalogue des Actes** : Gestion complète (CRUD) des types de soins et de leurs tarifs par défaut en DA.

---

## 🛠️ Stack Technique & Bibliothèques

| Usage | Package | Rôle |
|---|---|---|
| **State Management & Routing** | `get: ^4.7.2` | Contrôleurs réactifs `.obs`, navigation, injection de dépendances |
| **Client HTTP** | `dio: ^5.8.0+1` | Requêtes HTTP vers `127.0.0.1:8000`, intercepteurs, timeouts |
| **Dates & Nombres** | `intl: ^0.20.2` | Formatage en français (`fr_FR`), dates et montants en DA |
| **Typographie** | `google_fonts: ^6.2.1` | Polices modernes `Outfit` et `Inter` |
| **Animations & Fluidité** | `flutter_animate: ^4.5.2` | Micro-interactions et transitions douces |
| **Composants Calendrier** | `table_calendar: ^3.1.3` | Outils de calendrier |
