---
description: État du starter — versions installées vs lock vs disponibles sur WordPress.org, sans rien modifier
---

Exécute `scripts/check-updates.sh` puis `scripts/verify.sh --quick`.

Résume en quelques lignes, dans cet ordre :
1. Les mises à jour disponibles (nom, version installée → disponible), cœur et thème compris.
2. Les extensions premium dont l'état est « vérifier chez le fournisseur » : indique l'URL `vendor_url` de `config/plugins.json`.
3. Les écarts lock ≠ installé et les extensions hors lock.
4. Les erreurs de `verify.sh`, s'il y en a.

Termine par une recommandation : « rien à faire », ou « lancer /update », ou l'action manuelle requise. Ne modifie aucun fichier.
