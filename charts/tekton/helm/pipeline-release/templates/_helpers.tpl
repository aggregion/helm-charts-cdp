{{/*
Expand the name of the chart.
*/}}
{{- define "tektonPipeline.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tektonPipeline.chart" -}}
{{-   printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tektonPipeline.fullname" -}}
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

{{- define "tektonPipeline.controller.fullname" -}}
{{- printf "%s" (include "tektonPipeline.fullname" (list . "controller")) }}
{{- end }}

{{- define "tektonPipeline.webhook.fullname" -}}
{{- printf "%s" (include "tektonPipeline.fullname" (list . "webhook")) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tektonPipeline.labels" -}}
helm.sh/chart: {{ include "tektonPipeline.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "tektonPipeline.component.labels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- include "tektonPipeline.labels" . }}
{{- include "tektonPipeline.selectorLabels" (list . $argName) }}
{{- end }}
{{- end }}

{{- define "tektonPipeline.controller.labels" -}}
{{- include "tektonPipeline.component.labels" (list . "controller") }}
{{- end }}

{{- define "tektonPipeline.webhook.labels" -}}
{{- include "tektonPipeline.component.labels" (list . "webhook") }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tektonPipeline.selectorLabels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- $name := printf "tektonPipeline.%s.fullname" $argName }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ include $name . }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}

{{- define "tektonPipeline.controller.selectorLabels" -}}
{{- include "tektonPipeline.selectorLabels" (list . "controller") }}
{{- end }}

{{- define "tektonPipeline.webhook.selectorLabels" -}}
{{- include "tektonPipeline.selectorLabels" (list . "webhook") }}
{{- end }}

{{- define "tektonPipeline.selectorLabels.explicitly" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ $argName }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}
