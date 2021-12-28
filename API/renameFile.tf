module "renameDoc" {
  source      = "../modules/restapi_service_method"
  http_method = "POST"
  service = {
    uri         = "arn:aws:apigateway:${var.region}:dynamodb:action/UpdateItem"
    invoke_role = aws_iam_role.APIGatewayDynamoDBFullAccess.arn
    http_method = "POST"
  }

  apigateway = {
    arn = aws_api_gateway_rest_api.OxyApi.execution_arn
    id  = aws_api_gateway_rest_api.OxyApi.id
  }

  authorizer = {
    type = "COGNITO_USER_POOLS"
    id   = aws_api_gateway_authorizer.user_pool.id
  }

  resource = aws_api_gateway_resource.DocID

  request = {
    parameters = {
      "method.request.querystring.filename" = true
      "method.request.header.Content-Type"  = true
    }
    integration_parameters = {
      "integration.request.header.Content-Type" = "method.request.header.Content-Type"
    }
    timeout_ms = 29000
    templates = {
      "application/json" = local.request_template
    }
  }

  responses = {
    "ok" = {
      integration_parameters = {
        "method.response.header.Content-Type" = "integration.response.header.Content-Type"
      }
      integration_templates         = null
      integration_selection_pattern = "2\\d{2}"
      integration_status_code       = 200
      integration_content_handling  = "CONVERT_TO_TEXT"

      models = {
        "application/json" = "Empty"
      }
      parameters = {
        "method.response.header.Content-Type" = true
      }
      status_code = 200
    }
  }
}

locals {
  request_template = <<EOF
  #set($user_id = $context.authorizer.claims['cognito:username'])
  {
    "TableName":"${var.storage_table.name}",
    "Key":{
        "file_id":{
            "S":"$method.request.path.id"
        },
        "user_id":{
          "S":"$user_id"
        }
    },
    "UpdateExpression": "set display_name = :filename",

    "ExpressionAttributeValues": {
        ":filename": {"S": "$method.request.querystring.filename"},
        ":file_id": {"S": "$method.request.path.id"},
        ":user_id": {"S": "$user_id"}
    },
    "ConditionExpression": "file_id = :file_id AND user_id = :user_id",
    "ReturnValues": "ALL_NEW"
  }
    EOF
}