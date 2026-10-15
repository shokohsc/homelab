apiVersion: v1alpha1
kind: HostnameConfig
{{- if hasKey .Node.Data "ignoreHostname" }}
auto: stable
{{- else }}
auto: "off"
hostname: {{ .Node.Host }}
{{- end }}
