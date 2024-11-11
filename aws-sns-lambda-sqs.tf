
# Step 1: IAM Role for IoT Rule to Access SQS #
resource "aws_iam_role" "iot_to_sqs_role" {
  name = "iot_to_sqs_role_test"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "iot.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "iot_to_sqs_policy" {
  name = "iot_to_sqs_policy_test"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sqs:SendMessage",
        "Resource": aws_sqs_queue.alert_sqs.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iot_to_sqs_attach" {
  role       = aws_iam_role.iot_to_sqs_role.name
  policy_arn = aws_iam_policy.iot_to_sqs_policy.arn
}

# Step 2: IoT Rule to Send Data to SQS #
resource "aws_iot_topic_rule" "send_data_to_sqs" {
  name        = "SendDataToSQS_test"
  description = "Send data from raspi/alert topic to SQS"
  sql         = "SELECT * FROM 'raspi/alert'"
  sql_version = "2016-03-23"
  enabled     = true

  sqs {
    role_arn   = aws_iam_role.iot_to_sqs_role.arn
    queue_url  = aws_sqs_queue.alert_sqs.id
    use_base64 = false
  }
}

# Step 3: SQS Queue #
resource "aws_sqs_queue" "alert_sqs" {
  name                       = "alert_sqs_test"
  visibility_timeout_seconds = 30
}

# Step 4: IAM Role for Lambda to Access SQS, RDS, SNS, and SES #
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_to_sns_role_test"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy_test"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Resource": aws_sqs_queue.alert_sqs.arn
      },
      {
        "Effect": "Allow",
        "Action": [
          "rds-db:connect"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "sns:Publish"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Step 5: Lambda Function #
resource "aws_lambda_function" "lambda_to_sns" {
  function_name    = "lambda_to_sns_test"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_execution_role.arn
  timeout          = 10

  environment {
    variables = {
      RDS_HOST     = "database-tic-test.chc6sm8iodx6.us-east-2.rds.amazonaws.com"        
      RDS_USER     = "postgres"       
      RDS_PASSWORD = "lab_tic_v"        
      RDS_DB_NAME  = "huerta_db"       
      RDS_PORT     = "5432"
    }
  }

  layers = ["arn:aws:lambda:us-east-2:898466741470:layer:psycopg2-py38:1"]
}

# Step 6: Lambda Trigger for SQS #
resource "aws_lambda_event_source_mapping" "lambda_sqs_trigger" {
  event_source_arn = aws_sqs_queue.alert_sqs.arn
  function_name    = aws_lambda_function.lambda_to_sns.arn
  enabled          = true
}

