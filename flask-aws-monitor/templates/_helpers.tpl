{{- define "flask-aws-monitor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "flask-aws-monitor.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "flask-aws-monitor.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "flask-aws-monitor.labels" -}}
app.kubernetes.io/name: {{ include "flask-aws-monitor.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "flask-aws-monitor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flask-aws-monitor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
