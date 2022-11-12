{{/*
Expand the name of the chart.
*/}}
{{- define "scone.cas.name" -}}
{{- default .Chart.Name .Values.cas.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "scone.esp.name" -}}
{{- default .Chart.Name .Values.cas.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "scone.cas.fullname" -}}
{{- if .Values.cas.fullnameOverride }}
{{- .Values.cas.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.cas.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "scone.esp.fullname" -}}
{{- if .Values.esp.fullnameOverride }}
{{- .Values.esp.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.esp.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "scone.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "scone.cas.labels" -}}
helm.sh/chart: {{ include "scone.chart" . }}
{{ include "scone.cas.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "scone.esp.labels" -}}
helm.sh/chart: {{ include "scone.chart" . }}
{{ include "scone.esp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "scone.cas.selectorLabels" -}}
app.kubernetes.io/name: {{ include "scone.cas.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "scone.esp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "scone.esp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "scone.cas.serviceAccountName" -}}
{{- if .Values.cas.serviceAccount.create }}
{{- default (include "scone.cas.fullname" .) .Values.cas.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.cas.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "scone.esp.serviceAccountName" -}}
{{- if .Values.esp.serviceAccount.create }}
{{- default (include "scone.esp.fullname" .) .Values.esp.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.esp.serviceAccount.name }}
{{- end }}
{{- end }}
