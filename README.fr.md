# Wealthy

[English](README.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md) · [हिन्दी](README.hi.md) · [Español](README.es.md) · [العربية](README.ar.md) · [Français](README.fr.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Русский](README.ru.md) · [Português](README.pt.md)

Wealthy est une application iPhone et iPad pour enregistrer dépenses, revenus et soldes des portefeuilles. La numérisation des reçus, les résumés des dépenses et l’IA sur l’appareil vous aident à examiner vos finances.

## Fonctionnalités

- Enregistrer revenus et dépenses par portefeuille et catégorie.
- Numériser les reçus, vérifier les détails et conserver les images originales.
- Consulter les opérations dans un calendrier et les dépenses par catégorie.
- Appliquer les opérations mensuelles récurrentes à l’ouverture de l’application.
- Interroger Apple Foundation Models sur vos données.
- Lire de courts conseils avec une touche d’humour, fondés sur les revenus, dépenses et actifs enregistrés.
- Exporter et restaurer les données financières, avec les images des reçus en option.
- Enregistrer les actifs et opérations dans plusieurs devises, avec des soldes séparés.


## Plusieurs devises

- L’application prend en charge **155 devises ISO 4217 actives**, d’après la liste SIX publiée le 2026-09-17.
- Au premier lancement, après le choix de la langue d’affichage, sélectionnez une ou plusieurs devises à activer. Dans **Accueil → Réglages**, modifiez les devises activées et choisissez la devise par défaut des nouvelles opérations.
- Les actifs et l’historique conservent la devise enregistrée pour chaque opération. Les soldes restent séparés et l’analyse permet de passer d’une devise activée à l’autre. Aucune conversion automatique n’est effectuée.
- Les montants sont stockés en unités mineures ISO : 0 décimale pour le JPY, 2 pour l’USD et 3 pour le KWD. Les anciennes opérations restent en JPY.
- L’OCR des reçus ne change pas : il cible les textes japonais et anglais et extrait automatiquement les montants entiers en JPY. Les montants en devise étrangère doivent être saisis et vérifiés manuellement.

## Moyens de paiement et cartes de points

Le reçu propose le portefeuille correspondant au moyen de paiement imprimé ; sans indication, les espèces sont utilisées. La confirmation débite le montant une seule fois. Un portefeuille absent est créé à zéro et devient négatif, par exemple `¥0 → ¥-1,200`. Modifier ou supprimer une opération ajuste son solde. Plusieurs moyens de paiement, des points utilisés ou plusieurs portefeuilles correspondants nécessitent une vérification manuelle. Ces règles exploitent le texte OCR ; leur précision sur des photos n’a pas été mesurée.

Dans **Portefeuilles**, modifiez un portefeuille créé automatiquement pour saisir son solde actuel, ou enregistrez un solde initial ajouté au solde enregistré. Les cartes de points comprennent un nom, un numéro de membre facultatif, un solde et une expiration facultative. Les points sont saisis manuellement, séparés des actifs monétaires et inclus dans les sauvegardes financières.

La synchronisation automatique avec les banques et services de paiement **n’est pas implémentée**. Les premières intégrations proposées sont SBI Shinsei Bank et DOCOMO SMTB Net Bank, anciennement SBI Sumishin Net Bank. Ouvrir une application bancaire ne permet pas de lire son solde ; un service agréé de partage de comptes est nécessaire. Consultez l’[étude d’intégration](Documentation/FinancialServiceIntegration.md).

## Conditions requises

**iOS ou iPadOS 26.0 ou ultérieur** et un **appareil compatible avec Apple Intelligence** sont nécessaires. Apple Intelligence doit être activé et son modèle système prêt avant d’utiliser l’application.

| Appareil | Matériel compatible |
| --- | --- |
| iPhone | iPhone 15 Pro / Pro Max, modèles iPhone 16 et ultérieurs, ou iPhone Air |
| iPad | Modèles avec M1 ou ultérieur, ou iPad mini avec A17 Pro |

Les restrictions de langue et de région d’Apple s’appliquent également. Wealthy vérifie la disponibilité du modèle au lancement et au retour au premier plan. Consultez les [conditions actuelles d’Apple](https://www.apple.com/apple-intelligence/).

## Utilisation

1. Activez Apple Intelligence dans **Réglages → Apple Intelligence et Siri** et attendez la préparation du modèle.
2. Choisissez parmi les **11 langues d’interface** dans la fenêtre du premier lancement. L’anglais est la langue par défaut et votre choix est conservé. Vous pouvez le modifier dans **Accueil → Réglages → Réglages de langue**. L’interface arabe s’affiche de droite à gauche.
3. Sélectionnez une ou plusieurs devises à activer. Vous pourrez ensuite modifier les devises actives et la devise par défaut des nouvelles opérations dans **Accueil → Réglages**.
4. Ajoutez un portefeuille et enregistrez un revenu ou numérisez un reçu. Vérifiez les détails avant l’enregistrement.
5. Consultez Calendrier et Analyse, ou ouvrez l’assistant IA pour poser des questions sur vos données.

Les langues d’interface sont l’anglais, le japonais, le chinois simplifié, le hindi, l’espagnol, l’arabe, le français, l’indonésien, le coréen, le russe et le portugais. Cette liste concerne l’interface et ces éditions du README ; elle ne signifie pas que le modèle Apple installé prend en charge les 11 langues.

## IA sur l’appareil

La conversation, l’extraction complémentaire des reçus et les courts commentaires sur les dépenses utilisent **SystemLanguageModel**, intégré par Apple. Le système gère le modèle et ses mises à jour. Il n’y a ni modèles alternatifs, ni écran de téléchargement ou de sélection, ni connexion à Private Cloud Compute ou à un autre fournisseur d’IA dans le cloud.

La conversation demande une réponse dans la langue du dernier message, indépendamment de l’interface. Si la langue est indéterminable, celle de l’interface est utilisée. Les langues prises en charge dépendent du modèle installé. Une langue de conversation non prise en charge produit un message explicite : essayez une langue admise par ce modèle. Les commentaires sur les dépenses demandent la langue d’interface et associent une plaisanterie générée à une action fondée sur vos données ; un conseil local remplace la génération indisponible.

## Données, reçus et sauvegardes

Les données financières et images sont conservées sur l’appareil. Dans **Accueil → Réglages → Gestion des données**, exportez portefeuilles, revenus, dépenses, opérations récurrentes et catégories au format JSON. Une fenêtre indique la taille des images référencées et permet de les inclure ou d’exporter uniquement les données. Une image partagée n’est intégrée qu’une fois. L’encodage JSON augmente la taille des données d’image d’environ **33%**.

La restauration remplace les données actuelles. Les sauvegardes avec images restaurent leurs données originales ; celles sans images ne les restaurent pas. Les anciens formats restent lisibles, mais leur historique de conversation est ignoré. Les grandes collections d’images peuvent nécessiter beaucoup de mémoire lors de l’exportation ou de la restauration.

**Aucune exportation n’inclut l’historique de conversation.** Les messages expirent **24 heures** après leur création. Wealthy supprime les messages expirés pendant son exécution et vérifie au lancement et au retour au premier plan. Si iOS suspend ou ferme l’application, la suppression a lieu à la prochaine exécution. Les messages expirés sont exclus de l’affichage et du contexte de l’IA.

L’OCR des reçus vise les **textes japonais et anglais**. L’extraction automatique des montants vise les **yens japonais entiers** ; les devises étrangères exigent une saisie manuelle. Montants et dates proviennent de l’analyseur OCR, pas de suppositions de l’IA. La date imprimée lisible est utilisée ; sinon, la date du retour de la caméra avant reconnaissance est appliquée et signalée pour vérification. Une catégorie adaptée est réutilisée ou créée si nécessaire. Tous les détails extraits sont modifiables.

Lors d’une mesure sur un iPhone 16 Pro Max sous iOS 27.2 avec les mêmes **15 images de développement**, les totaux JPY correspondaient dans **6/10** cas lisibles ; les quatre autres restaient non confirmés. Les dates imprimées correspondaient dans **14/14** cas et les catégories hybrides dans **14/14 échantillons étiquetés** ; le taux d’erreur de caractères des lignes sélectionnées est resté à **11.22%**. Ces images ont aussi servi au développement : il ne s’agit pas d’un test indépendant ni d’une estimation de précision sur de nouveaux reçus. Consultez le [rapport de mesure](Verification/ReceiptImageOCR/RESULTS.md) pour les résultats historiques sur macOS, les exclusions et les détails. Vérifiez toujours avant d’enregistrer.

## Compiler depuis les sources

Utilisez Xcode avec le **SDK iOS 26 ou ultérieur**. Les compilations de développement sont vérifiées avec **Xcode 27.0**. Ouvrez `Wealthy/Wealthy.xcodeproj`, sélectionnez le schéma **Wealthy**, configurez votre équipe de signature et exécutez sur un iPhone ou iPad compatible. Le projet utilise les frameworks système d’Apple sans dépendances externes à des paquets Swift.

Les vérifications sur un iPhone 16 Pro Max sous iOS 27.2 ont confirmé les réponses IA en japonais et en anglais, ainsi que les opérations locales de dépenses, portefeuilles et cartes de points, et la boîte de dialogue de sauvegarde. Les autres appareils et les parcours non testés restent non vérifiés. Consultez les [instructions de vérification](Verification/README.md).

La **préversion v0.1.1** contient le code source décrit ici. Elle ne fournit pas de téléchargement d’application signée ; consultez les limites de vérification avant de compiler.

## Licence

Tous droits réservés. La redistribution des sources ou des binaires nécessite une autorisation.
