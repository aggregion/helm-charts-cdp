{{/*
Expand the name of the chart.
*/}}
{{- define "exts.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "exts.chart" -}}
{{-   printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "exts.fullname" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- if (index (index .Values $argName) "fullnameOverride") }}
{{-   (index (index .Values $argName) "fullnameOverride") | trunc 63 | trimSuffix "-" }}
{{- else }}
{{-   $name := printf "%s-%s" .Chart.Name $argName }}
{{-   if (index (index .Values $argName) "nameOverride") }}
{{-     $name = default (index (index .Values $argName) "nameOverride") (printf "%s-%s" (include "exts.name" .) $argName) }}
{{-   end }}
{{-   printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "exts.nats.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "nats")) }}
{{- end }}

{{- define "exts.postgres.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "postgres")) }}
{{- end }}

{{- define "exts.redis.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "redis")) }}
{{- end }}

{{- define "exts.rabbit.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "rabbit")) }}
{{- end }}

{{- define "exts.mongo.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "mongo")) }}
{{- end }}

{{- define "exts.clickhouse.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "clickhouse")) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "exts.labels" -}}
helm.sh/chart: {{ include "exts.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "exts.component.labels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- include "exts.labels" . }}
{{- include "exts.selectorLabels" (list . $argName) }}
{{- end }}
{{- end }}

{{- define "exts.nats.labels" -}}
{{- include "exts.component.labels" (list . "nats") }}
{{- end }}

{{- define "exts.postgres.labels" -}}
{{- include "exts.component.labels" (list . "postgres") }}
{{- end }}

{{- define "exts.redis.labels" -}}
{{- include "exts.component.labels" (list . "redis") }}
{{- end }}

{{- define "exts.rabbit.labels" -}}
{{- include "exts.component.labels" (list . "rabbit") }}
{{- end }}

{{- define "exts.mongo.labels" -}}
{{- include "exts.component.labels" (list . "mongo") }}
{{- end }}

{{- define "exts.clickhouse.labels" -}}
{{- include "exts.component.labels" (list . "clickhouse") }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "exts.selectorLabels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- $name := printf "exts.%s.fullname" $argName }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ include $name . }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}

{{- define "exts.nats.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "nats") }}
{{- end }}

{{- define "exts.postgres.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "postgres") }}
{{- end }}

{{- define "exts.redis.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "redis") }}
{{- end }}

{{- define "exts.rabbit.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "rabbit") }}
{{- end }}

{{- define "exts.mongo.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "mongo") }}
{{- end }}

{{- define "exts.clickhouse.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "clickhouse") }}
{{- end }}

{{- define "exts.selectorLabels.explicitly" -}}
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
{{- define "exts.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{-   default .Values.serviceAccount.name }}
{{- else }}
{{-   default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
