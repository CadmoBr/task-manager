resource "null_resource" "k3d_cluster" {
  triggers = {
    cluster_name = "task-cluster"
  }

  provisioner "local-exec" {
    command = <<-EOT
      k3d cluster get task-cluster > /dev/null 2>&1 || k3d cluster create task-cluster --servers 1 --agents 2 --port 3000:30001@loadbalancer --port 3001:30000@loadbalancer --k3s-arg "--disable=traefik@server:0" --wait
      
      k3d kubeconfig merge task-cluster --kubeconfig-switch-context
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete task-cluster || true"
  }
}

resource "null_resource" "task_manager_image" {
  triggers = {
    dockerfile = filemd5("${path.module}/../Dockerfile")
    package    = filemd5("${path.module}/../package.json")
    source     = sha256(join("", [for file in fileset("${path.module}/../app", "**") : filemd5("${path.module}/../app/${file}")]))
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/.."
    command     = "docker build -t task-manager:latest . && k3d image import task-manager:latest -c task-cluster"
  }

  depends_on = [null_resource.k3d_cluster]
}