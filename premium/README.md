# premium/ — archives des extensions non distribuées par WordPress.org

Déposer ici les zips tels que téléchargés chez le fournisseur, sans les renommer : les scripts lisent l'extension et sa version dans le zip. Ils sont ignorés par Git. Le dossier accueille tout ce qui n'est pas sur WordPress.org, payant ou non.

| Extension     | Nature                           | Où télécharger                          | `update_check` |
|---------------|----------------------------------|-----------------------------------------|----------------|
| Elementor Pro | Payant, licence par site         | https://my.elementor.com/subscriptions/ | `license`      |
| Novamira      | Gratuit (volet Pro optionnel)    | https://novamira.ai/ — site officiel uniquement | `manual` |

Règles :

- Un seul zip par extension. S'il y en a plusieurs, les scripts prennent celui dont la version est la plus élevée ; supprimer l'ancien pour éviter la confusion.
- Le numéro doit correspondre à `version` dans `config/plugins.json` une fois installé ; `verify.sh` le signale sinon.
- Nouveau zip déposé → `scripts/update.sh --plugin <slug>` l'installe par-dessus l'ancienne version (`wp plugin install --force`), vérifie, met à jour le lock et le CHANGELOG.
- **Elementor Pro** : la licence s'active dans wp-admin (Elementor → Licence) et est conservée dans le blueprint. Une fois active, `update.sh` récupère les mises à jour via l'updater Elementor sans passer par un zip.
- **Novamira** : pas de dépôt WordPress.org ni de licence à activer pour la version gratuite. Si son updater ne signale rien, `check-updates.sh` affiche « vérifier chez le fournisseur » : aller sur novamira.ai, télécharger, déposer, `update.sh --plugin novamira`.
