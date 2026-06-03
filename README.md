# TP - Automatisation dans les DevOps (UCAD 2025-2026)

Projet complet illustrant l'automatisation d'un pipeline DevOps :
script shell, intégration continue (GitHub Actions), conteneurisation (Docker)
et Infrastructure as Code (Terraform).

## Structure du projet

```
devops-tp/
├── app/                       # Application Node.js / Express
│   ├── src/
│   │   ├── index.js           # Définition de l'app (testable)
│   │   └── server.js          # Démarrage du serveur HTTP
│   ├── tests/
│   │   └── api.test.js        # Tests unitaires (Jest + Supertest)
│   ├── Dockerfile             # Image Docker de l'app
│   ├── .dockerignore
│   └── package.json
├── auto_deploy.sh             # Partie 1 : script bash d'automatisation
├── .github/workflows/ci.yml   # Partie 2 : pipeline CI/CD GitHub Actions
├── terraform/                 # Partie 3 : Infrastructure as Code
│   ├── main.tf
│   └── variables.tf
├── .gitignore
└── README.md
```

---

## Application de test

Une API Express minimale. La route principale `GET /ping` renvoie `pong`.

| Route      | Réponse                          |
|------------|----------------------------------|
| `GET /`    | message d'accueil (JSON)         |
| `GET /ping`| `pong`                           |
| `GET /health` | `{ "status": "ok", ... }`     |

### Lancer l'app localement

```bash
cd app
npm install
npm start          # http://localhost:3000
npm test           # lance les tests Jest
```

Vérification rapide :

```bash
curl http://localhost:3000/ping   # -> pong
```

---

## Partie 1 — Script shell `auto_deploy.sh`

Le script automatise : vérification des dépendances → clonage/màj du dépôt →
installation → tests → démarrage de l'application.

### Utilisation

```bash
chmod +x auto_deploy.sh
./auto_deploy.sh <URL_DU_DEPOT> [NOM_DU_DOSSIER]

# Exemple
./auto_deploy.sh https://github.com/votre-nom/votre-app.git mon_app
```

### Réponses aux questions de la Partie 1

1. **URL en paramètre** — Le dépôt est passé en argument (`$1`), avec un nom de
   dossier optionnel (`$2`, déduit de l'URL sinon).
2. **Fonction de log horodatée** — La fonction `log <NIVEAU> <message>` préfixe
   chaque ligne de `[AAAA-MM-JJ HH:MM:SS] [NIVEAU]`, l'affiche en couleur et
   l'écrit dans `deploy.log`.
3. **Arrière-plan + PID** — L'app est lancée via `nohup npm start &` ; son PID
   est sauvegardé dans `.app.pid`. Une ancienne instance est arrêtée
   proprement avant d'en démarrer une nouvelle.

Pour arrêter l'application :

```bash
kill $(cat .app.pid)
```

> Note : ce script cible un environnement Linux/macOS (bash). Sous Windows,
> exécutez-le via **WSL** ou **Git Bash**.

---

## Partie 2 — CI/CD avec GitHub Actions

Le workflow `.github/workflows/ci.yml` se déclenche sur chaque `push` et
`pull_request` vers `main`. Il comporte 3 jobs enchaînés :

1. **build-and-test** — installe les dépendances et exécute les tests.
2. **docker** — *(ne s'exécute que si les tests passent, via `needs:`)*
   construit l'image Docker et la pousse sur Docker Hub.
3. **deploy** *(avancé)* — déploie l'image sur un serveur distant via SSH.

> **Question 3 (déployer seulement si les tests passent)** : géré par
> `needs: build-and-test`. Si un test échoue, les jobs `docker` et `deploy`
> ne s'exécutent pas.

### Secrets à configurer

Dans GitHub : **Settings → Secrets and variables → Actions** :

| Secret             | Usage                                  |
|--------------------|----------------------------------------|
| `DOCKER_USERNAME`  | identifiant Docker Hub                  |
| `DOCKER_PASSWORD`  | token / mot de passe Docker Hub         |
| `SSH_HOST`         | IP/host du serveur de déploiement       |
| `SSH_USER`         | utilisateur SSH                         |
| `SSH_PRIVATE_KEY`  | clé privée SSH                          |

---

## Docker (bonus)

```bash
cd app
docker build -t votre-nom/mon-app:latest .
docker run -d -p 3000:3000 --name mon-app votre-nom/mon-app:latest
curl http://localhost:3000/ping   # -> pong
```

---

## Partie 3 — Infrastructure as Code (Terraform)

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
# ...
terraform destroy -auto-approve   # pour tout supprimer
```

> ⚠️ Nécessite un compte AWS et des identifiants configurés
> (`aws configure` ou variables d'environnement). Pensez à `terraform destroy`
> pour éviter toute facturation.

### Réponses aux questions de réflexion

**Avantages de l'IaC vs configuration manuelle**
- **Reproductibilité** : la même infra est recréée à l'identique, sans erreur humaine.
- **Versionnement** : l'infrastructure est décrite dans du code suivi par Git
  (historique, revue de code, rollback).
- **Documentation vivante** : le code *est* la documentation de l'infra.
- **Rapidité & scalabilité** : création/destruction en une commande.
- **Cohérence multi-environnements** : dev, staging et prod identiques.

**Intégrer Terraform dans un pipeline CI/CD**
- Lancer `terraform fmt -check` et `terraform validate` à chaque commit.
- Exécuter `terraform plan` sur les pull requests (et publier le plan en commentaire).
- Appliquer `terraform apply` automatiquement après merge sur `main`
  (avec une étape d'approbation manuelle pour la production).
- Stocker l'état dans un **backend distant** (S3 + verrouillage DynamoDB)
  et fournir les identifiants cloud via les secrets du CI.

**Précautions avec les fichiers `.tfstate`**
- Ils contiennent des **données sensibles en clair** (IP, parfois secrets) :
  ne **jamais** les versionner dans Git (voir `.gitignore`).
- Utiliser un **backend distant chiffré** avec **verrouillage** (lock) pour
  éviter les corruptions lors d'accès concurrents.
- Ne pas les éditer à la main ; activer le **versioning** du bucket pour
  pouvoir restaurer un état précédent.

---

## Livrables du TP

- [x] Script bash d'automatisation (`auto_deploy.sh`)
- [x] Workflow GitHub Actions (`.github/workflows/ci.yml`)
- [x] README expliquant chaque partie
- [ ] Captures d'écran des exécutions réussies *(à ajouter après exécution)*
