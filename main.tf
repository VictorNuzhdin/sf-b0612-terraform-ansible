##--Описание коннектора Облачного Провайдера (в дс. Yandex.Cloud)
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.84.0" # версию необходимо указать только при первичной инициализации Terraform
    }
  }
}

##--Локальные переменные:
##  *iam токен авторизации;
##  *id Облака;
##  *id Каталога;
##  *зона доступности;
##  *public ssh-ключ для авторизации по ключу на серверах;
##
variable "yc_token" { type=string }

locals {
  ## token-created: 2023.04.20 10:00
  ## $ export TF_VAR_yc_token=$(yc iam create-token) && echo $TF_VAR_yc_token
  #
  iam_token       = "${var.yc_token}"
  cloud_id        = "b1g0u201bri5ljle0qi2"
  folder_id       = "b1gqi8ai4isl93o0qkuj"
  access_zone     = "ru-central1-b"
  vm_default_login = "ubuntu"                    # Ubuntu image default username;
  ssh_pubkey_path  = "~/.ssh/id_ed25519.pub"     # Set a full path to the SSH public key for VM;
}

##--Авторизация на стороне провайдера и указание Ресурсов с которыми будет работать Terraform
provider "yandex" {
  token     = local.iam_token
  cloud_id  = local.cloud_id
  folder_id = local.folder_id
  zone      = local.access_zone
}


##--Создаем VM2 (Ubuntu 22.04, x2 vCPU, x2 GB RAM, x20 GB HDD) -- phpfpm хост
resource "yandex_compute_instance" "host2" {
  name        = "ubuntu-php-fpm"
  hostname    = "phpfpm"
  platform_id = "standard-v2"
  zone        = local.access_zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id    = "fd8i3uauimpm750kd9vh"
      type        = "network-hdd"
      size        = 20
      description = "Ubuntu 22.04 LTS"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    ip_address = "10.0.10.11"
    nat        = true
  }

  metadata = {
    serial-port-enable = 0
    ssh-keys = "ubuntu:${file("${local.ssh_pubkey_path}")}"
  }

  provisioner "remote-exec" {

    connection {
      type = "ssh"
      user = "ubuntu"
      host = yandex_compute_instance.host2.network_interface.0.nat_ip_address
      agent = true
      #timeout = "4m"
    }

    inline = [
      "sudo apt update && sudo apt install -y python3 && sudo apt -y autoremove",
      "echo '## python3 --version' >> /home/ubuntu/install_log.txt && python3 --version >> /home/ubuntu/install_log.txt"
    ]
  } ## << "provisioner remote-exec"

  provisioner "local-exec" {
    ##--Применяем Ansible Плейбук "phpfpm" к инстансу "host2"
    ##  example: ansible-playbook -i 158.160.28.188, -u ubuntu ./ansible/deploy_phpfpm.yml
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_ASK_PASS=False ansible-playbook -i '${yandex_compute_instance.host2.network_interface.0.nat_ip_address},' -u ${local.vm_default_login} ./ansible/deploy_phpfpm.yml"
    #
  } ## << "provisioner local-exec"

}


##--Создаем VM1 (Ubuntu 22.04, x2 vCPU, x2 GB RAM, x20 GB HDD) -- nginx хост (зависит от phpfpm)
resource "yandex_compute_instance" "host1" {
  name        = "ubuntu-nginx"      # имя ВМ;
  hostname    = "nginx"             # сетевое имя ВМ (имя хоста);
  platform_id = "standard-v2"       # семейство облачной платформы ВМ (влияет на тип и параметры доступного для выбора CPU);
  zone        = local.access_zone   # зона доступности (размещение ВМ в конкретном датацентре);

  resources {
    cores         = 2 # колво виртуальных ядер vCPU;
    memory        = 2 # размер оперативной памяти, ГБ;
    core_fraction = 5 # % гарантированной доли CPU (самый дешевый вариант, при 100% вся процессорная мощность резервируется для клиента);
  }

  ## Делаем ВМ прерываемой (делает ВМ дешевле на 50% но ее в любой момент могут вырубить что происходит не часто)
  scheduling_policy {
    preemptible = true
  }

  ## Загрузочный образ на основе которого создается ВМ (из Yandex)
  boot_disk {
    initialize_params {
      image_id    = "fd8i3uauimpm750kd9vh"    # версия ОС: Ubuntu 22.04 LTS (family_id: ubuntu-2204-lts, image_id: fd8i3uauimpm750kd9vh);
      type        = "network-hdd"             # тип загрузочного носителя (network-hdd | network-ssd);
      size        = 20                        # размер диска, ГБ (меньше 5 ГБ выбрать нельзя)
      description = "Ubuntu 22.04 LTS"
    }
  }

  ## Параметры локального сетевого интерфейса
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id   # идентификатор подсети в которую будет смотреть интерфейс;
    ip_address = "10.0.10.10"                  # указываем явно какой внутренний IPv4 адрес назначить ВМ;
    nat        = true                          # создаем интерфейс смотрящий в публичную сеть;
  }

  ## Данные авторизации пользователей на создаваемых ВМ
  metadata = {
    serial-port-enable = 0                                     # активация серийной консоли чтоб можно было подключиться к ВМ через веб-интерфейс (0, 1);
    #ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"      # самый простой и работающий вариант передачи publick ключа в ВМ;
    ssh-keys = "ubuntu:${file("${local.ssh_pubkey_path}")}"
  }

  ## Выполнение команд после того как ВМ будет создана
  ## *обновляем пакеты системы + устанавливаем python3
  provisioner "remote-exec" {
    ##..обязательный блок подключения к ВМ
    connection {
      type = "ssh"
      user = "ubuntu"
      host = yandex_compute_instance.host1.network_interface.0.nat_ip_address
      agent = true
      #timeout = "4m"
    }
    ##..блок выполнения команд (1 команда выполняется за ssh 1 подключение)
    inline = [
      "sudo apt update && sudo apt install -y python3 && sudo apt -y autoremove",
      "echo '## python3 --version' >> /home/ubuntu/install_log.txt && python3 --version >> /home/ubuntu/install_log.txt"
    ]
  } ## << "provisioner remote-exec"

  provisioner "local-exec" {
    ##--Применяем Ansible Плейбук "nginx" к инстансу "host1"
    ##  example: ansible-playbook -i 84.252.139.210, -u ubuntu -e host_public_ip_phpfpm=158.160.28.188 ./ansible/deploy_nginx.yml
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_ASK_PASS=False ansible-playbook -i '${yandex_compute_instance.host1.network_interface.0.nat_ip_address},' -u ${local.vm_default_login} -e host_public_ip_phpfpm=${yandex_compute_instance.host2.network_interface.0.nat_ip_address} ./ansible/deploy_nginx.yml"
    #
  } ## << "provisioner local-exec"

}


## В Сервисе "Virtual Private Cloud" (vpc) Создаем Сеть "acme-net" и подсеть "acme-net-sub1"
resource "yandex_vpc_network" "net1" {
  name = "acme-net" # имя сети так она будет отображаться в веб-консоли (чуть выше "net1" - это псевдоним ресурса);
}

resource "yandex_vpc_subnet" "subnet1" {
  name           = "acme-net-sub1"              # имя подсети;
  zone           = local.access_zone            # зона доступности (из локальной переменной);
  network_id     = yandex_vpc_network.net1.id   # связь подсети с сетью по id (net1 - это созданный псевдоним Ресурса);
  v4_cidr_blocks = ["10.0.10.0/28"]             # адресное IPv4 пространство подсети;
}


/*=EXAMPLE_OUTPUT:

    Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

    Outputs:

    vm1_nginx_external_ip = "ubuntu-nginx: 158.160.27.30"
    vm2_phpfpm_external_ip = "ubuntu-php-fpm: 158.160.19.88"

    webApp_url1_static = "http://158.160.27.30/cat.jpg"
    webApp_url2_dynamic = "http://158.160.27.30"
    webApp_url3_dynamic = "http://158.160.27.30/test.php"
    webApp_url4_dynamic = "http://158.160.27.30/info/"

*/
