{{/*
Expand the name of the chart.
*/}}
{{- define "dctl.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dctl.chart" -}}
{{-   printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dctl.fullname" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- if (index (index .Values $argName) "fullnameOverride") }}
{{-   (index (index .Values $argName) "fullnameOverride") | trunc 63 | trimSuffix "-" }}
{{- else }}
{{-   $name := printf "%s-%s" .Chart.Name $argName }}
{{-   if (index (index .Values $argName) "nameOverride") }}
{{-     $name = default (index (index .Values $argName) "nameOverride") (printf "%s-%s" (include "dctl.name" .) $argName) }}
{{-   end }}
{{-   printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "dctl.agentk8s.fullname" -}}
{{- printf "%s" (include "dctl.fullname" (list . "agentk8s")) }}
{{- end }}

{{- define "dctl.dc.fullname" -}}
{{- printf "%s" (include "dctl.fullname" (list . "dc")) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dctl.labels" -}}
helm.sh/chart: {{ include "dctl.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "dctl.component.labels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- with $argCtx }}
{{- include "dctl.labels" . }}
{{- include "dctl.selectorLabels" (list . $argName) }}
{{- end }}
{{- end }}

{{- define "dctl.agentk8s.labels" -}}
{{- include "dctl.component.labels" (list . "agentk8s") }}
{{- end }}

{{- define "dctl.dc.labels" -}}
{{- include "dctl.component.labels" (list . "dc") }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dctl.selectorLabels" -}}
{{- $argCtx := index . 0 }}
{{- $argName := index . 1 }}
{{- $name := printf "dctl.%s.fullname" $argName }}
{{- with $argCtx }}
app.kubernetes.io/name: "{{ include $name . }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- end }}

{{- define "dctl.agentk8s.selectorLabels" -}}
{{- include "dctl.selectorLabels" (list . "agentk8s") }}
{{- end }}

{{- define "dctl.dc.selectorLabels" -}}
{{- include "dctl.selectorLabels" (list . "dc") }}
{{- end }}

{{- define "dctl.selectorLabels.explicitly" -}}
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
{{- define "dctl.dcServiceAccountName" -}}
{{- if .Values.dc.serviceAccount.create }}
{{-   default .Values.dc.serviceAccount.name }}
{{- else }}
{{-   default "default" .Values.dc.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "dctl.agentServiceAccountName" -}}
{{- if .Values.agentk8s.serviceAccount.create }}
{{-   default .Values.agentk8s.serviceAccount.name }}
{{- else }}
{{-   default "default" .Values.agentk8s.serviceAccount.name }}
{{- end }}
{{- end }}
