{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "tutor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tutor.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "tutor.domainname" -}}
{{ .Values.LMS_HOST | replace "." "-" }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tutor.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Uniform common labels.
*/}}
{{- define "tutor.common.labels" -}}
{{ include "tutor.common.matchLabels" . }}
helm.sh/chart: {{ include "tutor.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Uniform selector labels.
*/}}
{{- define "tutor.common.matchLabels" -}}
app.kubernetes.io/name: {{ include "tutor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Spec for a container that renders tutor config files into a volume.
*/}}
{{- define "tutor.config.container" -}}
- name: tutor-config
  image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  args: ["config", "save", "--silent"]
  envFrom:
    - configMapRef:
        name: {{ template "tutor.fullname" . }}
  volumeMounts:
    - name: tutor-config
      mountPath: /root/.local/share/tutor
{{- end -}}

{{/*
Spec for a container to run Open edX migrations.
*/}}
{{- define "tutor.openedx.migrate" -}}
- name: migrate-{{ .ServiceVariant }}
  image: "{{ .Values.DOCKER_IMAGE_OPENEDX }}"
  imagePullPolicy: {{ .Values.openedx.image.pullPolicy }}
  command: ["./manage.py", "{{ .ServiceVariant }}", "migrate"]
  volumeMounts:
    - name: tutor-config
      mountPath: /openedx/edx-platform/{{ .ServiceVariant }}/envs/tutor/
      subPath: env/apps/openedx/settings/{{ .ServiceVariant }}
    - name: tutor-config
      mountPath: /openedx/config/
      subPath: env/apps/openedx/config
{{- end -}}
