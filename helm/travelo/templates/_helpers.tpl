{{/* Nom de base des ressources : <release>-travelo (ou <release> s'il contient déjà "travelo") */}}
{{- define "travelo.fullname" -}}
{{- if contains "travelo" .Release.Name -}}
{{- .Release.Name | trunc 50 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-travelo" .Release.Name | trunc 50 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* Labels communs */}}
{{- define "travelo.labels" -}}
app.kubernetes.io/part-of: travelo
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/* Labels de sélection d'un composant : include "travelo.selector" (list . "backend") */}}
{{- define "travelo.selector" -}}
{{- $root := index . 0 -}}
app.kubernetes.io/instance: {{ $root.Release.Name }}
app.kubernetes.io/component: {{ index . 1 }}
{{- end -}}
