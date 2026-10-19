# premium/ — archives des extensions non distribuées par WordPress.org

Déposer ici les zips tels que téléchargés chez le fournisseur. Ils sont ignorés par Git.

| Extension     | Nom de fichier attendu (`zip_glob` dans `config/plugins.json`) | Source                                  |
|---------------|----------------------------------------------------------------|-----------------------------------------|
| Elementor Pro | `elementor-pro-*.zip` (ex. `elementor-pro-4.3.2.zip`)          | https://my.elementor.com/subscriptions/ |
| Novamira      | `novamira-*.zip` (ex. `novamira-1.12.9.zip`)                   | https://novamira.ai/                    |

Règles :

- Un seul zip par extension. S'il y en a plusieurs, `install.sh` prend le plus récent (tri par nom de fichier).
- Le numéro de version dans le nom de fichier doit correspondre à `version` dans `config/plugins.json` ; `verify.sh` le signale sinon.
- Après avoir déposé un nouveau zip : `scripts/update.sh --plugin elementor-pro` (ou Novamira) installe la nouvelle version par-dessus l'ancienne (`wp plugin install --force`).
- Les licences s'activent dans wp-admin (Elementor → Licence ; Novamira → Réglages) ou via `.env` si le fournisseur le permet. L'activation est conservée dans le blueprint.
