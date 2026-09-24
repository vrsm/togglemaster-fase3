resource "aws_sqs_queue" "togglemaster" {
  name = "toggle-master"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600

  tags = {
    Name    = "toggle-master"
    Service = "analytics-service"
  }
}
