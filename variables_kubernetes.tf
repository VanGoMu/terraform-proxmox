# ============================================
# Variables del Cluster Kubernetes
# ============================================

variable "k8s_nodes" {
  description = "Configuración de los nodos del cluster Kubernetes"
  type = map(object({
    vm_name = string
    vm_id   = number
    ip      = string
    cores   = number
    memory  = number
    role    = string # "master" o "worker"
  }))
}

variable "k8s_description" {
  description = "Descripción de los nodos Kubernetes"
  type        = string
  default     = "Nodo Cluster Kubernetes"
}

variable "k8s_tags" {
  description = "Tags de los nodos Kubernetes"
  type        = list(string)
  default     = ["kubernetes", "development"]
}

variable "k8s_network_cidr" {
  description = "Subred para exports NFS y reglas de red del cluster"
  type        = string
}

variable "k8s_pod_network_cidr" {
  description = "CIDR de la red de pods Kubernetes"
  type        = string
  default     = "10.244.0.0/16"
}
