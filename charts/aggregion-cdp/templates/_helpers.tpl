{{/*
Expand the name of the chart.
*/}}
{{- define "cdp.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cdp.chart" -}}
{{-   printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cdp.fullname" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- if (index (index .Values $argName) "fullnameOverride") }}
{{-   (index (index .Values $argName) "fullnameOverride") | trunc 63 | trimSuffix "-" }}
{{- else }}
{{-   $name := printf "%s-%s" .Chart.Name $argName }}
{{-   if (index (index .Values $argName) "nameOverride") }}
{{-     $name = default (index (index .Values $argName) "nameOverride") (printf "%s-%s" (include "cdp.name" .) $argName) }}
{{-   end }}
{{-   printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "cdp.backend.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "backend")) }}
{{- end }}

{{- define "cdp.frontend.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "frontend")) }}
{{- end }}

{{- define "cdp.enclave.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "enclave")) }}
{{- end }}

{{- define "cdp.dataservice.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "dataservice")) }}
{{- end }}

{{- define "cdp.metadataseed.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "metadataseed")) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cdp.labels" -}}
helm.sh/chart: {{ include "cdp.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "cdp.component.labels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- include "cdp.labels" . }}
{{- include "cdp.selectorLabels" (list . $argName) }}
{{- end }}
{{- end }}

{{- define "cdp.backend.labels" -}}
{{- include "cdp.component.labels" (list . "backend") }}
{{- end }}

{{- define "cdp.frontend.labels" -}}
{{- include "cdp.component.labels" (list . "frontend") }}
{{- end }}

{{- define "cdp.enclave.labels" -}}
{{- include "cdp.component.labels" (list . "enclave") }}
{{- end }}

{{- define "cdp.dataservice.labels" -}}
{{- include "cdp.component.labels" (list . "dataservice") }}
{{- end }}

{{- define "cdp.metadataseed.labels" -}}
{{- include "cdp.component.labels" (list . "metadataseed") }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cdp.selectorLabels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- $name := printf "cdp.%s.fullname" $argName }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ include $name . }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}

{{- define "cdp.backend.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "backend") }}
{{- end }}

{{- define "cdp.enclave.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "enclave") }}
{{- end }}

{{- define "cdp.frontend.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "frontend") }}
{{- end }}

{{- define "cdp.dataservice.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "dataservice") }}
{{- end }}

{{- define "cdp.selectorLabels.explicitly" -}}
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
{{- define "cdp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{-   default .Values.serviceAccount.name }}
{{- else }}
{{-   default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
