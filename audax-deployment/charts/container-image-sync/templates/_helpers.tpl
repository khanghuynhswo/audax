{{/*
Expand the name of the chart.
*/}}
{{- define "container-image-sync.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "container-image-sync.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "container-image-sync.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "container-image-sync.labels" -}}
helm.sh/chart: {{ include "container-image-sync.chart" . }}
{{ include "container-image-sync.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "container-image-sync.selectorLabels" -}}
app.kubernetes.io/name: {{ include "container-image-sync.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "container-image-sync.serviceAccountName" -}}
{{- if .Values.target.auth.serviceAccount.create }}
{{- default (include "container-image-sync.fullname" .) .Values.target.auth.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.target.auth.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "container-image-sync.awscli" -}}
securityContext:
  {{- toYaml .Values.securityContext | nindent 2 }}
image: "{{ .Values.awscli.registry }}{{ .Values.awscli.repository }}:{{ .Values.awscli.tag | default .Chart.AppVersion }}"
imagePullPolicy: {{ .Values.awscli.pullPolicy }}
command: [ "/bin/sh", "/opt/audax/container-image-sync/config/entrypoint.sh" ]
{{- with .Values.volumeMounts }}
volumeMounts:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "container-image-sync.skopeo" -}}
securityContext:
  {{- toYaml .Values.securityContext | nindent 2 }}
image: "{{ .Values.skopeo.registry }}{{ .Values.skopeo.repository }}:{{ .Values.skopeo.tag | default .Chart.AppVersion }}"
imagePullPolicy: {{ .Values.skopeo.pullPolicy }}
command: [ "/bin/sh", "/opt/audax/container-image-sync/config/entrypoint.sh" ]
env:
  {{- range .Values.env }}
  - name: {{ .name }}
    value: {{ .value | quote }}
  {{- end }}
resources:
  {{- toYaml .Values.resources | nindent 2 }}
{{- with .Values.volumeMounts }}
volumeMounts:
  {{- toYaml . | nindent 2 }}
  # - name:  ax-ca-bundle
  #   mountPath: /etc/ssl/certs/ca-bundle.crt
  #   subPath: cacert.pem
  #   readOnly: true
  # - name:  ax-ca-bundle
  #   mountPath: /etc/ssl/certs/ca-bundle.trust.crt
  #   subPath: ca-certs.crt
  #   readOnly: true
{{- end }}
{{- end }}