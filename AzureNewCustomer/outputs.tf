output "public_ip_address of Console LB" {
  description = "IP Address of the Console LB"
  value       = "${azurerm_public_ip.lbpip.ip_address}"
}
output "public_ip_address of Report LB" {
  description = "IP Address of the Report LB"
  value       = "${azurerm_public_ip.lbpip2.ip_address}"
}
output "public_ip_address of Management VM" {
  description = "IP Address of the Management vm"
  value       = "${azurerm_public_ip.managevmpip.ip_address}"
}