machine:
  certSANs:
    - talos.home.arpa
    - {{ .Data.subnet }}.10
    - {{ .Data.subnet }}.20
    - {{ .Data.subnet }}.30
  features:
    hostDNS:
      forwardKubeDNSToHost: false # Use the host DNS resolver as upstream for Kubernetes CoreDNS pods.
  kubelet:
    extraConfig:
      featureGates:
        UserNamespacesSupport: true
        DynamicResourceAllocation: true
  sysctls:
    user.max_user_namespaces: "11255"
