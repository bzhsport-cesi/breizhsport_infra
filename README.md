# BreizhSport Infra

Infrastructure as Code (IaC) pour le déploiement automatisé de l’application frontend [BreizhSport](https://breizhsport.me) sur une VM DENV-R, via Terraform, Ansible, Docker et GitHub Actions.

---

## 📌 Objectifs

- Provisionner automatiquement une VM publique.
- Déployer une image Docker frontend (Next.js) sur la VM via Ansible.
- Configurer automatiquement le DNS via l’API Cloudflare.
- Gérer les certificats HTTPS via Cloudflare Proxy.
- Détruire et redéployer toute l'infrastructure à chaque commit.
- Utiliser **Terraform Cloud** comme backend distant (state partagé + historique).

---

## 🛠️ Technologies utilisées

| Outil                           | Rôle                                                                |
|---------------------------------|---------------------------------------------------------------------|
| **Terraform**                   | Provisionnement de l’infra (VM, IP, DNS)                            |
| **Ansible**                     | Configuration de la VM et déploiement Docker                        |
| **Docker / Compose**            | Conteneurisation du frontend Next.js                                |
| **GitHub Actions**              | CI/CD : build + destruction/redéploiement automatique               |
| **Cloudflare**                  | DNS & HTTPS (proxy SSL Full)                                        |
| **Terraform Cloud**             | Backend distant partagé pour stocker l’état Terraform               |
| **Warren (DENV-R)**             | Provider cloud pour créer les VMs publiques                         |
| **GitHub Container Registry**   | Stockage des images Docker front                                    |

---

## 🗂️ Arborescence

```
breizhsport_infra/
├── terraform/                     # Code Terraform principal (infra + Ansible provision)
│   ├── main.tf
│   ├── variables.tf
│   ├── provider.tf
│   ├── inventory.tmpl
|   ├── playbook.yml               # Playbook Ansible exécuté à distance
|   ├── inventory.tmpl             # Template pour inventory.tmpl
|   └── docker-compose.yml.j2      # Template pour docker-compose.yml.j2
├── .github/workflows/             # Fichiers GitHub Actions
│   └── deploy.yml
└── README.md            
```

---

## 🚀 Déploiement automatique (CI/CD)

1. Le dépôt **frontend** push une nouvelle image Docker sur GHCR.
2. Il déclenche une action vers ce dépôt.
3. Le fichier `deploy.yml` :
   - **Détruit** l’infrastructure existante (VM + DNS).
   - **Reprovisionne** une nouvelle VM + DNS.
   - **Exécute Ansible** pour lancer l’image via Docker Compose.
4. Résultat : le site est redéployé automatiquement avec la dernière version.

---

## 🔐 Secrets requis (GitHub)

| Secret                   | Description                                      |
|--------------------------|--------------------------------------------------|
| `API_TOKEN`              | Token API DENV-R (Warren)                        |
| `SSH_PRIVATE_KEY`        | Clé privée pour accéder à la VM                  |
| `SSH_PUBLIC_KEY`         | Clé publique à injecter dans la VM               |
| `ANSIBLE_USER`           | Nom d’utilisateur distant (ex: ubuntu)           |
| `REGISTRY_TOKEN`         | Token GitHub pour `docker login` sur GHCR        |
| `CLOUDFLARE_API_TOKEN`   | Token API Cloudflare                             |
| `CLOUDFLARE_ZONE_ID`     | Zone ID Cloudflare (pour `breizhsport.me`)       |
| `TF_API_TOKEN`           | Token Terraform Cloud pour le backend distant    |

---

## ⚙️ Commandes Terraform utiles (local)

```bash
terraform login
terraform init
terraform plan
terraform apply -var="..." ...
terraform destroy -var="..." ...
```

---

## ✅ Résultat attendu

- Site disponible sur `https://breizhsport.me`.
- DNS mis à jour automatiquement sur Cloudflare.
- VM publique provisionnée automatiquement chez DENV-R.
- Certificat HTTPS actif (via proxy Cloudflare).
- Infra détruite et redéployée à chaque push.