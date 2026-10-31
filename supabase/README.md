# Backend Supabase — déploiement et contrôles

Ordre obligatoire dans Supabase Dashboard → SQL Editor :

1. `01_schema.sql`
2. `02_rls.sql`
3. `03_storage.sql`
4. `04_admin.sql` — remplacer `EMAIL_ADMIN_LA@example.com` avant exécution
5. `06_commerce.sql`
6. `08_tracking.sql` — suivi colis (position, ETA, historique géré par l'admin)
6b. `10_payment_verification.sql` — vérification des paiements sans blocage `PAYMENT_MISMATCH` (à exécuter **avant** de redéployer `commerce`)
7. `05_seed.sql` seulement pour un environnement de démonstration séparé
8. `07_delete_demo.sql` pour masquer/supprimer les données de démonstration

Après `06_commerce.sql`, `is_demo = false` devient la valeur par défaut et le catalogue public n’affiche que les produits réels.

## Fonction `commerce`

La fonction sert de proxy sécurisé vers PLOP PLOP pour :

- démarrer et vérifier `api/paiement-marchand` / `api/paiement-verify`
- recevoir les webhooks `transaction.created` et `transaction.status_changed`
- préparer, exécuter et vérifier les retraits marchands
- supprimer un compte après reconnexion récente

Déployer sans vérification JWT au point d’entrée, puisqu’elle vérifie chaque demande elle-même :

```bash
supabase functions deploy commerce --no-verify-jwt
```

## Secrets Supabase nécessaires

À définir dans Project Settings → Edge Functions → Secrets, jamais dans le code ou l’application :

| Secret | Usage |
| --- | --- |
| `SUPABASE_URL` | Requêtes PostgREST et Auth Admin |
| `SUPABASE_SERVICE_ROLE_KEY` | Réservé à la fonction ; vérifier JWT et mise à jour sécurisée |
| `PLOP_CLIENT_ID` | Identifiant marchand (`pp_...`) |
| `PLOP_CLIENT_SECRET` | Signature HMAC webhook/retrait |
| `APP_ORIGINS` | Origines HTTPS séparées par virgule, ex. `https://admin.exemple.ht` |
| `PLOP_WITHDRAWALS_ENABLED` | `true` seulement après revue et essais validés |
| `PLOP_RECONCILE_SECRET` | Long secret aléatoire ; protège l’action `payment.reconcile` appelée par pg_cron |

Ne jamais mettre `PLOP_CLIENT_ID` ou `PLOP_CLIENT_SECRET` dans `.env` du client Flutter.

## Webhook PLOP PLOP

Configurer l’URL publique de la fonction comme `webhook_url` chez le marchand :

```text
https://<projet>.supabase.co/functions/v1/commerce
```

Les signatures `X-Webhook-Signature` sont obligatoires. Le webhook appelle `paiement-verify` avant de marquer `paid`; une réponse de statut contradictoire après `paid` met l’opération en `review`.

## Google, email et redirections

Dans Authentication → Providers :

- activer Email si les inscriptions par e-mail sont voulues
- activer Google avec les identifiants OAuth de Google Cloud
- ajouter `redlight://auth/callback` dans Authentication → Redirect URLs
- ajouter l’URL publique de l’application web dans Redirect URLs
- pour le client admin local, ajouter `http://localhost:<port>` si besoin

Android utilise déjà `redlight://auth/callback` ; iOS déclare le scheme `redlight` dans `Info.plist`.

## Retraits

`PLOP_WITHDRAWALS_ENABLED=false` (ou absent) bloque tout retrait. Pour activer, vérifier d’abord : solde, fréquence de 120 s, références uniques et numéro `509XXXXXXXX`. `withdrawal.verify` peut lire un retrait même si l’exécution est désactivée.

## Réconciliation

Une notification webhook peut échouer. L’écran paiement vérifie périodiquement via `paiement-verify`. Ne pas faire confiance à une URL de retour ou à un bouton “j’ai payé” : seul `paiement-verify` (ou le webhook signé) peut confirmer.

- La référence `PAY-<order_id>` est la clé. `provider_transaction_id` garde l’ID reçu au démarrage (`paiement-marchand`), `transaction_id` l’ID renvoyé par `paiement-verify` ; un ID différent ne bloque plus le paiement.
- Chaque vérification (client, webhook, cron, admin) est enregistrée dans `payment_checks` (statut, ID, montant, erreur, réponse brute).
- Montant différent ou ID déjà utilisé par une autre commande → paiement en `review` (pas d’erreur), à contrôler par l’admin.
- Vérification automatique : activer le bloc pg_cron en bas de `10_payment_verification.sql` (toutes les 5 min, paiements `pending` des 3 derniers jours).
- Un admin peut appeler `payment.verify` sur n’importe quelle commande.

## Tests recommandés avant production

```bash
flutter analyze
flutter test
deno test supabase/functions/commerce
```

Puis tester manuellement :

1. invité → catalogue/panier autorisés → checkout redirige vers connexion
2. création de compte → profil → modifier profil → changer mot de passe → documents
3. commande ≤ stock → paiement → retour → statut `paid` seulement après vérification
4. annulation avant démarrage paiement → stock restauré ; annulation après démarrage refusée
5. logo paiement admin → checkout l’affiche ; moyen inactif → checkout refuse la commande
6. `delete account` après reconnexion → historique conservé sans adresse

## Catalogue réel et photos

Le dépôt ne contient pas de catalogue ni de photos authentiques des pièces. Importer les produits via l’admin (formulaire + image storage `product-images`) ou fournir un fichier source contenant :

```csv
category,name,description,price_htg,stock,compatible_models,image_path
```

Les photos doivent être celles des produits exacts et être importées dans `product-images`. Ne pas utiliser de photos génériques/placeholder pour des produits réels.
