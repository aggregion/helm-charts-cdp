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

{{- define "exts.atlas.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "atlas")) }}
{{- end }}

{{- define "exts.cassandra.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "cassandra")) }}
{{- end }}

{{- define "exts.hadoop.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "hadoop")) }}
{{- end }}

{{- define "exts.hbase.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "hbase")) }}
{{- end }}

{{- define "exts.kafka.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "kafka")) }}
{{- end }}

{{- define "exts.solr.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "solr")) }}
{{- end }}

{{- define "exts.zookeeper.fullname" -}}
{{- printf "%s" (include "exts.fullname" (list . "zookeeper")) }}
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

{{- define "exts.atlas.labels" -}}
{{- include "exts.component.labels" (list . "atlas") }}
{{- end }}

{{- define "exts.cassandra.labels" -}}
{{- include "exts.component.labels" (list . "cassandra") }}
{{- end }}

{{- define "exts.hadoop.labels" -}}
{{- include "exts.component.labels" (list . "hadoop") }}
{{- end }}

{{- define "exts.hbase.labels" -}}
{{- include "exts.component.labels" (list . "hbase") }}
{{- end }}

{{- define "exts.kafka.labels" -}}
{{- include "exts.component.labels" (list . "kafka") }}
{{- end }}

{{- define "exts.solr.labels" -}}
{{- include "exts.component.labels" (list . "solr") }}
{{- end }}

{{- define "exts.zookeeper.labels" -}}
{{- include "exts.component.labels" (list . "zookeeper") }}
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

{{- define "exts.atlas.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "atlas") }}
{{- end }}

{{- define "exts.cassandra.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "cassandra") }}
{{- end }}

{{- define "exts.hadoop.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "hadoop") }}
{{- end }}

{{- define "exts.hbase.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "hbase") }}
{{- end }}

{{- define "exts.kafka.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "kafka") }}
{{- end }}

{{- define "exts.solr.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "solr") }}
{{- end }}

{{- define "exts.zookeeper.selectorLabels" -}}
{{- include "exts.selectorLabels" (list . "zookeeper") }}
{{- end }}

{{- define "exts.selectorLabels.explicitly" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ $argName }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}
