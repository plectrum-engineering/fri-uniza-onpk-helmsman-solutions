{{/*
Chart name + version, used in the helm.sh/chart label.
*/}}
{{- define "guestbook.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels added to every object.
*/}}
{{- define "guestbook.labels" -}}
helm.sh/chart: {{ include "guestbook.chart" . }}
app.kubernetes.io/part-of: guestbook
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
onpk.io/environment: {{ .Values.environment | quote }}
{{- end }}

{{/*
Render an image reference from {repository, tag, digest}.
A digest wins over a tag. Usage: {{ include "guestbook.image" .Values.frontend.image }}
*/}}
{{- define "guestbook.image" -}}
{{- if .digest -}}
{{ .repository }}@{{ .digest }}
{{- else -}}
{{ .repository }}:{{ required "image.tag or image.digest must be set" .tag }}
{{- end -}}
{{- end }}
