# Builder personnalisé Skaffold : construit l'image avec le Docker de l'hôte puis la
# charge dans Minikube (runtime containerd => "minikube docker-env" indisponible sous Windows).
# Variables fournies par Skaffold : IMAGE (nom:tag), BUILD_CONTEXT (dossier du Dockerfile).
$ErrorActionPreference = "Stop"
docker build -t $env:IMAGE $env:BUILD_CONTEXT
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Sans push, Skaffold déploie l'image sous la référence <nom>:<id de l'image>
# (référence immuable) : on crée ce tag et on charge les deux dans Minikube.
$name = $env:IMAGE.Substring(0, $env:IMAGE.LastIndexOf(":"))
$id = (docker inspect --format "{{.Id}}" $env:IMAGE).Replace("sha256:", "")
docker tag $env:IMAGE "${name}:${id}"
minikube image load $env:IMAGE "${name}:${id}"
exit $LASTEXITCODE
