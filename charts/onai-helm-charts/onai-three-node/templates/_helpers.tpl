{{/*
Expand the name of the chart.
*/}}
{{- define "onai-three-node.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "onai-three-node.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Per-node fully qualified names
*/}}
{{- define "onai-three-node.m1.fullname" -}}
{{- printf "%s-m1" (include "onai-three-node.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "onai-three-node.m2.fullname" -}}
{{- printf "%s-m2" (include "onai-three-node.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "onai-three-node.m3.fullname" -}}
{{- printf "%s-m3" (include "onai-three-node.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Chart name and version as used by the chart label.
*/}}
{{- define "onai-three-node.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "onai-three-node.labels" -}}
helm.sh/chart: {{ include "onai-three-node.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Per-node selector labels
*/}}
{{- define "onai-three-node.m1.selectorLabels" -}}
app.kubernetes.io/name: {{ include "onai-three-node.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: m1-web
{{- end }}

{{- define "onai-three-node.m2.selectorLabels" -}}
app.kubernetes.io/name: {{ include "onai-three-node.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: m2-vllm
{{- end }}

{{- define "onai-three-node.m3.selectorLabels" -}}
app.kubernetes.io/name: {{ include "onai-three-node.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: m3-gateway
{{- end }}

{{/*
Per-node labels (common + selector)
*/}}
{{- define "onai-three-node.m1.labels" -}}
{{ include "onai-three-node.labels" . }}
{{ include "onai-three-node.m1.selectorLabels" . }}
{{- end }}

{{- define "onai-three-node.m2.labels" -}}
{{ include "onai-three-node.labels" . }}
{{ include "onai-three-node.m2.selectorLabels" . }}
{{- end }}

{{- define "onai-three-node.m3.labels" -}}
{{ include "onai-three-node.labels" . }}
{{ include "onai-three-node.m3.selectorLabels" . }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "onai-three-node.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "onai-three-node.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
M3 internal service FQDN (for service discovery)
*/}}
{{- define "onai-three-node.m3.internalHost" -}}
{{- printf "%s.%s.svc.cluster.local" (include "onai-three-node.m3.fullname" .) .Release.Namespace }}
{{- end }}

{{/*
M1 internal service FQDN
*/}}
{{- define "onai-three-node.m1.internalHost" -}}
{{- printf "%s.%s.svc.cluster.local" (include "onai-three-node.m1.fullname" .) .Release.Namespace }}
{{- end }}

{{/*
M2 internal service FQDN
*/}}
{{- define "onai-three-node.m2.internalHost" -}}
{{- printf "%s.%s.svc.cluster.local" (include "onai-three-node.m2.fullname" .) .Release.Namespace }}
{{- end }}
