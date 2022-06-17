{{/*
Expand the name of the chart.
*/}}
{{- define "tektonOperator.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tektonOperator.chart" -}}
{{-   printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tektonOperator.fullname" -}}
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

{{- define "tektonOperator.operator.fullname" -}}
{{- printf "%s" (include "tektonOperator.fullname" (list . "operator")) }}
{{- end }}

{{- define "tektonOperator.webhook.fullname" -}}
{{- printf "%s" (include "tektonOperator.fullname" (list . "webhook")) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tektonOperator.labels" -}}
helm.sh/chart: {{ include "tektonOperator.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "tektonOperator.component.labels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- include "tektonOperator.labels" . }}
{{- include "tektonOperator.selectorLabels" (list . $argName) }}
{{- end }}
{{- end }}

{{- define "tektonOperator.operator.labels" -}}
{{- include "tektonOperator.component.labels" (list . "operator") }}
{{- end }}

{{- define "tektonOperator.webhook.labels" -}}
{{- include "tektonOperator.component.labels" (list . "webhook") }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tektonOperator.selectorLabels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- $name := printf "tektonOperator.%s.fullname" $argName }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ include $name . }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}

{{- define "tektonOperator.operator.selectorLabels" -}}
{{- include "tektonOperator.selectorLabels" (list . "operator") }}
{{- end }}

{{- define "tektonOperator.webhook.selectorLabels" -}}
{{- include "tektonOperator.selectorLabels" (list . "webhook") }}
{{- end }}

{{- define "tektonOperator.selectorLabels.explicitly" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ $argName }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}
