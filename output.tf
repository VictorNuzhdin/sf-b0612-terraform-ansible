output "vm1_nginx_external_ip" {
  value       = "${yandex_compute_instance.host1.name}: ${yandex_compute_instance.host1.network_interface.0.nat_ip_address}"
  description = "The Name and public IP address of VM1 instance."
  sensitive   = false
}

output "vm2_phpfpm_external_ip" {
  value       = "${yandex_compute_instance.host2.name}: ${yandex_compute_instance.host2.network_interface.0.nat_ip_address}"
  description = "The Name and public IP address of VM2 instance."
  sensitive   = false
}

output "webApp_url1_static" {
  value       = "http://${yandex_compute_instance.host1.network_interface.0.nat_ip_address}/cat.jpg"
  description = "Please check this URL with your web browser (static file stored on the Nginx host)"
  sensitive   = false
}

output "webApp_url2_dynamic" {
  value       = "http://${yandex_compute_instance.host1.network_interface.0.nat_ip_address}"
  description = "Please check this URL with your web browser (php file1 processing by php-fpm host)"
  sensitive   = false
}

output "webApp_url3_dynamic" {
  value       = "http://${yandex_compute_instance.host1.network_interface.0.nat_ip_address}/test.php"
  description = "Please check this URL with your web browser (php file2 processing by php-fpm host)"
  sensitive   = false
}

output "webApp_url4_dynamic" {
  value       = "http://${yandex_compute_instance.host1.network_interface.0.nat_ip_address}/info/"
  description = "Please check this URL with your web browser (php file3 processing by php-fpm host)"
  sensitive   = false
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
