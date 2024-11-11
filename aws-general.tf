terraform {
  backend "s3" {
    bucket = "terraforms-tic" 
    key    = "tic/terraform.tfstate" # Una ruta única para el archivo de estado
    region = "us-east-2"
  }
}
