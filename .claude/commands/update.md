---
description: Met à jour le starter (cœur, thème, extensions) depuis WordPress.org, vérifie, synchronise le lock et le CHANGELOG
argument-hint: [slug ...] (optionnel : limiter à certaines extensions)
---

Procédure de mise à jour du site starter. Arguments reçus : `$ARGUMENTS` (vide = tout).

1. Lance `scripts/check-updates.sh` et présente ce qui va changer. Si rien n'est disponible, dis-le et arrête-toi.
2. Pour chaque extension premium (`source: zip`) signalée « vérifier chez le fournisseur » : regarde si un zip plus récent est présent dans `premium/`. Sinon, note-la comme « à vérifier manuellement » et poursuis avec le reste — ne bloque pas la mise à jour des autres.
3. Lance `scripts/update.sh` (sans argument), ou `scripts/update.sh --plugin <slug>` pour chaque slug reçu en argument. Le script sauvegarde la base dans `reports/`, applique, exécute `verify.sh`, synchronise `config/plugins.json` + `config/stack.json` et ajoute l'entrée du jour dans `CHANGELOG.md`.
4. Si `verify.sh` échoue : ne force rien. Montre l'erreur, propose la restauration (`wp db import <sauvegarde>`) et attends une décision.
5. Si tout passe : affiche `git status` et `git diff --stat`, puis propose le commit avec le message `chore(update): <liste courte des changements>`. Commit seulement après accord.
6. Rappelle l'étape manuelle finale : LocalWP → site wp-starter → « Save as Blueprint » (voir README, section « Régénérer le blueprint »).

Ne touche jamais aux fichiers de `premium/` ni à `.env`. Ne modifie pas `config/settings.json` dans cette procédure.
