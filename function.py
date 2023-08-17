#!/usr/bin/env python3
from logging import getLogger
from json import dumps, loads
from os import environ
from typing import Any, Dict, List, Union

from boto3 import client


EKS = client("eks")
SSM = client("ssm")
SNS = client("sns")
SES = client("ses")
LOGGER = getLogger(environ.get("LOG_LEVEL", "INFO"))
SEND_EMAIL = bool(environ.get("SEND_EMAIL"))
PUBLISH_SNS = bool(environ.get("PUBLISH_SNS"))
ARM = bool(environ.get("ARM"))
BOTTLEROCKET = bool(environ.get("BOTTLEROCKET"))
ALLOWED_ARCHITECTURES = ("x86_64", "arm64")
GPU = bool(environ.get("GPU"))
ARCH = environ.get("ARCH", "x86_64")
NOTIFY_AMI = bool(environ.get("NOTIFY_AMI"))
NOTIFY_EKS = bool(environ.get("NOTIFY_EKS"))
FORCE_RUN = False
ADDITIONAL_MESSAGE_INFO = environ.get("ADDITIONAL_MESSAGE_INFO", "")

if not (SEND_EMAIL or PUBLISH_SNS):
  LOGGER.warning("Running with SEND_EMAIL or PUBLISH_SNS set to False. Will only generate logs.")    

# All amazon-linux-2 AMI's that support GPU are x86_64
if (
    not BOTTLEROCKET
    and (
        GPU and ARCH != "x86_64"
    )
  ):
    raise Exception("When using amazon-linux-2 you can only one of ARCH or GPU")

try:
    CURRENT_EKS_VERSION_PARAMETER = environ.get("CURRENT_EKS_VERSION_PARAMETER")
    EKS_VERSIONS_PARAMETER = environ["EKS_VERSIONS_PARAMETER"]
    SNS_TOPIC = environ["SNS_TOPIC"] if PUBLISH_SNS else None
    FROM_ADDRESS = environ["FROM_ADDRESS"] if SEND_EMAIL else None
    TO_ADDRESS = environ["TO_ADDRESS"] if SEND_EMAIL else None
except KeyError as e:
    raise Exception(f"Missing required environment variable: {e}") from e

if ARCH not in ALLOWED_ARCHITECTURES:
    raise Exception(f"ARCH must be one of {ALLOWED_ARCHITECTURES}")


def put_parameter(value: str, parameter: str = EKS_VERSIONS_PARAMETER) -> None:
    SSM.put_parameter(
        Name=parameter,
        Description="Last Known EKS versions available",
        Type="StringList",
        Value=value,
        Overwrite=True,
    )


def notify(subject: str, body: str = None, email: bool = True, sns: bool = False) -> None:
    body = body or subject
    body += f"\n{ADDITIONAL_MESSAGE_INFO}"

    if email:
        send_email(subject, body)

    if sns:
        publish_message(subject, body)


def send_email(subject: str, body: str = None) -> None:
    LOGGER.info("Sending Email to {}")

    res = SES.send_email(
        Source=FROM_ADDRESS,
        Destination={
            "ToAddresses": ["cloud-release-updates@morningconsult.com"],
        },
        Message={"Subject": {"Data": subject}, "Body": {"Text": {"Data": body}}},
    )
    LOGGER.info(dumps(res, indent=2))


def publish_message(subject: str, body: str = None) -> None:
    LOGGER.info("Publishing to SNS")
    body = body or subject

    res = SNS.publish(
        TopicArn=SNS_TOPIC,
        Message=body,
        Subject=subject,
    )
    LOGGER.info(dumps(res, indent=2))



def list_eks_versions() -> List[str]:
    """
    Returns a list of EKS control plane versions available
    by parsing EKS Addons' supported versions. It's currently
    the most reliable method.
    """
    res = EKS.describe_addon_versions()["addons"]

    cluster_versions = []

    for addon in res:
        for addon_version in addon["addonVersions"]:
            cluster_versions += [
                x["clusterVersion"]
                for x in addon_version["compatibilities"]
                if x["clusterVersion"] not in cluster_versions
            ]

    return sorted(cluster_versions)


def get_ami_version(
    cluster_version: str,
    bottlerocket: bool = False,
    gpu: bool = False,
    arch: bool = "x86_64"
) -> str:
    """
    Returns the AMI ID of the latest Bottlerocket AMI for a specific EKS version
    """
    if bottlerocket:
        flavor = f"aws-k8s-{cluster_version}"
        if gpu:
          flavor += "-nvidia"

        path = f"/aws/service/bottlerocket/{flavor}/{arch}/latest/image_id"
    else:
        flavor = "amazon-linux-2"

        if gpu:
            flavor += "-gpu"
        elif arch != "x86_64":
            flavor += f"-{arch}"

        path = f"/aws/service/eks/optimized-ami/{cluster_version}/{flavor}/recommended/image_id"

    try:
      version = get_parameter(path, from_json=False)
    except SSM.exceptions.ParameterNotFound as e:
        LOGGER.warning(f"{e}:{path}" )
        version = None
    return version


def get_parameter(
    name: str, from_json: bool = True
) -> Union[str, List[Any], Dict[Any, Any]]:
    """
    Fetches a parameter from SSM, optionally deserializing it from JSON
    """
    res = SSM.get_parameter(Name=name)
    value = res["Parameter"]["Value"]

    if from_json:
        value = loads(value)

    return value


def handler(_, __) -> None:
    CURRENT_EKS_VERSION = get_parameter(CURRENT_EKS_VERSION_PARAMETER, from_json=False)

    # These are versions that we've parsed before and also updated the latest
    # AMI ID for. The most recent version in this parameter IS NOT NECESSARILY
    # the version of EKS that we are on!
    old_version_parameter = get_parameter(EKS_VERSIONS_PARAMETER)

    latest_cluster_versions = list_eks_versions()

    # Store the EKS version as the key and the latest AMI ID as the value
    new_version_parameter = {
        eks_version: get_ami_version(eks_version, gpu=GPU, arch=ARCH, bottlerocket=BOTTLEROCKET)
        for eks_version in latest_cluster_versions
    }

    if old_version_parameter == new_version_parameter and not FORCE_RUN:
        return

    put_parameter(dumps(new_version_parameter))

    for eks_version, ami_id in new_version_parameter.items():
        # Notify us of EKS versions that are not already parsed and stored in SSM
        if eks_version not in old_version_parameter:
            msg = f"New EKS Version ({eks_version}) available"
            subject = msg
            if NOTIFY_EKS:
              LOGGER.info(msg)
              notify(msg, sns=PUBLISH_SNS, email=SEND_EMAIL)
            else:
                LOGGER.info(f"Skipping notification for {subject}")

        # Notify us of new Bottlerocket versions for our current EKS version
        if eks_version == CURRENT_EKS_VERSION and ami_id != old_version_parameter.get(eks_version):
            if GPU:
                gpu = "-nvidia" if BOTTLEROCKET else "-gpu"
            else:
                gpu = ""
            bottlerocket = "Bottlerocket" if BOTTLEROCKET else ""
            msg = f"{bottlerocket} AMI ({ami_id}) available for EKS version {eks_version}-{ARCH}{gpu}"
            subject = f"AMI Update for EKS {eks_version}-{ARCH}{gpu}"
            if NOTIFY_AMI:
              LOGGER.info(msg)
              notify(msg, subject, sns=PUBLISH_SNS, email=SEND_EMAIL)
            else:
                LOGGER.info(f"Skipping notification for {subject}")


if __name__ == "__main__":
    import logging
    from sys import stdout

    logging.basicConfig(
        handlers=[logging.StreamHandler(stream=stdout)],
        level=environ.get("LOG_LEVEL", "INFO"),
    )

    FORCE_RUN = True
    handler(None, None)
