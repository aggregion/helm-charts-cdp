{{/*
Expand the name of the chart.
*/}}
{{- define "svcs.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "svcs.chart" -}}
{{-   printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "svcs.fullname" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- if (index (index .Values $argName) "fullnameOverride") }}
{{-   (index (index .Values $argName) "fullnameOverride") | trunc 63 | trimSuffix "-" }}
{{- else }}
{{-   $name := printf "%s-%s" .Chart.Name $argName }}
{{-   if (index (index .Values $argName) "nameOverride") }}
{{-     $name = default (index (index .Values $argName) "nameOverride") (printf "%s-%s" (include "svcs.name" .) $argName) }}
{{-   end }}
{{-   printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "svcs.mailcatcher.fullname" -}}
{{- printf "%s" (include "svcs.fullname" (list . "mailcatcher")) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "svcs.labels" -}}
helm.sh/chart: {{ include "svcs.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "svcs.component.labels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- include "svcs.labels" . }}
{{- include "svcs.selectorLabels" (list . $argName) }}
{{- end }}
{{- end }}

{{- define "svcs.mailcatcher.labels" -}}
{{- include "svcs.component.labels" (list . "mailcatcher") }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "svcs.selectorLabels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- $name := printf "svcs.%s.fullname" $argName }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ include $name . }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}

{{- define "svcs.mailcatcher.selectorLabels" -}}
{{- include "svcs.selectorLabels" (list . "mailcatcher") }}
{{- end }}

{{- define "svcs.selectorLabels.explicitly" -}}
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
{{- define "svcs.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{-   default .Values.serviceAccount.name }}
{{- else }}
{{-   default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
