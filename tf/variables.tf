variable "kubeconfig_path" {
  description = "Ścieżka do kubeconfiga."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kontekst z kubeconfiga (kubectl config current-context)."
  type        = string
  default     = "aiops"
}

variable "namespace" {
  description = "Namespace uczestnika, w którym działa Kantyna."
  type        = string
  default     = "radoslaw"
}

variable "release" {
  description = "Nazwa release'u Helma (etykieta app.kubernetes.io/instance)."
  type        = string
  default     = "kantyna"
}
