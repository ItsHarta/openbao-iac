pid_file = "./pidfile"

vault {
  address = "https://openbao.astn.fyi"
  retry {
    num_retries = 5
  }
}

auto_auth {
  method "approle" {
    mount_path = "auth/agent"
    config = {
      role_id_file_path = "/mnt/roleid"
      secret_id_file_path = "/mnt/secretid"
      remove_secret_id_file_after_reading = false
    }
  }

  sink "file" {
    config = {
      path = "/tmp/token"
    }
  }
}

cache {
}

template {
  source = "/mnt/secrets.ctmpl"
  destination = "/etc/openbao/secrets.env"
}

# api_proxy {
#   use_auto_auth_token = true
# }

# listener "unix" {
#   address = "/var/run/openbao/agent.socket"
#   tls_disable = true

#   agent_api {
#     enable_quit = true
#   }
# }

# listener "tcp" {
#   address = "127.0.0.1:8100"
#   tls_disable = true
# }

