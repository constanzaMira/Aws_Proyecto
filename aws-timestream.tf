# Crear la base de datos Timestream
resource "aws_timestreamwrite_database" "huerta_db" {
  database_name = "HuertaDB-test"
}

# Crear la tabla Timestream dentro de HuertaDB-test
resource "aws_timestreamwrite_table" "sensor_data" {
  database_name = aws_timestreamwrite_database.huerta_db.database_name
  table_name    = "SensorData"

  retention_properties {
    memory_store_retention_period_in_hours  = 24    # 1 día en horas
    magnetic_store_retention_period_in_days = 730   # 2 años en días
  }

  magnetic_store_write_properties {
    enable_magnetic_store_writes = true
  }

  tags = {
    Name = "SensorData"
  }
}
