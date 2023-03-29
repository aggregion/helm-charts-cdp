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

{{- define "cdp.authservice.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "authservice")) }}
{{- end }}

{{- define "cdp.metadataSeed.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "metadataSeed")) }}
{{- end }}

{{- define "cdp.metadataService.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "metadataService")) }}
{{- end }}

{{- define "cdp.dbMetadataSync.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "dbMetadataSync")) }}
{{- end }}

{{- define "cdp.dbMetadataSyncConsumer.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "dbMetadataSyncConsumer")) }}
{{- end }}

{{- define "cdp.oidcprovider.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "oidcprovider")) }}
{{- end }}

{{- define "cdp.emailservice.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "emailservice")) }}
{{- end }}

{{- define "cdp.cleos.fullname" -}}
{{- printf "%s" (include "cdp.fullname" (list . "cleos")) }}
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

{{- define "cdp.authservice.labels" -}}
{{- include "cdp.component.labels" (list . "authservice") }}
{{- end }}

{{- define "cdp.metadataSeed.labels" -}}
{{- include "cdp.component.labels" (list . "metadataSeed") }}
{{- end }}

{{- define "cdp.metadataService.labels" -}}
{{- include "cdp.component.labels" (list . "metadataService") }}
{{- end }}

{{- define "cdp.dbMetadataSync.labels" -}}
{{- include "cdp.component.labels" (list . "dbMetadataSync") }}
{{- end }}

{{- define "cdp.dbMetadataSyncConsumer.labels" -}}
{{- include "cdp.component.labels" (list . "dbMetadataSyncConsumer") }}
{{- end }}

{{- define "cdp.oidcprovider.labels" -}}
{{- include "cdp.component.labels" (list . "oidcprovider") }}
{{- end }}

{{- define "cdp.emailservice.labels" -}}
{{- include "cdp.component.labels" (list . "emailservice") }}
{{- end }}

{{- define "cdp.cleos.labels" -}}
{{- include "cdp.component.labels" (list . "cleos") }}
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

{{- define "cdp.authservice.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "authservice") }}
{{- end }}

{{- define "cdp.metadataSeed.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "metadataSeed") }}
{{- end }}

{{- define "cdp.metadataService.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "metadataService") }}
{{- end }}

{{- define "cdp.dbMetadataSync.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "dbMetadataSync") }}
{{- end }}

{{- define "cdp.dbMetadataSyncConsumer.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "dbMetadataSyncConsumer") }}
{{- end }}

{{- define "cdp.oidcprovider.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "oidcprovider") }}
{{- end }}

{{- define "cdp.emailservice.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "emailservice") }}
{{- end }}

{{- define "cdp.cleos.selectorLabels" -}}
{{- include "cdp.selectorLabels" (list . "cleos") }}
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


{{/*
Return readiness probe
*/}}
{{- define "cdp.readinessProbe" -}}
{{- $readinessProbe := .Values.readinessProbe | default .Values.readinessProbe -}}
{{- if $readinessProbe }}
{{- if $readinessProbe.enabled }}
readinessProbe:
  httpGet:
    path: {{ .Values.readinessProbe.readinessPath }}
    port: {{ .Values.readinessProbe.healthcheckPort }}
  initialDelaySeconds: {{ $readinessProbe.initialDelaySeconds | default .Values.readinessProbe.initialDelaySeconds }}
  periodSeconds: {{ $readinessProbe.periodSeconds | default .Values.readinessProbe.periodSeconds }}
  timeoutSeconds: {{ $readinessProbe.timeoutSeconds | default .Values.readinessProbe.timeoutSeconds }}
  successThreshold: {{ $readinessProbe.successThreshold | default .Values.readinessProbe.successThreshold }}
  failureThreshold: {{ $readinessProbe.failureThreshold | default .Values.readinessProbe.failureThreshold}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Return liveness probe
*/}}
{{- define "cdp.livenessProbe" -}}
{{- $livenessProbe := .Values.livenessProbe | default .Values.livenessProbe -}}
{{- if $livenessProbe }}
{{- if $livenessProbe.enabled }}
livenessProbe:
  httpGet:
    path: {{ .Values.livenessProbe.livenessPath }}
    port: {{ .Values.livenessProbe.healthcheckPort }}
  initialDelaySeconds: {{ $livenessProbe.initialDelaySeconds | default .Values.livenessProbe.initialDelaySeconds }}
  periodSeconds: {{ $livenessProbe.periodSeconds | default .Values.livenessProbe.periodSeconds }}
  timeoutSeconds: {{ $livenessProbe.timeoutSeconds | default .Values.livenessProbe.timeoutSeconds }}
  successThreshold: {{ $livenessProbe.successThreshold | default .Values.livenessProbe.successThreshold }}
  failureThreshold: {{ $livenessProbe.failureThreshold | default .Values.livenessProbe.failureThreshold}}
{{- end -}}
{{- end -}}
{{- end -}}
