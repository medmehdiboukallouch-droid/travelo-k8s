# travelo-k8s — Déploiement de Travelo sur Kubernetes

Manifests Kubernetes, configuration Skaffold, chart Helm et cluster MySQL piloté par un opérateur pour l'application 3-tiers **Travelo** (React + Spring Boot + MySQL).
Devoir 2 du module Conteneurisation des Applications (INPT, ASEDS).

## Arborescence

```
k8s/                  manifests de l'application (namespace travelo)
  00-namespace.yaml     Namespace
  01-quotas.yaml        ResourceQuota (namespace) + LimitRange (par Pod / conteneur)
  02-rbac.yaml          ServiceAccounts, Role, RoleBinding
  03-configmap.yaml     ConfigMaps backend + MySQL (script de jeu de données)
  04-secret.yaml        Secret des identifiants MySQL
  10-mysql.yaml         Service headless + StatefulSet MySQL (PVC)
  20-backend.yaml       Deployment (2 réplicas) + Service Spring Boot
  30-frontend.yaml      Deployment (2 réplicas) + Service React/Nginx
  40-pdb.yaml           PodDisruptionBudgets
  50-ingress.yaml       Ingress travelo.local (/ -> frontend, /api -> backend)
  kustomization.yaml    kubectl apply -k k8s/
demo/                   démonstrations : liveness probe en échec, Pod refusé par le LimitRange
skaffold.yaml           bonus B : build + déploiement continu
scripts/build-image.ps1 builder Skaffold (docker build + minikube image load)
helm/travelo/           bonus C : chart Helm écrit from scratch
docs/                   dépôt Helm publié (index.yaml + archive du chart)
operator/               bonus A : cluster InnoDB (Operator) et bascule de Travelo dessus
```

## Prérequis

- Docker Desktop, Minikube, kubectl (Helm et Skaffold pour les bonus)
- Les sources de l'application dans `../travelo-app` (le frontend appelle l'API en relatif : `/api/...`)

## Déploiement

```bash
minikube start --driver=docker --cpus=6 --memory=8192 --addons=ingress,metrics-server

# Images (construites localement puis chargées dans le cluster)
docker build -t mehdiboukallouch/travelo-backend:2.0  ../travelo-app/travelo_backend
docker build -t mehdiboukallouch/travelo-frontend:2.0 ../travelo-app/travelo_frontend
minikube image load mehdiboukallouch/travelo-backend:2.0 mehdiboukallouch/travelo-frontend:2.0

kubectl apply -k k8s/
kubectl get all -n travelo
```

Accès navigateur : lancer `minikube tunnel` (le laisser ouvert) puis ajouter dans
`C:\Windows\System32\drivers\etc\hosts` (en administrateur) :

```
127.0.0.1 travelo.local helm.travelo.local
```

Puis ouvrir http://travelo.local

## Bonus B — Skaffold

Avec le runtime containerd, `minikube docker-env` n'est pas disponible sous Windows : un alias de contexte et un builder personnalisé sont utilisés.

```bash
kubectl config set-context travelo-dev --cluster=minikube --user=minikube --namespace=travelo
skaffold config set --kube-context travelo-dev local-cluster true
skaffold dev --kube-context travelo-dev --detect-minikube=false --cache-artifacts=false
```

## Bonus C — Helm

Kubernetes impose des noms de namespace en minuscules : le namespace demandé « Helm » s'appelle donc `helm`.

```bash
helm install travelo ./helm/travelo --namespace helm --create-namespace
# depuis le dépôt publié (GitHub Pages servant le dossier docs/) :
helm repo add travelo https://medmehdiboukallouch-droid.github.io/travelo-k8s/
helm install travelo travelo/travelo -n helm --create-namespace
```

## Bonus A — Operator

```bash
helm repo add mysql-operator https://mysql.github.io/mysql-operator/
helm install mysql-operator mysql-operator/mysql-operator -n mysql-operator --create-namespace
kubectl apply -f operator/innodbcluster.yaml
kubectl get innodbcluster -n travelo-db
```

Brancher Travelo sur le cluster InnoDB (via le MySQL Router) :

```bash
# base, utilisateur applicatif et jeu de données, exécutés sur le primaire via le Router
kubectl exec -i -n travelo-db travelo-db-0 -c mysql -- mysql -h travelo-db -P 6446 -uroot -p<root> < operator/init-travelo.sql
kubectl exec -i -n travelo-db travelo-db-0 -c mysql -- mysql -h travelo-db -P 6446 -utravelo -p<app> travelo_db < helm/travelo/files/schema-seed.sql
# le backend pointe vers le Router (port 6446 = lecture/écriture)
kubectl apply -f operator/backend-config-innodb.yaml
kubectl rollout restart deployment travelo-backend -n travelo
# l'ancien StatefulSet n'est plus utilisé
kubectl delete statefulset,service travelo-mysql -n travelo
```
