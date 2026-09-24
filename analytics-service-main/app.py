import os
import sys
import threading
import json
import uuid
import time
import logging

import boto3
from botocore.exceptions import NoCredentialsError, ClientError
from flask import Flask, jsonify
from dotenv import load_dotenv

# Configura o logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
log = logging.getLogger(__name__)

# Carrega .env para desenvolvimento local
load_dotenv()

# ---------------------------------------------------------------------
# Configuração
# ---------------------------------------------------------------------

AWS_REGION = os.getenv("AWS_REGION")
SQS_QUEUE_URL = os.getenv("AWS_SQS_URL")
DYNAMODB_TABLE_NAME = os.getenv("AWS_DYNAMODB_TABLE")

# Opcionais (somente para ambiente local)
SQS_ENDPOINT = os.getenv("SQS_ENDPOINT")
DYNAMODB_ENDPOINT = os.getenv("DYNAMODB_ENDPOINT")

AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")

if not all([AWS_REGION, SQS_QUEUE_URL, DYNAMODB_TABLE_NAME]):
    log.critical(
        "Erro: AWS_REGION, AWS_SQS_URL e AWS_DYNAMODB_TABLE devem ser definidos."
    )
    sys.exit(1)

# ---------------------------------------------------------------------
# Clientes Boto3
# ---------------------------------------------------------------------

try:

    session_kwargs = {
        "region_name": AWS_REGION,
    }

    # Apenas ambiente local usa credenciais fake
    if AWS_ACCESS_KEY_ID:
        session_kwargs["aws_access_key_id"] = AWS_ACCESS_KEY_ID

    if AWS_SECRET_ACCESS_KEY:
        session_kwargs["aws_secret_access_key"] = AWS_SECRET_ACCESS_KEY

    session = boto3.Session(**session_kwargs)

    sqs_kwargs = {}
    dynamodb_kwargs = {}

    # LocalStack
    if SQS_ENDPOINT:
        sqs_kwargs["endpoint_url"] = SQS_ENDPOINT

    # DynamoDB Local
    if DYNAMODB_ENDPOINT:
        dynamodb_kwargs["endpoint_url"] = DYNAMODB_ENDPOINT

    sqs_client = session.client(
        "sqs",
        **sqs_kwargs
    )

    dynamodb_client = session.client(
        "dynamodb",
        **dynamodb_kwargs
    )

    log.info("Clientes Boto3 inicializados na região %s", AWS_REGION)

except NoCredentialsError:
    log.critical("Credenciais AWS não encontradas.")
    sys.exit(1)

except Exception as e:
    log.critical(f"Erro ao inicializar o Boto3: {e}")
    sys.exit(1)

# ---------------------------------------------------------------------
# Worker SQS
# ---------------------------------------------------------------------


def process_message(message):
    """Processa uma mensagem da fila."""

    try:

        log.info(f"Processando mensagem ID: {message['MessageId']}")

        body = json.loads(message["Body"])

        event_id = str(uuid.uuid4())

        item = {
            "event_id": {"S": event_id},
            "user_id": {"S": body["user_id"]},
            "flag_name": {"S": body["flag_name"]},
            "result": {"BOOL": body["result"]},
            "timestamp": {"S": body["timestamp"]},
        }

        dynamodb_client.put_item(
            TableName=DYNAMODB_TABLE_NAME,
            Item=item
        )

        log.info(
            "Evento %s (flag=%s) salvo no DynamoDB.",
            event_id,
            body["flag_name"]
        )

        sqs_client.delete_message(
            QueueUrl=SQS_QUEUE_URL,
            ReceiptHandle=message["ReceiptHandle"]
        )

    except json.JSONDecodeError:

        log.error(
            "Erro ao decodificar JSON da mensagem %s",
            message["MessageId"]
        )

    except ClientError as e:

        log.error(
            "Erro do Boto3 ao processar %s: %s",
            message["MessageId"],
            e
        )

    except Exception as e:

        log.error(
            "Erro inesperado ao processar %s: %s",
            message["MessageId"],
            e
        )


def sqs_worker_loop():
    """Loop principal do worker."""

    log.info("Iniciando worker SQS...")

    while True:

        try:

            response = sqs_client.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=20,
            )

            messages = response.get("Messages", [])

            if not messages:
                continue

            log.info("Recebidas %d mensagens.", len(messages))

            for message in messages:
                process_message(message)

        except ClientError as e:

            log.error("Erro do Boto3 no worker: %s", e)
            time.sleep(10)

        except Exception as e:

            log.error("Erro inesperado no worker: %s", e)
            time.sleep(10)


# ---------------------------------------------------------------------
# Flask
# ---------------------------------------------------------------------

app = Flask(__name__)


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


# ---------------------------------------------------------------------
# Inicialização
# ---------------------------------------------------------------------

def start_worker():
    worker = threading.Thread(
        target=sqs_worker_loop,
        daemon=True
    )
    worker.start()


start_worker()


if __name__ == "__main__":

    port = int(os.getenv("PORT", "8005"))

    app.run(
        host="0.0.0.0",
        port=port,
        debug=False
    )
