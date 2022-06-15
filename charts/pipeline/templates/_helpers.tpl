{{/*
Expand the name of the chart.
*/}}
{{- define "pipeline.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pipeline.chart" -}}
{{-   printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pipeline.fullname" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- if (index (index .Values $argName) "fullnameOverride") }}
{{-   (index (index .Values $argName) "fullnameOverride") | trunc 63 | trimSuffix "-" }}
{{- else }}
{{-   $name := printf "%s-%s" .Chart.Name $argName }}
{{-   if (index (index .Values $argName) "nameOverride") }}
{{-     $name = default (index (index .Values $argName) "nameOverride") (printf "%s-%s" (include "pipeline.name" .) $argName) }}
{{-   end }}
{{-   printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "pipeline.runner.fullname" -}}
{{- printf "%s" (include "pipeline.fullname" (list . "runner")) }}
{{- end }}

{{- define "pipeline.watcher.fullname" -}}
{{- printf "%s" (include "pipeline.fullname" (list . "watcher")) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pipeline.labels" -}}
helm.sh/chart: {{ include "pipeline.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "pipeline.component.labels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- include "pipeline.labels" . }}
{{- include "pipeline.selectorLabels" (list . $argName) }}
{{- end }}
{{- end }}

{{- define "pipeline.runner.labels" -}}
{{- include "pipeline.component.labels" (list . "runner") }}
{{- end }}

{{- define "pipeline.watcher.labels" -}}
{{- include "pipeline.component.labels" (list . "watcher") }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pipeline.selectorLabels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- $name := printf "pipeline.%s.fullname" $argName }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ include $name . }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}

{{- define "pipeline.runner.selectorLabels" -}}
{{- include "pipeline.selectorLabels" (list . "runner") }}
{{- end }}

{{- define "pipeline.watcher.selectorLabels" -}}
{{- include "pipeline.selectorLabels" (list . "watcher") }}
{{- end }}

{{- define "pipeline.selectorLabels.explicitly" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ $argName }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "pipeline.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{-   default .Values.serviceAccount.name }}
{{- else }}
{{-   default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
